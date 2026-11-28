/**
 * The daily Bible question: one question a day for everyone, answered once, checked on
 * the server (the answers live only here), scored into a weekly leaderboard that starts
 * over every Monday (Central time).
 */

export interface QuizQuestion {
  q: string;
  /** 'hard' or 'medium'. The daily five lean hard. */
  level?: 'hard' | 'medium';
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

/** Harder questions: each answer is stated in the verse given. */
export const HARD_QUESTIONS: QuizQuestion[] = [
  { q: 'Which judge of Israel was left-handed?', choices: ['Gideon', 'Ehud', 'Jephthah', 'Othniel'], answer: 1, ref: 'Judges 3:15', level: 'hard' },
  { q: 'How many years did Solomon spend building the temple?', choices: ['Seven', 'Thirteen', 'Twenty', 'Forty'], answer: 0, ref: '1 Kings 6:38', level: 'hard' },
  { q: 'How many years did Solomon spend building his own house?', choices: ['Seven', 'Ten', 'Thirteen', 'Twenty'], answer: 2, ref: '1 Kings 7:1', level: 'hard' },
  { q: 'How old was Methuselah when he died?', choices: ['930 years', '950 years', '969 years', '912 years'], answer: 2, ref: 'Genesis 5:27', level: 'hard' },
  { q: 'Who was the father of Methuselah?', choices: ['Lamech', 'Enoch', 'Jared', 'Seth'], answer: 1, ref: 'Genesis 5:21', level: 'hard' },
  { q: 'What was the name of Moses’ wife?', choices: ['Zipporah', 'Miriam', 'Jochebed', 'Keturah'], answer: 0, ref: 'Exodus 2:21', level: 'hard' },
  { q: 'Which prophet was told to marry Gomer?', choices: ['Amos', 'Micah', 'Hosea', 'Joel'], answer: 2, ref: 'Hosea 1:2–3', level: 'hard' },
  { q: 'How old was Josiah when he began to reign?', choices: ['Eight', 'Twelve', 'Sixteen', 'Twenty-five'], answer: 0, ref: '2 Kings 22:1', level: 'hard' },
  { q: 'What name did the prince of the eunuchs give Daniel?', choices: ['Shadrach', 'Abednego', 'Belteshazzar', 'Meshach'], answer: 2, ref: 'Daniel 1:7', level: 'hard' },
  { q: 'On which island was John when he received the Revelation?', choices: ['Crete', 'Cyprus', 'Malta', 'Patmos'], answer: 3, ref: 'Revelation 1:9', level: 'hard' },
  { q: 'What was the name of the high priest’s servant whose ear Peter cut off?', choices: ['Malchus', 'Rhoda', 'Annas', 'Alexander'], answer: 0, ref: 'John 18:10', level: 'hard' },
  { q: 'The people of which city “searched the scriptures daily” after hearing Paul?', choices: ['Thessalonica', 'Berea', 'Corinth', 'Philippi'], answer: 1, ref: 'Acts 17:10–11', level: 'hard' },
  { q: 'Which young man fell from a third-floor window while Paul was preaching?', choices: ['Tychicus', 'Trophimus', 'Eutychus', 'Erastus'], answer: 2, ref: 'Acts 20:9', level: 'hard' },
  { q: 'Which couple worked with Paul as tentmakers in Corinth?', choices: ['Ananias and Sapphira', 'Aquila and Priscilla', 'Andronicus and Junia', 'Philemon and Apphia'], answer: 1, ref: 'Acts 18:2–3', level: 'hard' },
  { q: 'How many men did Gideon keep to fight the Midianites?', choices: ['10,000', '1,000', '300', '70'], answer: 2, ref: 'Judges 7:7', level: 'hard' },
  { q: 'What did Samson find in the carcass of the lion he had killed?', choices: ['A swarm of bees and honey', 'A jawbone', 'A silver cup', 'Thirty garments'], answer: 0, ref: 'Judges 14:8', level: 'hard' },
  { q: 'Who was Abraham’s father?', choices: ['Nahor', 'Haran', 'Terah', 'Serug'], answer: 2, ref: 'Genesis 11:26', level: 'hard' },
  { q: 'Who was chosen to replace Judas among the twelve?', choices: ['Barnabas', 'Matthias', 'Silas', 'Joseph Barsabas'], answer: 1, ref: 'Acts 1:23–26', level: 'hard' },
  { q: 'What was the name of Ruth and Boaz’s son?', choices: ['Jesse', 'Obed', 'Salmon', 'Perez'], answer: 1, ref: 'Ruth 4:13–17', level: 'hard' },
  { q: 'Which prophet was told to lie on his left side for 390 days?', choices: ['Jeremiah', 'Isaiah', 'Ezekiel', 'Daniel'], answer: 2, ref: 'Ezekiel 4:4–5', level: 'hard' },
  { q: 'Who was Jacob’s firstborn son?', choices: ['Judah', 'Reuben', 'Simeon', 'Levi'], answer: 1, ref: 'Genesis 35:23', level: 'hard' },
  { q: 'Which king of Salem brought out bread and wine to Abram?', choices: ['Abimelech', 'Melchizedek', 'Chedorlaomer', 'Bera'], answer: 1, ref: 'Genesis 14:18', level: 'hard' },
  { q: 'Which prophetess judged Israel under a palm tree?', choices: ['Huldah', 'Miriam', 'Deborah', 'Anna'], answer: 2, ref: 'Judges 4:4–5', level: 'hard' },
  { q: 'Who killed Sisera with a tent nail?', choices: ['Deborah', 'Jael', 'Rahab', 'Abigail'], answer: 1, ref: 'Judges 4:21', level: 'hard' },
  { q: 'Which king of Bashan had a bedstead of iron?', choices: ['Sihon', 'Og', 'Balak', 'Agag'], answer: 1, ref: 'Deuteronomy 3:11', level: 'hard' },
  { q: 'Which disciple was also called Didymus?', choices: ['Thomas', 'Bartholomew', 'Thaddaeus', 'James'], answer: 0, ref: 'John 11:16', level: 'hard' },
  { q: 'What name did Jesus give Simon, meaning “a stone”?', choices: ['Boanerges', 'Cephas', 'Barjona', 'Petra'], answer: 1, ref: 'John 1:42', level: 'hard' },
  { q: 'Who was made to carry Jesus’ cross?', choices: ['Joseph of Arimathaea', 'Simon of Cyrene', 'Nicodemus', 'Lazarus'], answer: 1, ref: 'Mark 15:21', level: 'hard' },
  { q: 'Who fell down dead after lying about the price of his land?', choices: ['Ananias', 'Simon the sorcerer', 'Elymas', 'Demas'], answer: 0, ref: 'Acts 5:1–5', level: 'hard' },
  { q: 'Who baptized the Ethiopian eunuch?', choices: ['Peter', 'Paul', 'Philip', 'Barnabas'], answer: 2, ref: 'Acts 8:35–38', level: 'hard' },
  { q: 'Who was the captain of David’s army?', choices: ['Abner', 'Joab', 'Benaiah', 'Uriah'], answer: 1, ref: '2 Samuel 8:16', level: 'hard' },
  { q: 'How many times did Naaman dip himself in the Jordan?', choices: ['Three', 'Five', 'Seven', 'Twelve'], answer: 2, ref: '2 Kings 5:14', level: 'hard' },
  { q: 'Who was the father of John the Baptist?', choices: ['Zacharias', 'Simeon', 'Joseph', 'Zebedee'], answer: 0, ref: 'Luke 1:13', level: 'hard' },
  { q: 'Which prophet saw a valley full of dry bones?', choices: ['Isaiah', 'Ezekiel', 'Zechariah', 'Habakkuk'], answer: 1, ref: 'Ezekiel 37:1–2', level: 'hard' },
  { q: 'At which pool did Jesus heal a man who had been ill for thirty-eight years?', choices: ['Siloam', 'Bethesda', 'Gihon', 'Hezekiah'], answer: 1, ref: 'John 5:2–5', level: 'hard' },
  { q: 'What was the name of Timothy’s grandmother?', choices: ['Eunice', 'Lois', 'Lydia', 'Phebe'], answer: 1, ref: '2 Timothy 1:5', level: 'hard' },
  { q: 'How many souls were saved in Noah’s ark?', choices: ['Six', 'Eight', 'Ten', 'Twelve'], answer: 1, ref: '1 Peter 3:20', level: 'hard' },
  { q: 'Who healed Naaman’s leprosy by telling him to wash in the Jordan?', choices: ['Elijah', 'Elisha', 'Gehazi', 'Nathan'], answer: 1, ref: '2 Kings 5:10–14', level: 'hard' },
  { q: 'Which king saw a hand writing on the wall during a feast?', choices: ['Nebuchadnezzar', 'Darius', 'Belshazzar', 'Cyrus'], answer: 2, ref: 'Daniel 5:1–5', level: 'hard' },
  { q: 'What is the last book of the Old Testament?', choices: ['Zechariah', 'Malachi', 'Haggai', 'Nehemiah'], answer: 1, ref: 'Malachi 1:1', level: 'hard' },
  { q: 'In which town did Jesus turn water into wine?', choices: ['Nain', 'Cana', 'Bethany', 'Capernaum'], answer: 1, ref: 'John 2:1–11', level: 'hard' },
  { q: 'Which Pharisee came to Jesus by night?', choices: ['Gamaliel', 'Nicodemus', 'Simon', 'Jairus'], answer: 1, ref: 'John 3:1–2', level: 'hard' },
  { q: 'Who was the mother of the prophet Samuel?', choices: ['Peninnah', 'Hannah', 'Naomi', 'Elisabeth'], answer: 1, ref: '1 Samuel 1:20', level: 'hard' },
  { q: 'Which apostle was stoned and left for dead at Lystra?', choices: ['Barnabas', 'Paul', 'Silas', 'Peter'], answer: 1, ref: 'Acts 14:19', level: 'hard' },
  { q: 'How many years did the Israelites eat manna?', choices: ['Twelve', 'Twenty', 'Forty', 'Seventy'], answer: 2, ref: 'Exodus 16:35', level: 'hard' },
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

// ---------------------------------------------------------------- the bank

/** Five questions a day, the same for everyone. */
export const QUESTIONS_PER_DAY = 5;
/** Warn the admins when fewer unused questions than this remain (60 days of five). */
export const LOW_STOCK = 60 * QUESTIONS_PER_DAY;

/** Lower case, letters and digits only: two questions with the same text are the same question. */
export function normalize(text: string): string {
  return text.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, ' ').trim();
}

/** A stable id from the question's text, so the same question can never be stored twice. */
export function questionId(q: string): string {
  let h1 = 0x811c9dc5, h2 = 0x01000193;
  for (const ch of normalize(q)) {
    const c = ch.charCodeAt(0);
    h1 = Math.imul(h1 ^ c, 16777619) >>> 0;
    h2 = Math.imul(h2 + c, 2654435761) >>> 0;
  }
  return 'q' + h1.toString(36) + h2.toString(36);
}

/** Word-trigram similarity, 0–1. Above about 0.6 two questions ask the same thing in other words. */
export function similarity(a: string, b: string): number {
  const grams = (s: string) => {
    const w = normalize(s).split(' ');
    const out = new Set<string>();
    for (let i = 0; i + 2 < w.length + 2; i++) out.add(w.slice(i, i + 3).join(' '));
    return out;
  };
  const A = grams(a), B = grams(b);
  let both = 0;
  for (const g of A) if (B.has(g)) both++;
  return both / (A.size + B.size - both || 1);
}

/** Pairs of questions that look like the same question, for an admin to look at. */
export function nearDuplicates(bank: { id: string; q: string }[], threshold = 0.6): [string, string][] {
  const out: [string, string][] = [];
  for (let i = 0; i < bank.length; i++)
    for (let j = i + 1; j < bank.length; j++) if (similarity(bank[i].q, bank[j].q) >= threshold) out.push([bank[i].id, bank[j].id]);
  return out;
}

/** A small seeded random generator, so a day's pick can be repeated exactly. */
function seeded(seed: string) {
  let h = 2166136261;
  for (const ch of seed) h = Math.imul(h ^ ch.charCodeAt(0), 16777619) >>> 0;
  return () => {
    h = Math.imul(h ^ (h >>> 15), 2246822507) >>> 0;
    h = Math.imul(h ^ (h >>> 13), 3266489909) >>> 0;
    return ((h ^= h >>> 16) >>> 0) / 4294967296;
  };
}

/**
 * Picks the day's questions from the ones never used: mostly hard (3 of 5 when there are
 * enough), in a shuffled order. Returns fewer than [n] only when the bank runs dry.
 */
export function pickDaily(unused: { id: string; level?: string }[], date: string, n = QUESTIONS_PER_DAY): string[] {
  const rnd = seeded(date);
  const shuffle = <T,>(xs: T[]) => {
    const a = [...xs];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rnd() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  };
  const hard = shuffle(unused.filter((q) => q.level === 'hard'));
  const rest = shuffle(unused.filter((q) => q.level !== 'hard'));
  const wantHard = Math.min(hard.length, Math.ceil((n * 3) / 5));
  const picked = [...hard.slice(0, wantHard), ...rest.slice(0, n - wantHard)];
  if (picked.length < n) picked.push(...hard.slice(wantHard, wantHard + n - picked.length));
  return shuffle(picked.map((q) => q.id));
}

/** Every question the app ships with, with its id; the bank in Firestore is seeded from these. */
export function seedQuestions(): (QuizQuestion & { id: string })[] {
  return [...QUESTIONS.map((q) => ({ ...q, level: q.level ?? ('medium' as const) })), ...HARD_QUESTIONS].map((q) => ({ ...q, id: questionId(q.q) }));
}

/** Days in a row played, given the last day played and its streak. */
export function nextStreak(lastDate: string | undefined, lastStreak: number, today: string): number {
  if (lastDate === today) return lastStreak;
  if (lastDate && addDays(lastDate, 1) === today) return lastStreak + 1;
  return 1;
}
