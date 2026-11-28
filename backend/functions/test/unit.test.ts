import { strict as assert } from 'node:assert';
import { test } from 'node:test';

import { classifyVideo, parseChannelRef, parseDuration, pickLive, playlistDoc } from '../src/youtube';
import { scenario } from './fakeYouTube';

test('parseDuration handles hours, minutes, seconds and live placeholders', () => {
  assert.equal(parseDuration('PT1H20M5S'), 4805);
  assert.equal(parseDuration('PT45S'), 45);
  assert.equal(parseDuration('PT2M'), 120);
  assert.equal(parseDuration('P0D'), 0);
  assert.equal(parseDuration(undefined), 0);
});

test('parseChannelRef accepts ids, handles and URLs', () => {
  assert.deepEqual(parseChannelRef('UCbethelPrayerHouse00001'), { kind: 'id', value: 'UCbethelPrayerHouse00001' });
  assert.deepEqual(parseChannelRef('https://www.youtube.com/channel/UCbethelPrayerHouse00001'), {
    kind: 'id',
    value: 'UCbethelPrayerHouse00001',
  });
  assert.deepEqual(parseChannelRef('https://www.youtube.com/@BethelPrayerHouse/videos'), {
    kind: 'handle',
    value: '@BethelPrayerHouse',
  });
  assert.deepEqual(parseChannelRef('bethelprayerhouse'), { kind: 'handle', value: '@bethelprayerhouse' });
});

test('classifyVideo sorts videos into sermons, shorts, testimonies and interviews', () => {
  const s = scenario();
  const byVideo = new Map<string, { id: string; title: string }[]>();
  for (const p of s.playlists) for (const id of p.items) byVideo.set(id, [...(byVideo.get(id) ?? []), p]);
  const c = (id: string) => classifyVideo(s.videos.find((v) => v.id === id)!, byVideo);

  assert.equal(c('liveNow0001'), null, 'live streams are not listed as videos');
  assert.equal(c('upcoming001'), null, 'scheduled streams are not listed as videos');
  assert.equal(c('privateVid1'), null, 'private videos are skipped');

  const rec = c('recording01')!;
  assert.equal(rec.type, 'sermon');
  assert.equal(rec.series, 'Romans Series');
  assert.equal(rec.isStreamRecording, true);
  assert.equal(rec.publishedAt, '2026-11-22T15:30:00Z', 'stream recordings use the stream start time');
  assert.equal(rec.durationSec, 4805);

  assert.equal(c('plainUpload')!.type, 'sermon');
  assert.equal(c('plainUpload')!.series, null, 'ignored playlists (Favorites) do not become series');
  assert.equal(c('shortClip01')!.type, 'short');
  assert.equal(c('shortClip02')!.type, 'short', '#shorts up to 3 minutes counts as a Short');
  assert.equal(c('longNotShrt')!.type, 'sermon', 'over 60s without #shorts is not a Short');
  assert.equal(c('testimony01')!.type, 'testimony');
  assert.equal(c('interview01')!.type, 'interview');
  assert.match(c('recording01')!.thumbnail, /recording01/);
});

test('pickLive prefers a live stream, then the next scheduled one', () => {
  const s = scenario();
  const live = pickLive(s.videos, s.now);
  assert.equal(live.status, 'live');
  assert.equal(live.videoId, 'liveNow0001');
  assert.equal(live.viewers, 87);

  const noLive = s.videos.filter((v) => v.id !== 'liveNow0001');
  const next = pickLive(noLive, s.now);
  assert.equal(next.status, 'upcoming');
  assert.equal(next.videoId, 'upcoming001');

  assert.equal(pickLive([], s.now).status, 'none');
});

test('playlistDoc keeps the channel order and labels testimony and interview playlists', () => {
  const p = { id: 'PL1', title: 'Sunday Services', thumbnail: 'https://i.ytimg.com/x.jpg', itemCount: 84 };
  assert.deepEqual(playlistDoc(p, 0), {
    title: 'Sunday Services',
    thumbnail: 'https://i.ytimg.com/x.jpg',
    itemCount: 84,
    position: 0,
    kind: 'series',
    removed: false,
  });
  assert.equal(playlistDoc({ ...p, title: 'Testimonies 2026' }, 3).kind, 'testimony');
  assert.equal(playlistDoc({ ...p, title: 'Pastor Interviews' }, 4).kind, 'interview');
});

test('classifyVideo sorts uploads into songs and testimonies by title, but never a live service', () => {
  const up = (id: string, title: string, live = false) => ({
    id,
    snippet: { title, publishedAt: '2026-11-01T10:00:00Z', liveBroadcastContent: 'none' as const },
    contentDetails: { duration: 'PT6M10S' },
    status: { privacyStatus: 'public', embeddable: true },
    ...(live ? { liveStreamingDetails: { actualStartTime: '2026-11-01T15:00:00Z', actualEndTime: '2026-11-01T17:00:00Z' } } : {}),
  });
  const none = new Map<string, { id: string; title: string }[]>();
  assert.equal(classifyVideo(up('song00000001', 'Yesu Raja | New Telugu Christian Song 2026'), none)!.type, 'song');
  assert.equal(classifyVideo(up('song00000002', 'దేవుని పాట'), none)!.type, 'song');
  assert.equal(classifyVideo(up('test00000001', 'Testimony - Sis. Mary'), none)!.type, 'testimony');
  assert.equal(classifyVideo(up('serm00000001', 'Walking in the light'), none)!.type, 'sermon');
  assert.equal(classifyVideo(up('live00000001', 'Sunday worship with songs', true), none)!.type, 'sermon', 'live services stay services');
  const inSongs = new Map([['plain0000001', [{ id: 'PLsongs', title: 'Worship Songs' }]]]);
  assert.equal(classifyVideo(up('plain0000001', 'Nee Prema'), inSongs)!.type, 'song', 'a video in a Songs playlist is a song');
  assert.equal(playlistDoc({ id: 'PLsongs', title: 'Worship Songs', thumbnail: '', itemCount: 3 }, 0).kind, 'song');
});

