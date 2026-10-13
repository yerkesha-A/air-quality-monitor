"""Scheduled Android alerts. Deploy only after Firebase/billing and delivery tests."""
import datetime
import json
import logging
import urllib.parse
import urllib.request

from firebase_admin import initialize_app, firestore, messaging
from firebase_functions import scheduler_fn
from google.cloud.firestore_v1.base_query import FieldFilter

from air_logic import above_threshold, claim_id, valid_coordinates

initialize_app()


def fetch_current(place):
    query = urllib.parse.urlencode({'latitude': place['latitude'], 'longitude': place['longitude'],
                                   'current': 'us_aqi', 'timeformat': 'unixtime'})
    url = 'https://air-quality-api.open-meteo.com/v1/air-quality?' + query
    with urllib.request.urlopen(url, timeout=18) as response:
        if response.status != 200:
            raise ValueError('Air API HTTP error')
        return json.load(response).get('current', {})


@firestore.transactional
def reserve(transaction, ref, user_ref, threshold, place_id):
    user = user_ref.get(transaction=transaction).to_dict() or {}
    if (not user.get('backgroundAlerts') or user.get('threshold') != threshold
            or (user.get('place') or {}).get('id') != place_id):
        return False
    existing = ref.get(transaction=transaction)
    if existing.exists:
        data = existing.to_dict()
        if data.get('status') != 'failed':
            return False
    transaction.set(ref, {'status': 'sending', 'createdAt': firestore.SERVER_TIMESTAMP})
    return True


@scheduler_fn.on_schedule(schedule='every 60 minutes', region='europe-west1', timeout_sec=540)
def check_air_thresholds(event: scheduler_fn.ScheduledEvent) -> None:
    db = firestore.client()
    cache = {}
    users = db.collection('users').where(filter=FieldFilter('backgroundAlerts', '==', True)).stream()
    for user_doc in users:
        claim = None
        try:
            profile = user_doc.to_dict()
            place = profile.get('place')
            if not valid_coordinates(place):
                continue
            coordinates = (place['latitude'], place['longitude'])
            if coordinates not in cache:
                cache[coordinates] = fetch_current(place)
            current = cache[coordinates]
            aqi, model_time = current.get('us_aqi'), current.get('time')
            now = datetime.datetime.now(datetime.timezone.utc).timestamp()
            if (not above_threshold(aqi, profile.get('threshold'))
                    or not isinstance(model_time, (int, float))
                    or model_time < now - 7200 or model_time > now + 3600):
                continue
            devices = list(user_doc.reference.collection('devices').stream())
            devices = [d for d in devices if isinstance(d.to_dict().get('token'), str)]
            if not devices:
                continue
            alert_id = claim_id(place['id'], model_time, profile['threshold'])
            claim = user_doc.reference.collection('alertClaims').document(alert_id)
            if not reserve(db.transaction(), claim, user_doc.reference, profile['threshold'], place['id']):
                claim = None
                continue
            title = 'Воздух в ' + str(place.get('name', 'выбранном месте'))[:200]
            body = f'{round(aqi)} US AQI — выше вашего порога {profile["threshold"]}. Оценка модели.'
            accepted = 0
            for start in range(0, len(devices), 500):
                chunk = devices[start:start + 500]
                response = messaging.send_each_for_multicast(messaging.MulticastMessage(
                    tokens=[d.to_dict()['token'] for d in chunk],
                    notification=messaging.Notification(title=title, body=body),
                    data={'route': '/alerts', 'cityId': place['id'], 'aqi': str(aqi)},
                    android=messaging.AndroidConfig(priority='high', notification=messaging.AndroidNotification(
                        channel_id='air_quality_alerts', icon='ic_notification'))))
                accepted += response.success_count
                for device, result in zip(chunk, response.responses):
                    if isinstance(result.exception, messaging.UnregisteredError):
                        device.reference.delete()
            claim.set({'status': 'acceptedByFcm' if accepted else 'failed',
                       'updatedAt': firestore.SERVER_TIMESTAMP}, merge=True)
            if accepted:
                user_doc.reference.collection('notifications').document(alert_id).set({
                    'title': title, 'body': body, 'aqi': aqi, 'standard': 'US AQI',
                    'modelTime': model_time, 'createdAt': firestore.SERVER_TIMESTAMP})
        except Exception:
            logging.exception('AQI check failed for one profile')
            if claim is not None:
                claim.set({'status': 'failed', 'updatedAt': firestore.SERVER_TIMESTAMP}, merge=True)
