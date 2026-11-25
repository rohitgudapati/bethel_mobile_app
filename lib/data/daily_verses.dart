import 'models.dart';

/// A new verse every day, the same for everyone (King James Version, public domain).
///
/// Used whenever no verse has been published for today. When an admin publishes a
/// verse (text or image) for a date in Firebase, that one is shown instead.
const dailyVerses = <(String, String)>[
  (
    'John 3:16',
    'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.'
  ),
  ('Psalm 23:1', 'The LORD is my shepherd; I shall not want.'),
  ('Philippians 4:13', 'I can do all things through Christ which strengtheneth me.'),
  (
    'Isaiah 40:31',
    'But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.'
  ),
  (
    'Proverbs 3:5-6',
    'Trust in the LORD with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.'
  ),
  (
    'Jeremiah 29:11',
    'For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.'
  ),
  (
    'Romans 8:28',
    'And we know that all things work together for good to them that love God, to them who are the called according to his purpose.'
  ),
  (
    'Joshua 1:9',
    'Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.'
  ),
  ('Psalm 46:1', 'God is our refuge and strength, a very present help in trouble.'),
  ('Matthew 11:28', 'Come unto me, all ye that labour and are heavy laden, and I will give you rest.'),
  ('Psalm 119:105', 'Thy word is a lamp unto my feet, and a light unto my path.'),
  (
    'Romans 1:16',
    'For I am not ashamed of the gospel of Christ: for it is the power of God unto salvation to every one that believeth; to the Jew first, and also to the Greek.'
  ),
  (
    'Philippians 4:6',
    'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.'
  ),
  (
    'Isaiah 41:10',
    'Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.'
  ),
  (
    'Psalm 27:1',
    'The LORD is my light and my salvation; whom shall I fear? the LORD is the strength of my life; of whom shall I be afraid?'
  ),
  (
    'Lamentations 3:22-23',
    'It is of the LORD\'s mercies that we are not consumed, because his compassions fail not. They are new every morning: great is thy faithfulness.'
  ),
  (
    'Matthew 6:33',
    'But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.'
  ),
  (
    '2 Corinthians 5:17',
    'Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.'
  ),
  ('Psalm 118:24', 'This is the day which the LORD hath made; we will rejoice and be glad in it.'),
  (
    'John 14:6',
    'Jesus saith unto him, I am the way, the truth, and the life: no man cometh unto the Father, but by me.'
  ),
  (
    'John 8:12',
    'Then spake Jesus again unto them, saying, I am the light of the world: he that followeth me shall not walk in darkness, but shall have the light of life.'
  ),
  ('Psalm 34:8', 'O taste and see that the LORD is good: blessed is the man that trusteth in him.'),
  (
    'Romans 12:2',
    'And be not conformed to this world: but be ye transformed by the renewing of your mind, that ye may prove what is that good, and acceptable, and perfect, will of God.'
  ),
  (
    '1 John 1:9',
    'If we confess our sins, he is faithful and just to forgive us our sins, and to cleanse us from all unrighteousness.'
  ),
  ('Hebrews 11:1', 'Now faith is the substance of things hoped for, the evidence of things not seen.'),
  ('Psalm 37:4', 'Delight thyself also in the LORD; and he shall give thee the desires of thine heart.'),
  ('Proverbs 18:10', 'The name of the LORD is a strong tower: the righteous runneth into it, and is safe.'),
  ('Isaiah 26:3', 'Thou wilt keep him in perfect peace, whose mind is stayed on thee: because he trusteth in thee.'),
  (
    'John 16:33',
    'These things I have spoken unto you, that in me ye might have peace. In the world ye shall have tribulation: but be of good cheer; I have overcome the world.'
  ),
  (
    'Psalm 121:1-2',
    'I will lift up mine eyes unto the hills, from whence cometh my help. My help cometh from the LORD, which made heaven and earth.'
  ),
  (
    'Romans 15:13',
    'Now the God of hope fill you with all joy and peace in believing, that ye may abound in hope, through the power of the Holy Ghost.'
  ),
  (
    'Matthew 5:16',
    'Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.'
  ),
  ('2 Timothy 1:7', 'For God hath not given us the spirit of fear; but of power, and of love, and of a sound mind.'),
  ('Psalm 91:1', 'He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty.'),
  ('Mark 16:15', 'And he said unto them, Go ye into all the world, and preach the gospel to every creature.'),
  (
    'Micah 6:8',
    'He hath shewed thee, O man, what is good; and what doth the LORD require of thee, but to do justly, and to love mercy, and to walk humbly with thy God?'
  ),
  (
    'James 1:5',
    'If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him.'
  ),
  ('1 Peter 5:7', 'Casting all your care upon him; for he careth for you.'),
  (
    'Psalm 100:4',
    'Enter into his gates with thanksgiving, and into his courts with praise: be thankful unto him, and bless his name.'
  ),
  ('Nahum 1:7', 'The LORD is good, a strong hold in the day of trouble; and he knoweth them that trust in him.'),
  (
    'Psalm 55:22',
    'Cast thy burden upon the LORD, and he shall sustain thee: he shall never suffer the righteous to be moved.'
  ),
  (
    'Ephesians 2:8-9',
    'For by grace are ye saved through faith; and that not of yourselves: it is the gift of God: Not of works, lest any man should boast.'
  ),
  ('Hebrews 13:8', 'Jesus Christ the same yesterday, and to day, and for ever.'),
  (
    'Revelation 3:20',
    'Behold, I stand at the door, and knock: if any man hear my voice, and open the door, I will come in to him, and will sup with him, and he with me.'
  ),
];

/// Days since 1 Jan 2024 in local time, so the verse changes at local midnight.
int _dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024)).inDays;

/// The built-in verse for [date]. Its id is the date (yyyymmdd), so likes stay with the day.
DailyVerse builtInVerse(DateTime date) {
  final (ref, text) = dailyVerses[_dayNumber(date) % dailyVerses.length];
  return DailyVerse(
    id: date.year * 10000 + date.month * 100 + date.day,
    date: DateTime(date.year, date.month, date.day),
    text: text,
    reference: ref,
  );
}