import { LOW_STOCK, QUESTIONS, addDays, centralDateKey, centralDayBounds, nearDuplicates, nextStreak, pickDaily, points, questionId, seedQuestions, similarity, weekKey } from '../src/quiz';

test('quiz bank: four choices, a valid answer, no repeats', () => {
  assert.ok(QUESTIONS.length >= 30);
  assert.equal(new Set(QUESTIONS.map((q) => q.q)).size, QUESTIONS.length);
  for (const q of QUESTIONS) {
    assert.equal(q.choices.length, 4, q.q);
    assert.ok(q.answer >= 0 && q.answer < 4, q.q);
    assert.equal(new Set(q.choices).size, 4, q.q);
  }
});

test('quiz days and weeks follow Central time', () => {
  assert.equal(centralDateKey(new Date('2026-11-28T05:30:00Z')), '2026-11-27', '11:30 PM Friday in Chicago');
  assert.equal(centralDateKey(new Date('2026-11-28T06:30:00Z')), '2026-11-28');
  assert.equal(weekKey('2026-11-28'), '2026-11-23', 'Saturday belongs to the week starting Monday');
  assert.equal(weekKey('2026-11-30'), '2026-11-30');
  assert.equal(weekKey('2026-11-29'), '2026-11-23', 'Sunday ends the week');
  assert.equal(addDays('2026-12-31', 1), '2027-01-01');
  const { opens, closes } = centralDayBounds('2026-11-28');
  assert.equal(opens.toISOString(), '2026-11-28T06:00:00.000Z');
  assert.equal(closes.toISOString(), '2026-11-29T06:00:00.000Z');
  assert.equal(centralDayBounds('2026-07-04').opens.toISOString(), '2026-07-04T05:00:00.000Z', 'daylight saving');
});

test('quiz bank: every question once, no near-duplicates, valid answers', () => {
  const bank = seedQuestions();
  assert.ok(bank.length >= 80, `bank has ${bank.length}`);
  assert.equal(new Set(bank.map((q) => q.id)).size, bank.length, 'ids are unique');
  assert.deepEqual(nearDuplicates(bank), [], 'no two questions ask the same thing');
  for (const q of bank) {
    assert.equal(new Set(q.choices).size, 4, q.q);
    assert.ok(q.answer >= 0 && q.answer < 4, q.q);
    assert.ok(q.ref.length > 2, q.q);
  }
  assert.ok(bank.filter((q) => q.level === 'hard').length >= 40);
});

test('question ids ignore case and punctuation; similar wording is caught', () => {
  assert.equal(questionId('Who built the ark?'), questionId('who built the ARK'));
  assert.notEqual(questionId('Who built the ark?'), questionId('Who built the temple?'));
  assert.ok(similarity('Who carried the cross of Jesus?', 'Who carried Jesus’ cross?') < 1);
  assert.ok(similarity('How old was Methuselah when he died?', 'How old was Methuselah when he died') === 1);
});

test('daily pick: five, mostly hard, the same for the same day, never a used one', () => {
  const pool = seedQuestions().map((q) => ({ id: q.id, level: q.level }));
  const a = pickDaily(pool, '2026-12-06');
  assert.equal(a.length, 5);
  assert.deepEqual(a, pickDaily(pool, '2026-12-06'), 'same day, same pick');
  const hard = new Set(pool.filter((q) => q.level === 'hard').map((q) => q.id));
  assert.ok(a.filter((id) => hard.has(id)).length >= 3);
  // Simulate many days: nothing repeats until the bank runs out.
  let unused = pool;
  const seen = new Set<string>();
  for (let d = 0; d < Math.floor(pool.length / 5); d++) {
    const ids = pickDaily(unused, addDays('2026-12-01', d));
    for (const id of ids) {
      assert.ok(!seen.has(id), 'a question was repeated');
      seen.add(id);
    }
    unused = unused.filter((q) => !ids.includes(q.id));
  }
  assert.ok(pickDaily([], '2026-12-06').length === 0);
  assert.equal(LOW_STOCK, 300);
});

test('quiz scoring and streaks', () => {
  assert.equal(points(false, 9), 0);
  assert.equal(points(true, 1), 10);
  assert.equal(points(true, 3), 14);
  assert.equal(points(true, 30), 20, 'bonus caps at 10');
  assert.equal(nextStreak(undefined, 0, '2026-11-28'), 1);
  assert.equal(nextStreak('2026-11-27', 4, '2026-11-28'), 5);
  assert.equal(nextStreak('2026-11-25', 4, '2026-11-28'), 1);
});
