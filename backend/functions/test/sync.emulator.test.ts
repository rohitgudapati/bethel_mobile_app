import { strict as assert } from 'node:assert';
import { before, test } from 'node:test';

import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { syncChannel } from '../src/sync';
import { YouTubeClient } from '../src/youtube';
import { CHANNEL_ID, fakeFetch, scenario } from './fakeYouTube';

const PROJECT = 'demo-bethel';

before(async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'run with `npm run test:emulator`');
  initializeApp({ projectId: PROJECT });
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: 'DELETE',
  });
});

test('sync writes sermons, shorts, testimonies, interviews and live status', async () => {
  const db = getFirestore();
  const s = scenario();
  const res = await syncChannel(db, new YouTubeClient('test-key', fakeFetch(s)), {
    channel: 'https://www.youtube.com/@bethelprayerhouse',
    full: true,
    now: s.now,
  });
  assert.equal(res.channelId, CHANNEL_ID);
  assert.equal(res.written, 7);
  assert.equal(res.live, 'live');

  const kinds = Object.fromEntries((await db.collection('videos').get()).docs.map((d) => [d.id, d.get('kind')]));
  assert.deepEqual(kinds, {
    recording01: 'sermon',
    plainUpload: 'sermon',
    longNotShrt: 'sermon',
    shortClip01: 'short',
    shortClip02: 'short',
    testimony01: 'testimony',
    interview01: 'interview',
  });

  const rec = (await db.doc('videos/recording01').get()).data()!;
  assert.equal(rec.series, 'Romans Series');
  assert.equal(rec.hidden, false);
  assert.equal(rec.publishedAt.toDate().toISOString(), '2026-11-22T15:30:00.000Z');

  const live = (await db.doc('church/live').get()).data()!;
  assert.equal(live.status, 'live');
  assert.equal(live.videoId, 'liveNow0001');

  const yt = (await db.doc('church/youtube').get()).data()!;
  assert.deepEqual(yt.series, ['Romans Series']);
});

test('re-sync keeps admin edits, removes privated videos and files finished streams', async () => {
  const db = getFirestore();
  await db.doc('videos/plainUpload').update({ typeOverride: 'testimony', hidden: true, preacher: 'Senior Pastor' });

  const s = scenario();
  // The live service ended, and a testimony was made private.
  const liveVid = s.videos.find((v) => v.id === 'liveNow0001')!;
  liveVid.snippet!.liveBroadcastContent = 'none';
  liveVid.contentDetails = { duration: 'PT1H35M' };
  liveVid.liveStreamingDetails = { ...liveVid.liveStreamingDetails, actualEndTime: s.now.toISOString() };
  s.videos.find((v) => v.id === 'testimony01')!.status = { privacyStatus: 'private' };

  const calls: string[] = [];
  const res = await syncChannel(db, new YouTubeClient('test-key', fakeFetch(s, calls)), {
    channel: CHANNEL_ID,
    now: s.now,
  });
  assert.equal(res.removed, 1);
  assert.equal(res.live, 'upcoming');
  assert.ok(calls.length <= 4 + s.playlists.length, `quota-friendly: ${calls.length} API calls`);

  const plain = (await db.doc('videos/plainUpload').get()).data()!;
  assert.equal(plain.kind, 'testimony', 'typeOverride wins');
  assert.equal(plain.hidden, true);
  assert.equal(plain.preacher, 'Senior Pastor');

  assert.equal((await db.doc('videos/testimony01').get()).get('removed'), true);

  const recording = (await db.doc('videos/liveNow0001').get()).data()!;
  assert.equal(recording.kind, 'sermon', 'the finished live service becomes a sermon');
  assert.equal(recording.isStreamRecording, true);

  const live = (await db.doc('church/live').get()).data()!;
  assert.equal(live.status, 'upcoming');
  assert.equal(live.videoId, 'upcoming001');
});

test('a bad API key surfaces a clear error', async () => {
  const yt = new YouTubeClient('', fakeFetch(scenario()));
  await assert.rejects(() => syncChannel(getFirestore(), yt, { channel: CHANNEL_ID }), /YouTube API channels failed \(403\) API key missing/);
});
