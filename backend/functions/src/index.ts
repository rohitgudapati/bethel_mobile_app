import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret, defineString } from 'firebase-functions/params';
import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';

import { addDays, centralDateKey, centralDayBounds, nextStreak, points, questionFor, weekKey } from './quiz';
import { syncChannel } from './sync';
import { YouTubeClient } from './youtube';

initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 5 });

/** YouTube Data API key, stored in Secret Manager: `firebase functions:secrets:set YOUTUBE_API_KEY`. */
const youtubeApiKey = defineSecret('YOUTUBE_API_KEY');
/** The church channel: id (UC...), @handle or URL. Asked for on first deploy. */
const youtubeChannel = defineString('YOUTUBE_CHANNEL', {
  description: 'Church YouTube channel: @handle, channel id (UC...) or channel URL',
  default: '@bethelprayerhousenaperville',
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

/**
 * Sundays 2:00–5:58 PM Central, every 2 minutes: the 3:00 PM service shows as LIVE
 * within about two minutes of the stream starting, and drops off soon after it ends.
 */
export const syncYouTubeSunday = onSchedule(
  { schedule: '*/2 14-17 * * 0', timeZone: 'America/Chicago', secrets: [youtubeApiKey], timeoutSeconds: 100 },
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
  // set+merge: the built-in daily verse has no document until its first like.
  await getFirestore().collection('verses').doc(event.params.id).set({ likes: FieldValue.increment(1) }, { merge: true });
});

export const onVerseUnliked = onDocumentDeleted('verses/{id}/likes/{uid}', async (event) => {
  await getFirestore().collection('verses').doc(event.params.id).set({ likes: FieldValue.increment(-1) }, { merge: true });
});

// ---------------------------------------------------------------- daily question
// quiz/{date} holds the question (never the answer). A member answers by creating
// quizAnswers/{date}_{uid}; onQuizAnswer checks it and adds the points to this week's
// leaderboard, leaderboards/{monday}/scores/{uid}.

async function publishQuizDays(days: number) {
  const db = getFirestore();
  const today = centralDateKey(new Date());
  for (let i = 0; i < days; i++) {
    const date = addDays(today, i);
    const q = questionFor(date);
    const { opens, closes } = centralDayBounds(date);
    await db.collection('quiz').doc(date).set({
      date,
      question: q.q,
      choices: q.choices,
      week: weekKey(date),
      opensAt: Timestamp.fromDate(opens),
      closesAt: Timestamp.fromDate(closes),
    });
  }
}

/** Shortly after midnight Central: today's question and the next two days'. */
export const publishQuiz = onSchedule({ schedule: 'every day 00:01', timeZone: 'America/Chicago' }, async () => {
  await publishQuizDays(3);
});

/** Admins can publish right away (e.g. after the first deploy). */
export const publishQuizNow = onCall(async (req) => {
  if (req.auth?.token.admin !== true) throw new HttpsError('permission-denied', 'Only church admins can do this.');
  await publishQuizDays(3);
  return { ok: true };
});

export const onQuizAnswer = onDocumentCreated('quizAnswers/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const a = snap.data() as { uid: string; date: string; choice: number };
  const db = getFirestore();
  const q = questionFor(a.date);
  const correct = a.choice === q.answer;

  let name = 'Member';
  let member = true;
  try {
    const user = await getAuth().getUser(a.uid);
    // Guests (anonymous sign-in) get their answer checked but don't go on the leaderboard.
    member = user.providerData.length > 0;
    const profile = (await db.collection('users').doc(a.uid).get()).data();
    name = String(profile?.name || user.displayName || name).trim() || 'Member';
  } catch (e) {
    logger.warn('No name for quiz player', { uid: a.uid, e: String(e) });
  }

  const week = weekKey(a.date);
  await db.runTransaction(async (tx) => {
    const streakRef = db.collection('quizStreaks').doc(a.uid);
    const scoreRef = db.collection('leaderboards').doc(week).collection('scores').doc(a.uid);
    const prev = (await tx.get(streakRef)).data() as { last?: string; streak?: number } | undefined;
    const streak = nextStreak(prev?.last, prev?.streak ?? 0, a.date);
    const earned = points(correct, streak);
    tx.update(snap.ref, { correct, answer: q.answer, ref: q.ref, points: member ? earned : 0, streak, checkedAt: FieldValue.serverTimestamp() });
    if (!member) return;
    tx.set(streakRef, { last: a.date, streak }, { merge: true });
    tx.set(
      scoreRef,
      {
        name,
        points: FieldValue.increment(earned),
        correct: FieldValue.increment(correct ? 1 : 0),
        played: FieldValue.increment(1),
        streak,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
});
