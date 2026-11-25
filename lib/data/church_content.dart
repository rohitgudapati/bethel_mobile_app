import 'models.dart';

/// Content from bethelprayerhouse.org, used by the demo build.
/// The Firebase backend seeds the same content (backend/seed/content.json).

const churchServices = <ChurchService>[
  ChurchService(
    id: 1,
    name: 'Sunday Worship Service',
    schedule: 'Every Sunday · 3:00 PM',
    description: 'A powerful worship experience that blends traditional Indian Christian heritage with contemporary '
        'praise: anointed preaching, heartfelt worship and warm fellowship, ending with a shared meal together. '
        'Sunday School for children runs at the same time.',
    image: 'assets/church/worship.jpg',
    icon: IconDataRef.worship,
  ),
  ChurchService(
    id: 2,
    name: 'Prayer Meeting',
    schedule: 'Every Friday · 7:30 PM',
    description: 'Dedicated time for corporate prayer and intercession for church and community needs, '
        'building spiritual strength together.',
    image: 'assets/pray.png',
  ),
  ChurchService(
    id: 3,
    name: 'Youth Meeting',
    schedule: 'Every Sunday · 6:30 PM',
    description:
        'Practical teaching, small group discussions and mentorship, and annual youth retreats and conferences.',
    image: 'assets/picture2.png',
    icon: IconDataRef.bible,
  ),
  ChurchService(
    id: 4,
    name: 'Sister\'s Meeting',
    schedule: 'Every other Sunday',
    description: 'Prayer gatherings and worship, mentoring and discipleship programs, and monthly fellowship events.',
    image: 'assets/picture1.png',
    icon: IconDataRef.family,
  ),
  ChurchService(
    id: 5,
    name: 'All Night Prayer',
    schedule: 'First Friday of the month',
    description:
        'Extended time in God\'s presence: corporate intercession and worship, fellowship and spiritual renewal.',
    image: 'assets/church/building.jpg',
    icon: IconDataRef.fasting,
  ),
];

const churchMinistries = <Ministry>[
  Ministry(
    id: 1,
    name: 'Children\'s Ministry',
    info: 'Age-appropriate Sunday School that runs alongside the Sunday worship service.',
    image: 'assets/ministriesimage.png',
    meets: 'Sundays · 3:00 PM',
  ),
  Ministry(
    id: 2,
    name: 'Youth Ministry',
    info: 'Practical teaching, small group discussions and mentorship, and annual youth retreats and conferences.',
    image: 'assets/picture2.png',
    meets: 'Sundays · 6:30 PM',
  ),
  Ministry(
    id: 3,
    name: 'Sister\'s Ministry',
    info: 'Prayer gatherings and worship, mentoring and discipleship programs, and monthly fellowship events.',
    image: 'assets/picture1.png',
    meets: 'Every other Sunday',
  ),
  Ministry(
    id: 4,
    name: 'Prayer Ministry',
    info: 'Corporate prayer every Friday and an all night prayer on the first Friday of each month.',
    image: 'assets/pray.png',
    meets: 'Fridays · 7:30 PM',
  ),
  Ministry(
    id: 5,
    name: 'Indian International Student Ministry',
    info: 'A family away from home for Indian international students across the Chicago area, including UIC, IIT, '
        'Lewis University, DePaul, NIU and North Central College. Fellowship and Indian festivals, academic and career '
        'guidance, airport pickups, help with housing and transportation, home-cooked Indian meals, and worship in a '
        'culturally familiar setting.',
    image: 'assets/master4.png',
    meets: 'Join us on Sundays',
  ),
];

const churchElders = <Elder>[
  Elder(
    id: 1,
    name: 'Bro. Moses Polugari',
    role: 'Elder',
    bio:
        'Bro. Moses leads with a deep commitment to the apostles\' teaching. His servant heart ensures that God\'s Word '
        'is faithfully proclaimed, guiding our church in sound doctrine and spiritual truth with passion and dedication.',
    image: 'assets/church/elder_moses.jpg',
    phone: '(818) 610-9650',
  ),
  Elder(
    id: 2,
    name: 'Bro. Vinod Somepalli',
    role: 'Elder',
    bio: 'Bro. Vinod exemplifies compassionate care, dedicating himself to nurturing the church family. He shepherds '
        'with a thoughtful and prayerful approach, ensuring every member feels supported and cherished in their walk '
        'with Christ.',
    image: 'assets/church/elder_vinod.jpg',
    phone: '(630) 854-7335',
  ),
];

const eldersIntro = 'Bethel Prayer House is lovingly guided by elders who serve with wisdom and humility. These '
    'dedicated leaders are called to shepherd the congregation, embodying servant leadership as they teach God\'s Word '
    'and provide spiritual care for our church family.';
