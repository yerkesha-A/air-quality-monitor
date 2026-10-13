"""Pure server logic. No credentials, deployment or synthetic AQI."""
import hashlib
import math


def above_threshold(aqi, threshold):
    return (isinstance(aqi, (int, float)) and not isinstance(aqi, bool)
            and math.isfinite(aqi) and aqi >= 0
            and isinstance(threshold, int) and not isinstance(threshold, bool)
            and 25 <= threshold <= 300 and aqi >= threshold)


def valid_coordinates(place):
    if not isinstance(place, dict):
        return False
    lat, lon = place.get('latitude'), place.get('longitude')
    return all(isinstance(v, (int, float)) and not isinstance(v, bool)
               and math.isfinite(v) for v in (lat, lon)) and -90 <= lat <= 90 and -180 <= lon <= 180


def claim_id(place_id, model_time, threshold):
    return hashlib.sha256(f'{place_id}:{int(model_time) // 3600}:{threshold}'.encode()).hexdigest()
