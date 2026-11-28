/**
 * The daily Bible question: one question a day for everyone, answered once, checked on
 * the server (the answers live only here), scored into a weekly leaderboard that starts
 * over every Monday (Central time).
 */

export interface QuizQuestion {
  q: string;
  choices: [string, string, string, string];
  /** Index of the right choice. */
  answer: number;
  /** Where to read about it. */
  ref: string;
}

export const QUESTIONS: QuizQuestion[] = [
  { q: 'How many books are in the Bible?', choices: ['39', '27', '66', '73'], answer: 2, ref: 'The whole Bible' },
  { q: 'Who built the ark?', choices: ['Moses', 'Noah', 'Abraham', 'Jonah'], answer: 1, ref: 'Genesis 6' },
  { q: 'What was Jesus’ first miracle in the Gospel of John?', choices: ['Calming the storm', 'Feeding 5,000', 'Water into wine', 'Healing a blind man'], answer: 2, ref: 'John 2:1–11' },
  { q: 'Who was swallowed by a great fish?', choices: ['Jonah', 'Elijah', 'Peter', 'Daniel'], answer: 0, ref: 'Jonah 1:17' },
  { q: 'How many disciples did Jesus choose?', choices: ['7', '10', '12', '70'], answer: 2, ref: 'Luke 6:13' },
  { q: 'What is the shortest verse in the KJV Bible?', choices: ['“Jesus wept.”', '“Pray without ceasing.”', '“God is love.”', '“Rejoice evermore.”'], answer: 0, ref: 'John 11:35' },
  { q: 'Who killed Goliath?', choices: ['Saul', 'Jonathan', 'Samson', 'David'], answer: 3, ref: '1 Samuel 17' },
  { q: 'Which book comes first in the New Testament?', choices: ['Mark', 'Matthew', 'Luke', 'Acts'], answer: 1, ref: 'Matthew 1' },
  { q: 'In what town was Jesus born?', choices: ['Nazareth', 'Jerusalem', 'Bethlehem', 'Capernaum'], answer: 2, ref: 'Matthew 2:1' },
  { q: 'Who denied Jesus three times?', choices: ['Judas', 'Thomas', 'John', 'Peter'], answer: 3, ref: 'Luke 22:54–62' },
  { q: 'What is the longest book in the Bible by chapters?', choices: ['Isaiah', 'Psalms', 'Genesis', 'Jeremiah'], answer: 1, ref: 'Psalms' },
  { q: 'Who received the Ten Commandments on Mount Sinai?', choices: ['Aaron', 'Joshua', 'Moses', 'Elijah'], answer: 2, ref: 'Exodus 20' },
  { q: 'How many days and nights did it rain in the flood?', choices: ['7', '40', '150', '12'], answer: 1, ref: 'Genesis 7:12' },
  { q: 'Who was thrown into the lions’ den?', choices: ['Daniel', 'Shadrach', 'Joseph', 'Jeremiah'], answer: 0, ref: 'Daniel 6' },
  { q: 'What did God create on the first day?', choices: ['Animals', 'Light', 'Man', 'The sea'], answer: 1, ref: 'Genesis 1:3–5' },
  { q: 'Who wrote most of the letters in the New Testament?', choices: ['Peter', 'John', 'James', 'Paul'], answer: 3, ref: 'Romans – Philemon' },
  { q: 'Which disciple doubted until he saw Jesus’ wounds?', choices: ['Thomas', 'Andrew', 'Philip', 'Matthew'], answer: 0, ref: 'John 20:24–29' },
  { q: 'What was the name of Abraham’s wife?', choices: ['Rebekah', 'Rachel', 'Sarah', 'Leah'], answer: 2, ref: 'Genesis 17:15' },
  { q: 'How many loaves fed the five thousand?', choices: ['Two', 'Five', 'Seven', 'Twelve'], answer: 1, ref: 'Matthew 14:17–21' },
  { q: 'Who was sold into slavery by his brothers?', choices: ['Benjamin', 'Joseph', 'Reuben', 'Judah'], answer: 1, ref: 'Genesis 37' },
  { q: 'Which river was Jesus baptized in?', choices: ['Nile', 'Euphrates', 'Jordan', 'Tigris'], answer: 2, ref: 'Matthew 3:13' },
  { q: 'What is the last book of the Bible?', choices: ['Jude', 'Revelation', 'Malachi', '3 John'], answer: 1, ref: 'Revelation 22' },
  { q: 'Who betrayed Jesus for thirty pieces of silver?', choices: ['Peter', 'Judas Iscariot', 'Barabbas', 'Pilate'], answer: 1, ref: 'Matthew 26:14–16' },
  { q: 'Whose walls fell after the people marched around them?', choices: ['Jericho', 'Babylon', 'Nineveh', 'Ai'], answer: 0, ref: 'Joshua 6' },
  { q: 'What is the first of the fruit of the Spirit listed in Galatians?', choices: ['Joy', 'Peace', 'Love', 'Faith'], answer: 2, ref: 'Galatians 5:22' },
  { q: '“The Lord is my shepherd” begins which Psalm?', choices: ['Psalm 1', 'Psalm 23', 'Psalm 91', 'Psalm 121'], answer: 1, ref: 'Psalm 23:1' },
  { q: 'Who was the first king of Israel?', choices: ['David', 'Solomon', 'Saul', 'Samuel'], answer: 2, ref: '1 Samuel 10' },
  { q: 'Which king asked God for wisdom?', choices: ['Solomon', 'Hezekiah', 'Josiah', 'Ahab'], answer: 0, ref: '1 Kings 3' },
  { q: 'Who climbed a sycamore tree to see Jesus?', choices: ['Nicodemus', 'Zacchaeus', 'Bartimaeus', 'Lazarus'], answer: 1, ref: 'Luke 19:1–10' },
  { q: 'On which day did the Holy Spirit come on the disciples in Acts 2?', choices: ['Passover', 'Pentecost', 'The Sabbath', 'Tabernacles'], answer: 1, ref: 'Acts 2:1–4' },
  { q: 'What did Esau sell to Jacob for a meal?', choices: ['His land', 'His birthright', 'His flock', 'His coat'], answer: 1, ref: 'Genesis 25:29–34' },
  { q: 'Who was Ruth’s mother-in-law?', choices: ['Naomi', 'Orpah', 'Hannah', 'Deborah'], answer: 0, ref: 'Ruth 1' },
  { q: 'How many books are in the New Testament?', choices: ['27', '29', '39', '24'], answer: 0, ref: 'Matthew – Revelation' },
  { q: 'Which prophet was taken up to heaven in a whirlwind?', choices: ['Elisha', 'Isaiah', 'Elijah', 'Ezekiel'], answer: 2, ref: '2 Kings 2:11' },
  { q: 'Whom did Jesus raise from the dead after four days?', choices: ['Jairus’ daughter', 'Lazarus', 'Dorcas', 'The widow’s son'], answer: 1, ref: 'John 11' },
  { q: 'What was Paul’s name before his conversion?', choices: ['Simon', 'Saul', 'Silas', 'Stephen'], answer: 1, ref: 'Acts 9; 13:9' },
  { q: 'Which book tells of Queen Esther saving her people?', choices: ['Ruth', 'Esther', 'Judges', 'Nehemiah'], answer: 1, ref: 'Esther 4–8' },
  { q: 'Who led the rebuilding of Jerusalem’s walls?', choices: ['Ezra', 'Nehemiah', 'Zerubbabel', 'Haggai'], answer: 1, ref: 'Nehemiah 2–6' },
  { q: 'What did Jesus say is the greatest commandment?', choices: ['Do not steal', 'Love the Lord your God with all your heart', 'Keep the Sabbath', 'Honour your parents'], answer: 1, ref: 'Matthew 22:37–38' },
  { q: 'How many times should we forgive, Jesus told Peter?', choices: ['Seven', 'Seventy times seven', 'Three', 'Twelve'], answer: 1, ref: 'Matthew 18:21–22' },
  { q: 'Who was the mother of John the Baptist?', choices: ['Mary', 'Elisabeth', 'Anna', 'Martha'], answer: 1, ref: 'Luke 1:57–60' },
  { q: 'What are the first words of the Bible?', choices: ['“In the beginning God…”', '“Hear, O Israel…”', '“The Lord is my shepherd…”', '“In the beginning was the Word…”'], answer: 0, ref: 'Genesis 1:1' },
];

