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
