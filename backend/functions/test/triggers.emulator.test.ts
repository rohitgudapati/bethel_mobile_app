import { strict as assert } from 'node:assert';
import { test } from 'node:test';

process.env.GCLOUD_PROJECT ??= 'demo-bethel';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const fns = require('../src/index');
import { getFirestore } from 'firebase-admin/firestore';

test('"I prayed" and verse likes keep their counters', async () => {
  const db = getFirestore();
  await db.doc('prayerRequests/t1').set({ request: 'test', prayedCount: 0, public: true });
  await db.doc('verses/t1').set({ likes: 3 });

  await fns.onPrayed.run({ params: { id: 't1', uid: 'a' } });
  await fns.onPrayed.run({ params: { id: 't1', uid: 'b' } });
  await fns.onVerseLiked.run({ params: { id: 't1', uid: 'a' } });
  await fns.onVerseUnliked.run({ params: { id: 't1', uid: 'b' } });
  await fns.onVerseLiked.run({ params: { id: 't1', uid: 'c' } });

  assert.equal((await db.doc('prayerRequests/t1').get()).get('prayedCount'), 2);
  assert.equal((await db.doc('verses/t1').get()).get('likes'), 4);

  // The built-in daily verse has no document until someone likes it.
  await fns.onVerseLiked.run({ params: { id: 'day-2026-11-25', uid: 'a' } });
  assert.equal((await db.doc('verses/day-2026-11-25').get()).get('likes'), 1);
});

test('only admins can run a YouTube sync from the app', async () => {
  await assert.rejects(() => fns.syncYouTubeNow.run({ data: {}, auth: { uid: 'x', token: {} } }), /Only church admins/);
});
