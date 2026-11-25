import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { after, before, beforeEach, test } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { addDoc, collection, deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

let env: RulesTestEnvironment;

before(async () => {
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST!.split(':');
  env = await initializeTestEnvironment({
    projectId: 'demo-bethel-rules',
    firestore: { host, port: Number(port), rules: readFileSync(join(__dirname, '..', '..', '..', 'firestore.rules'), 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'songs/hymns-of-faith-1'), { title: 'Amazing Grace' });
    await setDoc(doc(db, 'videos/vid1'), { title: 'Sermon', kind: 'sermon', hidden: false });
    await setDoc(doc(db, 'prayerRequests/private1'), { uid: 'alice', request: 'Private request', public: false });
    await setDoc(doc(db, 'prayerRequests/public1'), { uid: 'alice', request: 'Shared request', public: true, prayedCount: 0 });
    await setDoc(doc(db, 'prayerContacts/private1'), { uid: 'alice', email: 'alice@example.com', phone: '555' });
  });
});

const guest = (uid = 'guest1') => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const member = (uid = 'alice') => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'password' } }).firestore();
const admin = () => env.authenticatedContext('pastor', { admin: true, firebase: { sign_in_provider: 'password' } }).firestore();
const anyone = () => env.unauthenticatedContext().firestore();

test('church content is public to read and admin-only to write', async () => {
  await assertSucceeds(getDoc(doc(anyone(), 'songs/hymns-of-faith-1')));
  await assertFails(setDoc(doc(member(), 'songs/x'), { title: 'Mine' }));
  await assertSucceeds(setDoc(doc(admin(), 'songs/x'), { title: 'New hymn' }));
});

test('prayer requests: guests can post, private ones stay private, contacts are admin-only', async () => {
  await assertSucceeds(
    addDoc(collection(guest(), 'prayerRequests'), {
      uid: 'guest1', name: 'Sam', request: 'Please pray for my exams', category: 'Family', public: true,
      createdAt: serverTimestamp(), prayedCount: 0,
    }),
  );
  await assertFails(
    addDoc(collection(guest(), 'prayerRequests'), {
      uid: 'guest1', name: 'Sam', request: 'Inflated', category: 'Family', public: true,
      createdAt: serverTimestamp(), prayedCount: 500,
    }),
  );
  await assertFails(
    addDoc(collection(guest(), 'prayerRequests'), {
      uid: 'someoneElse', name: 'Sam', request: 'Spoofed author', category: 'Family', public: true,
      createdAt: serverTimestamp(), prayedCount: 0,
    }),
  );
  await assertSucceeds(getDoc(doc(anyone(), 'prayerRequests/public1')));
  await assertFails(getDoc(doc(guest('bob'), 'prayerRequests/private1')));
  await assertSucceeds(getDoc(doc(member('alice'), 'prayerRequests/private1')));
  await assertFails(getDoc(doc(member('alice'), 'prayerContacts/private1')));
  await assertSucceeds(getDoc(doc(admin(), 'prayerContacts/private1')));
  await assertFails(updateDoc(doc(guest(), 'prayerRequests/public1'), { prayedCount: 99 }));
});

test('"I prayed" is one document per person', async () => {
  await assertSucceeds(setDoc(doc(guest('g1'), 'prayerRequests/public1/prayedBy/g1'), {}));
  await assertFails(setDoc(doc(guest('g1'), 'prayerRequests/public1/prayedBy/g2'), {}));
});

test('sermon comments need a real account and the right author', async () => {
  const ok = { uid: 'alice', name: 'Alice', text: 'Great message', createdAt: serverTimestamp() };
  await assertFails(addDoc(collection(guest('alice'), 'videos/vid1/comments'), ok));
  await assertFails(addDoc(collection(member('bob'), 'videos/vid1/comments'), ok));
  await assertSucceeds(addDoc(collection(member('alice'), 'videos/vid1/comments'), ok));
  await assertFails(addDoc(collection(member('alice'), 'videos/vid1/comments'), { ...ok, text: 'x'.repeat(1001) }));
});

test('admins can hide or relabel a video but not rewrite YouTube fields', async () => {
  await assertSucceeds(updateDoc(doc(admin(), 'videos/vid1'), { hidden: true, typeOverride: 'testimony' }));
  await assertFails(updateDoc(doc(admin(), 'videos/vid1'), { title: 'Changed' }));
  await assertFails(updateDoc(doc(member(), 'videos/vid1'), { hidden: true }));
});

test('people can only see and change their own profile', async () => {
  await assertSucceeds(setDoc(doc(member('alice'), 'users/alice'), { savedSongs: ['hymns-of-faith-1'] }));
  await assertFails(getDoc(doc(member('bob'), 'users/alice')));
  await assertSucceeds(deleteDoc(doc(member('alice'), 'users/alice')));
  assert.ok(true);
});
