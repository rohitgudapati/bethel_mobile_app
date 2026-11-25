import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { test } from 'node:test';

import { getFirestore } from 'firebase-admin/firestore';

import { seed } from '../src/tools/seed';

test('seed loads the starting church content', async () => {
  const content = JSON.parse(readFileSync(join(__dirname, '..', '..', '..', 'seed', 'content.json'), 'utf8'));
  const n = await seed(content, 'demo-bethel');
  assert.ok(n > 40);
  const db = getFirestore();
  assert.equal((await db.collection('songs').where('bookId', '==', 'hymns-of-faith').get()).size, 10);
  assert.equal((await db.doc('songBooks/songs-of-zion').get()).get('songCount'), 2);
  const grace = (await db.doc('songs/hymns-of-faith-1').get()).data()!;
  assert.equal(grace.title, 'Amazing Grace');
  assert.match(grace.lyrics.English, /^Amazing grace! How sweet the sound/);
  assert.equal((await db.doc('church/info').get()).get('address'), '756 South River Rd, Naperville');
  const sunday = (await db.doc('events/sunday-worship').get()).get('date').toDate() as Date;
  assert.equal(sunday.getDay(), 0, 'Sunday service lands on a Sunday');
});
