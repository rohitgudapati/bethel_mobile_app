/// One question for "Did you know?" on Home: three choices, the answer, and the fact behind it.
class BibleFact {
  const BibleFact(this.question, this.choices, this.answer, this.fact);
  final String question;
  final List<String> choices;
  final int answer;
  final String fact;
}

/// Checked against the KJV. One a day, in order.
const bibleFacts = <BibleFact>[
  BibleFact('Which book of the Bible never mentions God by name?', ['Ruth', 'Esther', 'Jonah'], 1,
      'Esther. God’s name never appears, yet His care runs through the whole story.'),
  BibleFact('What is the shortest chapter in the Bible?', ['Psalm 23', 'Psalm 117', 'John 11'], 1,
      'Psalm 117, just two verses: “O praise the LORD, all ye nations.”'),
  BibleFact('What is the longest chapter in the Bible?', ['Genesis 1', 'Isaiah 53', 'Psalm 119'], 2,
      'Psalm 119, with 176 verses, almost all about God’s word.'),
  BibleFact('Who lived the longest, according to Genesis?', ['Adam', 'Methuselah', 'Noah'], 1,
      'Methuselah lived 969 years (Genesis 5:27).'),
  BibleFact('How many books are in the Bible?', ['59', '66', '72'], 1, '66: 39 in the Old Testament and 27 in the New.'),
  BibleFact('In which language was most of the New Testament first written?', ['Hebrew', 'Latin', 'Greek'], 2,
      'Greek, the common language of the eastern Roman Empire.'),
  BibleFact('What was Jesus’ first miracle in the Gospel of John?', ['Calming the storm', 'Water into wine', 'Feeding 5,000'], 1,
      'Turning water into wine at a wedding in Cana (John 2:11).'),
  BibleFact('For how many days and nights did it rain in the flood?', ['7', '40', '150'], 1,
      'Forty days and forty nights (Genesis 7:12).'),
  BibleFact('Which apostle denied Jesus three times?', ['Peter', 'Thomas', 'Judas'], 0,
      'Peter, before the rooster crowed. Jesus later restored him three times (John 21).'),
  BibleFact('On which mountain did Moses receive the Ten Commandments?', ['Mount Carmel', 'Mount Sinai', 'Mount Zion'], 1,
      'Mount Sinai (Exodus 19–20).'),
  BibleFact('With five loaves and two fishes, about how many men did Jesus feed?', ['3,000', '4,000', '5,000'], 2,
      'About five thousand men, besides women and children (Matthew 14:21).'),
  BibleFact('Who wrote the most psalms?', ['Solomon', 'Asaph', 'David'], 2, 'David. Seventy-three psalms carry his name.'),
  BibleFact('What was the apostle Paul’s name before?', ['Saul', 'Silas', 'Simon'], 0, 'Saul, who also is called Paul (Acts 13:9).'),
  BibleFact('Which book has the most chapters?', ['Isaiah', 'Psalms', 'Jeremiah'], 1, 'Psalms, with 150.'),
  BibleFact('Who interpreted Pharaoh’s dreams of cows and corn?', ['Daniel', 'Joseph', 'Moses'], 1,
      'Joseph: seven years of plenty, then seven of famine (Genesis 41).'),
  BibleFact('Which chapter is known as the love chapter?', ['John 3', '1 Corinthians 13', 'Romans 8'], 1,
      '1 Corinthians 13: “And now abideth faith, hope, charity, these three.”'),
  BibleFact('How many sons did Jacob have?', ['Ten', 'Twelve', 'Fourteen'], 1, 'Twelve, the fathers of the tribes of Israel.'),
  BibleFact('In which river was Jesus baptised?', ['Jordan', 'Nile', 'Euphrates'], 0, 'The Jordan, by John the Baptist (Matthew 3).'),
  BibleFact('Who was thrown into the den of lions?', ['Daniel', 'Elijah', 'Jeremiah'], 0,
      'Daniel. God shut the lions’ mouths (Daniel 6:22).'),
  BibleFact('What did God create on the first day?', ['The sun', 'Light', 'The sea'], 1,
      'Light. “Let there be light: and there was light” (Genesis 1:3).'),
  BibleFact('Where is the fruit of the Spirit listed?', ['Galatians 5', 'Ephesians 6', 'James 1'], 0,
      'Galatians 5:22–23: love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance.'),
  BibleFact('What is the shortest verse in the King James Bible?', ['John 11:35', 'Genesis 1:1', 'Psalm 23:1'], 0,
      'John 11:35, “Jesus wept.”'),
  BibleFact('In which town was Jesus born?', ['Nazareth', 'Bethlehem', 'Jerusalem'], 1,
      'Bethlehem of Judaea, as Micah foretold (Matthew 2:1, Micah 5:2).'),
  BibleFact('Which gospel is not one of the three “synoptic” gospels?', ['Mark', 'Luke', 'John'], 2,
      'John. Matthew, Mark and Luke tell the story in a similar way; John writes differently.'),
  BibleFact('Who was swallowed by a great fish?', ['Jonah', 'Job', 'Hosea'], 0, 'Jonah, for three days and three nights (Jonah 1:17).'),
];
