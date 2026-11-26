import { Firestore, Timestamp, FieldValue } from 'firebase-admin/firestore';

import { classifyVideo, defaultRules, pickLive, playlistDoc, SyncRules, YouTubeClient } from './youtube';

export interface SyncOptions {
  /** Channel id, @handle or channel URL. */
  channel: string;
  /** Scan the whole upload history and every playlist (daily); otherwise the latest 50 uploads. */
  full?: boolean;
  rules?: SyncRules;
  now?: Date;
}

export interface SyncResult {
  channelId: string;
  scanned: number;
  written: number;
  removed: number;
  live: 'live' | 'upcoming' | 'none';
  liveVideoId: string | null;
}

/**
 * Pulls the church's YouTube channel into Firestore:
 *   videos/{videoId}  sermons, shorts, testimonies, interviews
 *   church/live       what is live now or scheduled next
 *   church/youtube    channel details and last sync time
 *   playlists/{id}    the channel's playlists in its own order (Watch shows one shelf each)
 *
 * Admin edits (`hidden`, `typeOverride`, `preacher`, `seriesOverride`) are never overwritten.
 * The app lists videos by `kind`, which is `typeOverride` when set, else the detected type.
 */
export async function syncChannel(db: Firestore, yt: YouTubeClient, opts: SyncOptions): Promise<SyncResult> {
  const rules = opts.rules ?? defaultRules;
  const channel = await yt.resolveChannel(opts.channel);

  const uploadIds = await yt.playlistVideoIds(channel.uploadsPlaylistId, opts.full ? 2000 : 50);

  // Playlist membership decides series, testimonies and interviews.
  const playlistsByVideo = new Map<string, { id: string; title: string }[]>();
  const playlists = await yt.playlists(channel.id);
  for (const p of playlists) {
    if (rules.ignorePlaylistPattern.test(p.title)) continue;
    const ids = await yt.playlistVideoIds(p.id, opts.full ? 500 : 50);
    for (const id of ids) {
      const list = playlistsByVideo.get(id) ?? [];
      list.push(p);
      playlistsByVideo.set(id, list);
    }
  }

  const raw = await yt.videos(uploadIds);
  const live = pickLive(raw, opts.now);

  // Existing docs, so admin overrides are respected.
  const refs = raw.map((v) => db.collection('videos').doc(v.id));
  const existing = new Map<string, FirebaseFirestore.DocumentData>();
  for (let i = 0; i < refs.length; i += 300) {
    const snaps = refs.length ? await db.getAll(...refs.slice(i, i + 300)) : [];
    for (const s of snaps) if (s.exists) existing.set(s.id, s.data()!);
  }

  let written = 0;
  let removed = 0;
  let batch = db.batch();
  let ops = 0;
  const flush = async () => {
    if (ops > 0) await batch.commit();
    batch = db.batch();
    ops = 0;
  };

  for (const v of raw) {
    const ref = db.collection('videos').doc(v.id);
    const prev = existing.get(v.id);
    const doc = classifyVideo(v, playlistsByVideo, rules);
    if (!doc) {
      // Private, deleted or not finished streaming: keep it out of the app.
      const stillStreaming = (v.snippet?.liveBroadcastContent ?? 'none') !== 'none';
      if (prev && !prev.removed && !stillStreaming) {
        batch.set(ref, { removed: true, syncedAt: FieldValue.serverTimestamp() }, { merge: true });
        ops++;
        removed++;
      }
    } else {
      batch.set(
        ref,
        {
          ...doc,
          publishedAt: Timestamp.fromDate(new Date(doc.publishedAt)),
          kind: prev?.typeOverride ?? doc.type,
          removed: false,
          ...(prev ? {} : { hidden: false, createdAt: FieldValue.serverTimestamp() }),
          syncedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      ops++;
      written++;
    }
    if (ops >= 400) await flush();
  }

  // Playlists, in the channel's order. Ones gone from the channel are marked removed.
  const shown = playlists.filter((p) => !rules.ignorePlaylistPattern.test(p.title));
  shown.forEach((p, i) => {
    batch.set(db.collection('playlists').doc(p.id), { ...playlistDoc(p, i, rules), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    ops++;
  });
  const known = await db.collection('playlists').where('removed', '==', false).get();
  for (const d of known.docs) {
    if (!shown.some((p) => p.id === d.id)) {
      batch.set(d.ref, { removed: true, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      ops++;
    }
  }
  if (ops >= 400) await flush();

  batch.set(db.collection('church').doc('live'), { ...live, updatedAt: FieldValue.serverTimestamp() });
  batch.set(
    db.collection('church').doc('youtube'),
    {
      channelId: channel.id,
      channelTitle: channel.title,
      channelUrl: `https://www.youtube.com/channel/${channel.id}`,
      lastSync: FieldValue.serverTimestamp(),
      ...(opts.full ? { lastFullSync: FieldValue.serverTimestamp() } : {}),
      series: [...new Set(playlists.map((p) => p.title))].filter(
        (t) => !rules.ignorePlaylistPattern.test(t) && !rules.testimonyPattern.test(t) && !rules.interviewPattern.test(t),
      ),
    },
    { merge: true },
  );
  ops += 2;
  await flush();

  return { channelId: channel.id, scanned: raw.length, written, removed, live: live.status, liveVideoId: live.videoId };
}
