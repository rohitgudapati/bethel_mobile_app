/**
 * YouTube Data API v3 client and the rules that turn channel videos into
 * app content. Pure functions here; Firestore writes live in sync.ts.
 *
 * Quota: each sync costs about 4 + (number of playlists) units, well under the
 * default 10,000 units/day even when run every 10 minutes.
 */

export type FetchLike = (url: string) => Promise<{ ok: boolean; status: number; json(): Promise<any> }>;

const API = 'https://www.googleapis.com/youtube/v3';

export class YouTubeClient {
  constructor(private readonly apiKey: string, private readonly fetchImpl: FetchLike = fetch as unknown as FetchLike) {}

  private async get(path: string, params: Record<string, string | number>): Promise<any> {
    const qs = new URLSearchParams({ ...Object.fromEntries(Object.entries(params).map(([k, v]) => [k, String(v)])), key: this.apiKey });
    const res = await this.fetchImpl(`${API}/${path}?${qs}`);
    if (!res.ok) {
      let detail = '';
      try {
        detail = (await res.json())?.error?.message ?? '';
      } catch {
        /* ignore */
      }
      throw new Error(`YouTube API ${path} failed (${res.status}) ${detail}`.trim());
    }
    return res.json();
  }

  /** Accepts a channel id (UC...), an @handle or a youtube.com URL containing either. */
  async resolveChannel(channel: string): Promise<{ id: string; title: string; uploadsPlaylistId: string }> {
    const ref = parseChannelRef(channel);
    const params: Record<string, string> = { part: 'snippet,contentDetails' };
    if (ref.kind === 'id') params.id = ref.value;
    else params.forHandle = ref.value;
    const data = await this.get('channels', params);
    const item = data.items?.[0];
    if (!item) throw new Error(`YouTube channel not found: ${channel}`);
    return {
      id: item.id,
      title: item.snippet?.title ?? '',
      uploadsPlaylistId: item.contentDetails?.relatedPlaylists?.uploads,
    };
  }

  /** Video ids in a playlist, newest first, up to `max`. */
  async playlistVideoIds(playlistId: string, max = 50): Promise<string[]> {
    const ids: string[] = [];
    let pageToken: string | undefined;
    do {
      const data = await this.get('playlistItems', {
        part: 'contentDetails',
        playlistId,
        maxResults: Math.min(50, max - ids.length),
        ...(pageToken ? { pageToken } : {}),
      });
      for (const it of data.items ?? []) {
        const id = it.contentDetails?.videoId;
        if (id) ids.push(id);
      }
      pageToken = data.nextPageToken;
    } while (pageToken && ids.length < max);
    return ids;
  }

  async playlists(channelId: string): Promise<ChannelPlaylist[]> {
    const out: ChannelPlaylist[] = [];
    let pageToken: string | undefined;
    do {
      const data = await this.get('playlists', {
        part: 'snippet,contentDetails',
        channelId,
        maxResults: 50,
        ...(pageToken ? { pageToken } : {}),
      });
      for (const p of data.items ?? []) {
        out.push({
          id: p.id,
          title: p.snippet?.title ?? '',
          thumbnail: bestThumbnail(p),
          itemCount: p.contentDetails?.itemCount ?? 0,
        });
      }
      pageToken = data.nextPageToken;
    } while (pageToken && out.length < 200);
    return out;
  }

  async videos(ids: string[]): Promise<RawVideo[]> {
    const out: RawVideo[] = [];
    for (let i = 0; i < ids.length; i += 50) {
      const data = await this.get('videos', {
        part: 'snippet,contentDetails,liveStreamingDetails,status',
        id: ids.slice(i, i + 50).join(','),
        maxResults: 50,
      });
      out.push(...(data.items ?? []));
    }
    return out;
  }
}

export function parseChannelRef(input: string): { kind: 'id' | 'handle'; value: string } {
  const s = input.trim();
  const idMatch = s.match(/(UC[\w-]{22})/);
  if (idMatch) return { kind: 'id', value: idMatch[1] };
  const handleMatch = s.match(/@([\w.\-]+)/);
  if (handleMatch) return { kind: 'handle', value: `@${handleMatch[1]}` };
  return { kind: 'handle', value: s.startsWith('@') ? s : `@${s}` };
}

// ---------------------------------------------------------------- classification

export interface RawVideo {
  id: string;
  snippet?: {
    title?: string;
    description?: string;
    publishedAt?: string;
    liveBroadcastContent?: 'live' | 'upcoming' | 'none';
    thumbnails?: Record<string, { url: string; width?: number; height?: number }>;
  };
  contentDetails?: { duration?: string };
  liveStreamingDetails?: {
    actualStartTime?: string;
    actualEndTime?: string;
    scheduledStartTime?: string;
    concurrentViewers?: string;
  };
  status?: { privacyStatus?: string; embeddable?: boolean };
}

export type VideoType = 'sermon' | 'short' | 'testimony' | 'interview';

export interface VideoDoc {
  videoId: string;
  type: VideoType;
  title: string;
  description: string;
  thumbnail: string;
  publishedAt: string; // ISO; converted to a Timestamp when written
  durationSec: number;
  series: string | null;
  playlistIds: string[];
  isStreamRecording: boolean;
  embeddable: boolean;
}

export interface LiveDoc {
  status: 'live' | 'upcoming' | 'none';
  videoId: string | null;
  title: string;
  description: string;
  thumbnail: string;
  scheduledStart: string | null;
  viewers: number | null;
}

