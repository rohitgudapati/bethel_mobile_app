import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret, defineString } from 'firebase-functions/params';
import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';

import { LOW_STOCK, QUESTIONS_PER_DAY, addDays, centralDateKey, centralDayBounds, nextStreak, pickDaily, points, seedQuestions, weekKey } from './quiz';
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

// ---------------------------------------------------------------- daily questions
// questionBank/{id}   every question with its answer; only the server reads it.
// quiz/{date}         the day's five questions, without answers (public).
// quizKeys/{date}     the day's answers (server only).
// quizAnswers/{date}_{uid}_{i}  a member's answer to question i, created once; onQuizAnswer
//                     checks it, fills in correct/answer/ref/points and adds the points to
//                     leaderboards/{monday}/scores/{uid}.
// quizStats/{date}    how many answered / got each question right (public).
// adminAlerts/quizBank  written when fewer than LOW_STOCK unused questions remain.

/** Adds any question the app ships with that the bank doesn't have yet (by id, so never twice). */
async function seedBank() {
  const db = getFirestore();
  const have = new Set((await db.collection('questionBank').select().get()).docs.map((d) => d.id));
  const missing = seedQuestions().filter((q) => !have.has(q.id));
  for (let i = 0; i < missing.length; i += 400) {
    const batch = db.batch();
    for (const q of missing.slice(i, i + 400)) {
      batch.set(db.collection('questionBank').doc(q.id), {
        q: q.q,
        choices: q.choices,
        answer: q.answer,
        ref: q.ref,
        level: q.level ?? 'medium',
        status: 'ready',
        usedOn: null,
        source: 'app',
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  return missing.length;
}

async function publishQuizDays(days: number) {
  const db = getFirestore();
  await seedBank();
  const today = centralDateKey(new Date());
  for (let i = 0; i < days; i++) {
    const date = addDays(today, i);
    if ((await db.collection('quiz').doc(date).get()).exists) continue; // already published: never re-pick
    const unused = await db.collection('questionBank').where('status', '==', 'ready').where('usedOn', '==', null).get();
    const ids = pickDaily(unused.docs.map((d) => ({ id: d.id, level: d.get('level') })), date);
    if (ids.length === 0) {
      logger.error('Question bank is empty: no quiz published', { date });
      break;
    }
    const byId = new Map(unused.docs.map((d) => [d.id, d.data()]));
    const qs = ids.map((id) => ({ id, ...(byId.get(id) as { q: string; choices: string[]; answer: number; ref: string }) }));
    const { opens, closes } = centralDayBounds(date);
    const batch = db.batch();
    for (const q of qs) batch.update(db.collection('questionBank').doc(q.id), { usedOn: date });
    batch.set(db.collection('quiz').doc(date), {
      date,
      week: weekKey(date),
      count: qs.length,
      questions: qs.map((q) => ({ id: q.id, q: q.q, choices: q.choices })),
      opensAt: Timestamp.fromDate(opens),
      closesAt: Timestamp.fromDate(closes),
    });
    batch.set(db.collection('quizKeys').doc(date), { ids, answers: qs.map((q) => q.answer), refs: qs.map((q) => q.ref) });
    await batch.commit();
  }
  const remaining = (await db.collection('questionBank').where('status', '==', 'ready').where('usedOn', '==', null).count().get()).data().count;
  if (remaining < LOW_STOCK) {
    await db.doc('adminAlerts/quizBank').set({
      remaining,
      daysLeft: Math.floor(remaining / QUESTIONS_PER_DAY),
      message: `Only ${remaining} unused trivia questions left (about ${Math.floor(remaining / QUESTIONS_PER_DAY)} days). Please add more.`,
      at: FieldValue.serverTimestamp(),
    });
    logger.warn('Trivia question bank is running low', { remaining });
  } else {
    await db.doc('adminAlerts/quizBank').delete().catch(() => undefined);
  }
}

/** Shortly after midnight Central: today's questions and the next two days'. */
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
  const a = snap.data() as { uid: string; date: string; index: number; choice: number };
  const db = getFirestore();
  const key = (await db.doc(`quizKeys/${a.date}`).get()).data() as { answers: number[]; refs: string[] } | undefined;
  if (!key || a.index < 0 || a.index >= key.answers.length) return;
  const answer = key.answers[a.index];
  const correct = a.choice === answer;
  const total = key.answers.length;

  let name = 'Member';
  let member = true;
  try {
    const user = await getAuth().getUser(a.uid);
    // Guests (anonymous sign-in) get their answers checked but don't go on the leaderboard.
    member = user.providerData.length > 0;
    const profile = (await db.collection('users').doc(a.uid).get()).data();
    name = String(profile?.name || user.displayName || name).trim() || 'Member';
  } catch (e) {
    logger.warn('No name for quiz player', { uid: a.uid, e: String(e) });
  }

  const week = weekKey(a.date);
  await db.runTransaction(async (tx) => {
    const progressRef = db.collection('quizProgress').doc(`${a.date}_${a.uid}`);
    const streakRef = db.collection('quizStreaks').doc(a.uid);
    const scoreRef = db.collection('leaderboards').doc(week).collection('scores').doc(a.uid);
    const progress = (await tx.get(progressRef)).data() as { done?: number; right?: number; points?: number } | undefined;
    const prev = (await tx.get(streakRef)).data() as { last?: string; streak?: number } | undefined;
    const done = (progress?.done ?? 0) + 1;
    const finished = done >= total;
    // The streak (and its bonus) counts once a day, when the last question is answered.
    const streak = finished ? nextStreak(prev?.last, prev?.streak ?? 0, a.date) : prev?.streak ?? 0;
    const earned = (correct ? 10 : 0) + (finished ? points(true, streak) - 10 : 0);

    tx.update(snap.ref, { correct, answer, ref: key.refs[a.index], points: member ? earned : 0, checkedAt: FieldValue.serverTimestamp() });
    tx.set(
      db.collection('quizStats').doc(a.date),
      { answered: { [a.index]: FieldValue.increment(1) }, right: { [a.index]: FieldValue.increment(correct ? 1 : 0) } },
      { merge: true },
    );
    tx.set(progressRef, { uid: a.uid, date: a.date, done, right: (progress?.right ?? 0) + (correct ? 1 : 0), points: (progress?.points ?? 0) + (member ? earned : 0), streak }, { merge: true });
    if (!member) return;
    if (finished) tx.set(streakRef, { last: a.date, streak }, { merge: true });
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
