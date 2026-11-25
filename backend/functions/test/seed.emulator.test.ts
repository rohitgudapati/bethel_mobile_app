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
  assert.equal((await db.collection('songs').where('bookId', '==', 'hymns-of-faith').get()).size, 20);
  assert.equal((await db.doc('songBooks/songs-of-zion').get()).get('songCount'), 2);
  const grace = (await db.doc('songs/hymns-of-faith-1').get()).data()!;
  assert.equal(grace.title, 'Amazing Grace');
  assert.match(grace.lyrics.English, /^Amazing grace! How sweet the sound/);
  assert.equal((await db.doc('church/info').get()).get('address'), '7S201 South River Rd, Naperville, IL');
  const sunday = (await db.doc('events/sunday-worship').get()).get('date').toDate() as Date;
  assert.equal(sunday.getDay(), 0, 'Sunday service lands on a Sunday');
});

test('seed loads a full song book file in batches and replaces the sample songs', async () => {
  const content = JSON.parse(readFileSync(join(__dirname, '..', '..', '..', 'seed', 'content.json'), 'utf8'));
  const entries = Array.from({ length: 450 }, (_, i) => ({
    n: i + 1,
    t: `Song ${i + 1}`,
    tt: `పాట ${i + 1}`,
    r: 'Psalm 1',
    te: 'పల్లవి : ఒకటి\n\n1. రెండు',
    en: 'Pallavi : okati\n\n1. rendu',
  }));
  // seed() already initialised the app in the previous test; reuse it.
  const { songBookDocs } = await import('../src/tools/seed');
  const db = getFirestore();
  const docs = songBookDocs('songs-of-zion', entries);
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    for (const d of docs.slice(i, i + 400)) batch.set(db.doc(`songs/songs-of-zion-${d.number}`), d);
    await batch.commit();
  }
  const zion = await db.collection('songs').where('bookId', '==', 'songs-of-zion').get();
  assert.equal(zion.size, 450);
  const s1 = (await db.doc('songs/songs-of-zion-1').get()).data()!;
  assert.equal(s1.title, 'Song 1', 'sample song 1 replaced');
  assert.equal(s1.altTitle, 'పాట 1');
  assert.deepEqual(Object.keys(s1.lyrics), ['Telugu', 'English']);
  assert.ok(content.songs.length > 0);
});