export interface SyncRules {
  /** Videos at or under this length are Shorts. YouTube allows Shorts up to 3 minutes. */
  shortMaxSec: number;
  /** Playlist title patterns → content type. Anything else is a sermon series. */
  testimonyPattern: RegExp;
  interviewPattern: RegExp;
  /** Playlists whose titles match this are ignored (e.g. "Favorites"). */
  ignorePlaylistPattern: RegExp;
}

export const defaultRules: SyncRules = {
  shortMaxSec: 180,
  testimonyPattern: /testimon/i,
  interviewPattern: /interview/i,
  ignorePlaylistPattern: /^(favorites|liked videos|uploads)$/i,
};

/** ISO 8601 duration (PT1H2M3S) → seconds. */
export function parseDuration(iso: string | undefined): number {
  if (!iso) return 0;
  const m = iso.match(/^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
  if (!m) return 0;
  const [, d, h, min, s] = m.map((x) => (x ? Number(x) : 0));
  return d * 86400 + h * 3600 + min * 60 + s;
}

/** A playlist on the channel, as the app shows it on Watch. */
export interface ChannelPlaylist {
  id: string;
  title: string;
  thumbnail: string;
  itemCount: number;
}

/** What `playlists/{id}` holds. `position` keeps the channel's own order. */
export function playlistDoc(p: ChannelPlaylist, position: number, rules: SyncRules = defaultRules) {
  const kind = rules.testimonyPattern.test(p.title) ? 'testimony' : rules.interviewPattern.test(p.title) ? 'interview' : 'series';
  return { title: p.title, thumbnail: p.thumbnail, itemCount: p.itemCount, position, kind, removed: false };
}

export function bestThumbnail(v: { snippet?: { thumbnails?: Record<string, { url: string }> } }): string {
  const t = v.snippet?.thumbnails ?? {};
  return (t.maxres ?? t.standard ?? t.high ?? t.medium ?? t.default)?.url ?? '';
}

function isShort(v: RawVideo, durationSec: number, rules: SyncRules): boolean {
  if (durationSec === 0 || v.liveStreamingDetails) return false;
  if (durationSec <= 60) return true;
  const text = `${v.snippet?.title ?? ''} ${v.snippet?.description ?? ''}`;
  return durationSec <= rules.shortMaxSec && /#shorts?\b/i.test(text);
}

/**
 * Turns a YouTube video into an app video, or null when it should not be listed
 * (private, still live/upcoming, or a scheduled stream that never happened).
 */
export function classifyVideo(
  v: RawVideo,
  playlistsByVideo: Map<string, { id: string; title: string }[]>,
  rules: SyncRules = defaultRules,
): VideoDoc | null {
  const privacy = v.status?.privacyStatus;
  if (privacy && privacy !== 'public' && privacy !== 'unlisted') return null;
  const broadcast = v.snippet?.liveBroadcastContent ?? 'none';
  if (broadcast !== 'none') return null; // shown via the live document instead
  if (v.liveStreamingDetails && !v.liveStreamingDetails.actualEndTime) return null;

  const durationSec = parseDuration(v.contentDetails?.duration);
  const lists = (playlistsByVideo.get(v.id) ?? []).filter((p) => !rules.ignorePlaylistPattern.test(p.title));

  let type: VideoType = 'sermon';
  let series: string | null = null;
  if (isShort(v, durationSec, rules)) {
    type = 'short';
  } else if (lists.some((p) => rules.testimonyPattern.test(p.title))) {
    type = 'testimony';
  } else if (lists.some((p) => rules.interviewPattern.test(p.title))) {
    type = 'interview';
  } else if (lists.length > 0) {
    series = lists[0].title;
  }

  return {
    videoId: v.id,
    type,
    title: v.snippet?.title ?? '',
    description: v.snippet?.description ?? '',
    thumbnail: bestThumbnail(v),
    publishedAt: v.liveStreamingDetails?.actualStartTime ?? v.snippet?.publishedAt ?? new Date(0).toISOString(),
    durationSec,
    series,
    playlistIds: lists.map((p) => p.id),
    isStreamRecording: Boolean(v.liveStreamingDetails),
    embeddable: v.status?.embeddable ?? true,
  };
}

/** Live now beats upcoming; upcoming picks the soonest future start. */
export function pickLive(videos: RawVideo[], now: Date = new Date()): LiveDoc {
  const live = videos.find((v) => v.snippet?.liveBroadcastContent === 'live');
  const upcoming = videos
    .filter((v) => v.snippet?.liveBroadcastContent === 'upcoming' && v.liveStreamingDetails?.scheduledStartTime)
    .filter((v) => new Date(v.liveStreamingDetails!.scheduledStartTime!).getTime() > now.getTime() - 2 * 3600_000)
    .sort(
      (a, b) =>
        new Date(a.liveStreamingDetails!.scheduledStartTime!).getTime() -
        new Date(b.liveStreamingDetails!.scheduledStartTime!).getTime(),
    )[0];
  const v = live ?? upcoming;
  if (!v) {
    return { status: 'none', videoId: null, title: '', description: '', thumbnail: '', scheduledStart: null, viewers: null };
  }
  return {
    status: live ? 'live' : 'upcoming',
    videoId: v.id,
    title: v.snippet?.title ?? '',
    description: v.snippet?.description ?? '',
    thumbnail: bestThumbnail(v),
    scheduledStart: v.liveStreamingDetails?.scheduledStartTime ?? null,
    viewers: v.liveStreamingDetails?.concurrentViewers ? Number(v.liveStreamingDetails.concurrentViewers) : null,
  };
}
