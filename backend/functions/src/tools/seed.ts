/**
 * Loads the starting church content (backend/seed/content.json) into Firestore.
 *
 *   Emulator:   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm run seed
 *   Production: GOOGLE_CLOUD_PROJECT=<project-id> npm run seed -- --production
 *               (needs `gcloud auth application-default login` first)
 *
 * Existing documents with the same ids are overwritten; anything else is left alone.
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

type Json = Record<string, any>;

function dayFromOffset(offset: number | string, now = new Date()): Date {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const dow = today.getDay(); // 0 = Sunday
  let days: number;
  if (offset === 'nextSunday') days = dow === 0 ? 7 : 7 - dow;
  else if (offset === 'nextFriday') days = ((5 - dow + 7) % 7) || 7;
  else days = Number(offset);
  return new Date(today.getTime() + days * 86400_000);
}

export async function seed(content: Json, projectId?: string) {
  initializeApp(projectId ? { projectId } : undefined);
  const db = getFirestore();
  const batch = db.batch();
  let n = 0;
  const put = (col: string, id: string, data: Json) => {
    batch.set(db.collection(col).doc(id), data);
    n++;
  };

  put('church', 'info', content.church);
  for (const b of content.songBooks) {
    const count = content.songs.filter((s: Json) => s.bookId === b.id).length;
    const { id, ...rest } = b;
    put('songBooks', id, { ...rest, songCount: count });
  }
  for (const s of content.songs) {
    const { id: _legacy, ...rest } = s;
    put('songs', `${s.bookId}-${s.number}`, { ...rest, trendingScore: 0 });
  }
  for (const s of content.services) {
    const { id, ...rest } = s;
    put('services', id, rest);
  }
  for (const m of content.ministries) {
    const { id, ...rest } = m;
    put('ministries', id, rest);
  }
  for (const e of content.events) {
    const { id, dayOffset, ...rest } = e;
    put('events', id, { ...rest, date: Timestamp.fromDate(dayFromOffset(dayOffset)) });
  }
  for (const v of content.verses) {
    const { id, dayOffset, ...rest } = v;
    put('verses', id, { text: null, ...rest, date: Timestamp.fromDate(dayFromOffset(dayOffset)), likes: 0, shares: 0, views: 0 });
  }
  for (const b of content.books) {
    const { id, ...rest } = b;
    put('books', id, rest);
  }
  for (const p of content.pictures) {
    const { id, ...rest } = p;
    put('pictures', id, rest);
  }
  for (const p of content.readingPlan) {
    const { id, ...rest } = p;
    put('readingPlan', id, rest);
  }
  await batch.commit();
  return n;
}

if (require.main === module) {
  const production = process.argv.includes('--production');
  if (!process.env.FIRESTORE_EMULATOR_HOST && !production) {
    console.error('Refusing to seed: FIRESTORE_EMULATOR_HOST is not set. Pass --production to seed the live project.');
    process.exit(1);
  }
  const content = JSON.parse(readFileSync(join(__dirname, '..', '..', '..', 'seed', 'content.json'), 'utf8'));
  seed(content, process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT ?? 'demo-bethel')
    .then((n) => console.log(`Seeded ${n} documents.`))
    .catch((e) => {
      console.error(e);
      process.exit(1);
    });
}