/** The date (YYYY-MM-DD) in Central time. */
export function centralDateKey(at: Date): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Chicago', year: 'numeric', month: '2-digit', day: '2-digit' }).format(at);
}

function daysSinceEpoch(dateKey: string): number {
  const [y, m, d] = dateKey.split('-').map(Number);
  return Math.floor(Date.UTC(y, m - 1, d) / 86_400_000);
}

export function addDays(dateKey: string, days: number): string {
  const t = (daysSinceEpoch(dateKey) + days) * 86_400_000;
  return new Date(t).toISOString().slice(0, 10);
}

/** The Monday that starts [dateKey]'s week: the leaderboard's id. */
export function weekKey(dateKey: string): string {
  const day = new Date(daysSinceEpoch(dateKey) * 86_400_000).getUTCDay(); // 0 = Sunday
  return addDays(dateKey, -((day + 6) % 7));
}

/** Every question once before any repeats, in the bank's order. */
export function questionFor(dateKey: string, bank: QuizQuestion[] = QUESTIONS): QuizQuestion {
  const i = ((daysSinceEpoch(dateKey) % bank.length) + bank.length) % bank.length;
  return bank[i];
}

/** Start and end of a Central-time day, as instants. */
export function centralDayBounds(dateKey: string): { opens: Date; closes: Date } {
  // Find the UTC instant where the Central date turns to dateKey (DST-safe: try hours 4–7 UTC).
  const base = daysSinceEpoch(dateKey) * 86_400_000;
  const startOf = (key: string, b: number) => {
    for (let h = 0; h < 12; h++) {
      const t = new Date(b + h * 3_600_000);
      if (centralDateKey(t) === key) return t;
    }
    return new Date(b + 6 * 3_600_000);
  };
  return { opens: startOf(dateKey, base), closes: startOf(addDays(dateKey, 1), base + 86_400_000) };
}

/** 10 points for a right answer, plus 2 for each day of the streak before today (up to 10). */
export function points(correct: boolean, streak: number): number {
  if (!correct) return 0;
  return 10 + 2 * Math.min(Math.max(streak - 1, 0), 5);
}

/** Days in a row played, given the last day played and its streak. */
export function nextStreak(lastDate: string | undefined, lastStreak: number, today: string): number {
  if (lastDate === today) return lastStreak;
  if (lastDate && addDays(lastDate, 1) === today) return lastStreak + 1;
  return 1;
}
