import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret, defineString } from 'firebase-functions/params';
import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';

import { syncChannel } from './sync';
import { YouTubeClient } from './youtube';

initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 5 });

/** YouTube Data API key, stored in Secret Manager: `firebase functions:secrets:set YOUTUBE_API_KEY`. */
const youtubeApiKey = defineSecret('YOUTUBE_API_KEY');
/** The church channel: id (UC...), @handle or URL. Asked for on first deploy. */
const youtubeChannel = defineString('YOUTUBE_CHANNEL', {
  description: 'Church YouTube channel: @handle, channel id (UC...) or channel URL',
});

async function runSync(full: boolean) {
  const result = await syncChannel(getFirestore(), new YouTubeClient(youtubeApiKey.value()), {
    channel: youtubeChannel.value(),
    full,
  });
  logger.info('YouTube sync finished', { full, ...result });
  return result;
}

/** Every 10 minutes: live status and the latest uploads. */
export const syncYouTube = onSchedule(
  { schedule: 'every 10 minutes', timeZone: 'America/Chicago', secrets: [youtubeApiKey], timeoutSeconds: 120 },
  async () => {
    await runSync(false);
  },
);

/** Every night: whole channel history and all playlists. */
export const syncYouTubeFull = onSchedule(
  { schedule: 'every day 03:15', timeZone: 'America/Chicago', secrets: [youtubeApiKey], timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    await runSync(true);
  },
);

/** Admins can trigger a sync from the app (e.g. right after going live). */
export const syncYouTubeNow = onCall({ secrets: [youtubeApiKey], timeoutSeconds: 540 }, async (req) => {
  if (req.auth?.token.admin !== true) throw new HttpsError('permission-denied', 'Only church admins can run a sync.');
  return runSync(Boolean(req.data?.full));
});

// ---------------------------------------------------------------- counters
// Counters are kept by functions so one person can't inflate them.

export const onPrayed = onDocumentCreated('prayerRequests/{id}/prayedBy/{uid}', async (event) => {
  await getFirestore()
    .collection('prayerRequests')
    .doc(event.params.id)
    .update({ prayedCount: FieldValue.increment(1) });
});

export const onVerseLiked = onDocumentCreated('verses/{id}/likes/{uid}', async (event) => {
  await getFirestore().collection('verses').doc(event.params.id).update({ likes: FieldValue.increment(1) });
});

export const onVerseUnliked = onDocumentDeleted('verses/{id}/likes/{uid}', async (event) => {
  await getFirestore().collection('verses').doc(event.params.id).update({ likes: FieldValue.increment(-1) });
});
