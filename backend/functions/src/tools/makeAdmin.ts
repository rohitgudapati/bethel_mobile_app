/**
 * Gives a person admin rights (edit content, read prayer contacts, run a YouTube sync).
 *
 *   GOOGLE_CLOUD_PROJECT=<project-id> npm run make-admin -- person@example.com
 *
 * The person must have signed in to the app once. They need to sign out and in again
 * for the change to apply.
 */
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

async function main() {
  const email = process.argv[2];
  if (!email) throw new Error('Usage: npm run make-admin -- person@example.com');
  initializeApp();
  const user = await getAuth().getUserByEmail(email);
  await getAuth().setCustomUserClaims(user.uid, { ...(user.customClaims ?? {}), admin: true });
  console.log(`${email} is now an admin.`);
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
