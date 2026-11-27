import 'catalog.dart';

/// Draft topics for Songs of Zion, read from the reference app's index (songs 1–436).
/// Confirm against the printed book. Once Firebase is set up these come from the server
/// and are edited in the admin site; this list is only the fallback.
const draftTopics = <String, List<SongTopic>>{
  'Songs of Zion': [
    SongTopic(en: 'Psalms', te: 'కీర్తనలు', from: 1, to: 75, icon: 'book'),
    SongTopic(en: 'Worship', te: 'ఆరాధన', from: 76, to: 201, icon: 'worship'),
    SongTopic(en: 'Praise', te: 'స్తుతి', from: 202, to: 229, icon: 'music'),
    SongTopic(en: 'Thanksgiving', te: 'కృతజ్ఞతార్పణ', from: 230, to: 252, icon: 'thanks'),
    SongTopic(en: 'New Year', te: 'క్రొత్త సంవత్సరము', from: 253, to: 264, icon: 'calendar'),
    SongTopic(en: 'Birth of Christ', te: 'క్రీస్తు జన్మము', from: 265, to: 271, icon: 'star'),
    SongTopic(en: 'Suffering and death', te: 'శ్రమలు, మరణము', from: 272, to: 289, icon: 'cross'),
    SongTopic(en: 'Resurrection', te: 'పునరుత్థానము', from: 290, to: 295, icon: 'sun'),
    SongTopic(en: 'Second coming', te: 'రెండవ రాకడ', from: 296, to: 327, icon: 'cloud'),
    SongTopic(en: 'Gospel proclamation', te: 'సువార్త ప్రకటన', from: 328, to: 381, icon: 'campaign'),
    SongTopic(en: 'Gospel invitation', te: 'సువార్త ఆహ్వానము', from: 382, to: 419, icon: 'invite'),
    SongTopic(en: 'Gospel confession', te: 'సువార్త ఒప్పుకోలు', from: 420, to: 436, icon: 'heart'),
  ],
};
