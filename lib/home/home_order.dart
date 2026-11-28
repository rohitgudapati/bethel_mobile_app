/// Decides the order of the Home screen from what is happening right now. Pure: give it
/// the signals, get the sections. Anything that doesn't apply is left out.
///
///   Always       greeting, then the daily verse on the first screen
///   Right now    live stream, or a service starting within the hour (above the verse)
///   Today        event today, today's service replay, last week's winners (Mon),
///                final day of the leaderboard (Sun), today's trivia, reading behind,
///                today's reading portion
///   Browse       this week, YouTube playlists, leaderboard (Tue–Sat), done for today,
///                start a reading plan
library;

enum HomeSection {
  live,
  startingSoon,
  verse,
  eventToday,
  replay,
  lastWeekWinners,
  finalDay,
  trivia,
  planBehind,
  planToday,
  thisWeek,
  playlists,
  leaderboard,
  doneToday,
  planStart,
}

/// none: no plan · behind: earlier days unread · today: today's portion unread ·
/// done: today's portion read · waiting: the plan starts later or has finished.
enum PlanStatus { none, behind, today, done, waiting }

class HomeSignals {
  const HomeSignals({
    required this.now,
    this.live = false,
    this.nextStart,
    this.eventToday = false,
    this.lastStreamEnded,
    this.triviaTotal = 0,
    this.triviaDone = 0,
    this.plan = PlanStatus.none,
    this.guest = false,
  });

  final DateTime now;
  final bool live;

  /// Start of the next service or scheduled stream, if known.
  final DateTime? nextStart;
  final bool eventToday;

  /// When the last live stream ended (for "Missed it? Watch today's service").
  final DateTime? lastStreamEnded;
  final int triviaTotal;
  final int triviaDone;
  final PlanStatus plan;
  final bool guest;

  bool get startingSoon {
    final s = nextStart;
    if (live || s == null) return false;
    final mins = s.difference(now).inMinutes;
    return mins >= 0 && mins <= 60;
  }

  bool get replay {
    final e = lastStreamEnded;
    if (live || e == null || e.isAfter(now)) return false;
    return now.difference(e) < const Duration(hours: 24);
  }

  bool get triviaFinished => triviaTotal > 0 && triviaDone >= triviaTotal;
}

List<HomeSection> orderHome(HomeSignals s) {
  final monday = s.now.weekday == DateTime.monday;
  final sunday = s.now.weekday == DateTime.sunday;
  return [
    // Right now
    if (s.live) HomeSection.live else if (s.startingSoon) HomeSection.startingSoon,
    HomeSection.verse,
    // Today, for you
    if (s.eventToday) HomeSection.eventToday,
    if (s.replay) HomeSection.replay,
    if (monday) HomeSection.lastWeekWinners,
    if (sunday && !s.guest) HomeSection.finalDay,
    if (s.triviaTotal > 0 && (s.guest || !s.triviaFinished)) HomeSection.trivia,
    if (s.plan == PlanStatus.behind) HomeSection.planBehind,
    if (s.plan == PlanStatus.today) HomeSection.planToday,
    // Browse
    HomeSection.thisWeek,
    HomeSection.playlists,
    if (s.plan == PlanStatus.waiting) HomeSection.planToday,
    if (!monday && !(sunday && !s.guest)) HomeSection.leaderboard,
    if (!s.guest && (s.triviaFinished || s.plan == PlanStatus.done)) HomeSection.doneToday,
    if (s.plan == PlanStatus.none) HomeSection.planStart,
  ];
}
