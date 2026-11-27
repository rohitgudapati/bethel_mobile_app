import { FetchLike, RawVideo } from '../src/youtube';

export const CHANNEL_ID = 'UCbethelPrayerHouse00001';
export const UPLOADS = 'UUbethelPrayerHouse00001';

const iso = (d: Date) => d.toISOString();

/** A small, realistic channel: one live stream, one upcoming, recordings, shorts, playlists. */
export function scenario(now = new Date('2026-11-29T16:45:00Z')) {
  const thumb = (id: string) => ({ high: { url: `https://i.ytimg.com/vi/${id}/hqdefault.jpg` } });
  const v = (id: string, extra: Partial<RawVideo> & { title: string; duration?: string; published?: string }): RawVideo => ({
    id,
    snippet: {
      title: extra.title,
      description: `${extra.title} description`,
      publishedAt: extra.published ?? '2026-11-20T15:00:00Z',
      liveBroadcastContent: 'none',
      thumbnails: thumb(id),
      ...(extra.snippet ?? {}),
    },
    contentDetails: { duration: extra.duration ?? 'PT30M' },
    status: { privacyStatus: 'public', embeddable: true, ...(extra.status ?? {}) },
    ...(extra.liveStreamingDetails ? { liveStreamingDetails: extra.liveStreamingDetails } : {}),
  });

  const videos: RawVideo[] = [
    v('liveNow0001', {
      title: 'Sunday Worship Service – Live',
      duration: 'P0D',
      snippet: { liveBroadcastContent: 'live' } as any,
      liveStreamingDetails: { actualStartTime: iso(new Date(now.getTime() - 15 * 60_000)), concurrentViewers: '87' },
    }),
    v('upcoming001', {
      title: 'Friday Night Prayer',
      duration: 'P0D',
      snippet: { liveBroadcastContent: 'upcoming' } as any,
      liveStreamingDetails: { scheduledStartTime: iso(new Date(now.getTime() + 5 * 86400_000)) },
    }),
    v('recording01', {
      title: 'Not Ashamed of the Gospel | Romans 1',
      duration: 'PT1H20M5S',
      published: '2026-11-22T15:30:00Z',
      liveStreamingDetails: { actualStartTime: '2026-11-22T15:30:00Z', actualEndTime: '2026-11-22T17:00:00Z' },
    }),
    v('plainUpload', { title: 'Midweek Devotion', duration: 'PT35M', published: '2026-11-19T00:00:00Z' }),
    v('shortClip01', { title: 'A one-minute prayer', duration: 'PT45S' }),
    v('shortClip02', { title: 'Verse for your week #shorts', duration: 'PT2M10S' }),
    v('longNotShrt', { title: 'Choir practice highlights', duration: 'PT2M30S' }),
    v('testimony01', { title: 'Healed and restored', duration: 'PT8M' }),
    v('interview01', { title: 'How Bethel began', duration: 'PT20M' }),
    v('privateVid1', { title: 'Draft', status: { privacyStatus: 'private' } }),
  ];

  const playlists = [
    { id: 'PLromans', title: 'Romans Series', items: ['recording01'] },
    { id: 'PLtestim', title: 'Testimonies', items: ['testimony01'] },
    { id: 'PLinterv', title: 'Interviews 2026', items: ['interview01'] },
    { id: 'PLfav', title: 'Favorites', items: ['plainUpload'] },
  ];
  return { now, videos, playlists };
}

export type Scenario = ReturnType<typeof scenario>;

/** A fetch stand-in that answers the four YouTube endpoints the sync uses. */
export function fakeFetch(s: Scenario, calls: string[] = []): FetchLike {
  return async (url: string) => {
    calls.push(url);
    const u = new URL(url);
    const p = u.searchParams;
    const endpoint = u.pathname.split('/').pop();
    let body: any;
    if (!p.get('key')) return { ok: false, status: 403, json: async () => ({ error: { message: 'API key missing' } }) };
    switch (endpoint) {
      case 'channels':
        body =
          p.get('id') === CHANNEL_ID || p.get('forHandle') === '@bethelprayerhouse'
            ? { items: [{ id: CHANNEL_ID, snippet: { title: 'Bethel Prayer House' }, contentDetails: { relatedPlaylists: { uploads: UPLOADS } } }] }
            : { items: [] };
        break;
      case 'playlistItems': {
        const id = p.get('playlistId');
        const ids = id === UPLOADS ? s.videos.map((v) => v.id) : (s.playlists.find((x) => x.id === id)?.items ?? []);
        body = { items: ids.map((videoId) => ({ contentDetails: { videoId } })) };
        break;
      }
      case 'playlists':
        body = {
          items: s.playlists.map((x) => ({
            id: x.id,
            snippet: { title: x.title, thumbnails: { high: { url: `https://i.ytimg.com/pl/${x.id}.jpg` } } },
            contentDetails: { itemCount: x.items.length },
          })),
        };
        break;
      case 'videos': {
        const ids = (p.get('id') ?? '').split(',');
        body = { items: s.videos.filter((v) => ids.includes(v.id)) };
        break;
      }
      default:
        return { ok: false, status: 404, json: async () => ({}) };
    }
    return { ok: true, status: 200, json: async () => body };
  };
}
