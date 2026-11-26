import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';

let environment;
const profile = {
  name: 'Test user', email: 'test@example.com', photoUrl: null,
  threshold: 100, backgroundAlerts: false, place: null, theme: 0, milligrams: false,
};
before(async () => {
  environment = await initializeTestEnvironment({ projectId: 'demo-air-quality-monitor',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') } });
});
beforeEach(async () => environment.clearFirestore());
after(async () => environment?.cleanup());
test('Owner can save and read own profile', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice'), profile));
  await assertSucceeds(getDoc(doc(db, 'users/alice')));
});
test('Other account cannot read or modify profile, favorites or tokens', async () => {
  const db = environment.authenticatedContext('bob').firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
  await assertFails(setDoc(doc(db, 'users/alice'), profile));
  await assertFails(setDoc(doc(db, 'users/alice/devices/device'), { token: 'test' }));
  await assertFails(getDoc(doc(db, 'users/alice/favorites/1')));
});
test('Anonymous user cannot access private data', async () => {
  const db = environment.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
  await assertFails(setDoc(doc(db, 'users/alice'), profile));
});
test('Owner cannot save invalid thresholds, coordinates or arbitrary server fields', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice'), { ...profile, threshold: -1 }));
  await assertFails(setDoc(doc(db, 'users/alice'), { ...profile, admin: true }));
  await assertFails(setDoc(doc(db, 'users/alice'), { ...profile,
    place: { id: '1', name: 'City', latitude: 99, longitude: 70 } }));
});
test('Favorites validate ID and tokens remain scoped to their owner', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  const place = { id: '1', name: 'City', latitude: 43, longitude: 76, country: '', region: '' };
  await assertSucceeds(setDoc(doc(db, 'users/alice/favorites/1'), place));
  await assertFails(setDoc(doc(db, 'users/alice/favorites/2'), place));
  await assertSucceeds(setDoc(doc(db, 'users/alice/devices/device'), { token: 'test-token' }));
});
test('Notification history and dedup claims can only be written by server', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice/notifications/1'), { title: 'Forged alert' }));
  await assertFails(setDoc(doc(db, 'users/alice/alertClaims/1'), { status: 'sent' }));
});

function deletingContext(uid, ageSeconds = 0) {
  return environment.authenticatedContext(uid, {
    auth_time: Math.floor(Date.now() / 1000) - ageSeconds,
  }).firestore();
}
function barrier() {
  return { startedAt: serverTimestamp(), purgeAfter: Timestamp.fromMillis(Date.now() + 7200000) };
}
test('Deletion barrier requires fresh authentication and cannot be removed by a stale client', async () => {
  const stale = deletingContext('alice', 600);
  await assertFails(setDoc(doc(stale, 'accountDeletions/alice'), barrier()));
  const fresh = deletingContext('alice');
  await assertFails(setDoc(doc(fresh, 'accountDeletions/bob'), barrier()));
  await assertSucceeds(setDoc(doc(fresh, 'accountDeletions/alice'), barrier()));
  await assertFails(deleteDoc(doc(fresh, 'accountDeletions/alice')));
  await assertFails(setDoc(doc(fresh, 'accountDeletions/alice'), { ...barrier(), email: 'test@example.com' }));
});
test('Deletion blocks all profile/favorite/device recreation but permits purging server-owned data', async () => {
  const db = deletingContext('alice');
  await assertSucceeds(setDoc(doc(db, 'users/alice'), profile));
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/alice/notifications/1'), { title: 'Alert' });
    await setDoc(doc(context.firestore(), 'users/alice/alertClaims/1'), { status: 'sent' });
  });
  await assertFails(deleteDoc(doc(db, 'users/alice/notifications/1')));
  await assertSucceeds(setDoc(doc(db, 'accountDeletions/alice'), barrier()));
  await assertFails(setDoc(doc(db, 'users/alice'), profile));
  await assertFails(setDoc(doc(db, 'users/alice/devices/d'), { token: 'test' }));
  await assertFails(setDoc(doc(db, 'users/alice/favorites/1'), { id: '1', name: 'City', latitude: 43, longitude: 76 }));
  await assertFails(setDoc(doc(db, 'users/alice/notifications/forged'), { title: 'Forged' }));
  await assertSucceeds(getDoc(doc(db, 'users/alice/alertClaims/1')));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/alertClaims/1')));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/notifications/1')));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice')));
  await assertFails(setDoc(doc(db, 'users/alice'), profile));
  const bob = deletingContext('bob');
  await assertFails(deleteDoc(doc(bob, 'users/alice/notifications/1')));
});
