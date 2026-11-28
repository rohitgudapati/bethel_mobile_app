import 'package:bethelprayerhouse/home/home_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Sunday Dec 6, 2026; service at 3:00 PM.
  DateTime sun(int h, [int m = 0]) => DateTime(2026, 12, 6, h, m);
  final service = sun(15);
  List<HomeSection> order(HomeSignals s) => orderHome(s);

  test('Sunday 2:40 PM: starting soon goes above the verse, then the final day', () {
    final o = order(HomeSignals(now: sun(14, 40), nextStart: service, triviaTotal: 5, plan: PlanStatus.today));
    expect(o.take(5), [HomeSection.startingSoon, HomeSection.verse, HomeSection.finalDay, HomeSection.trivia, HomeSection.planToday]);
    expect(o, isNot(contains(HomeSection.leaderboard)), reason: 'on Sunday the leaderboard is the final-day card');
  });

  test('more than an hour before, no starting-soon card', () {
    expect(order(HomeSignals(now: sun(13, 30), nextStart: service)).first, HomeSection.verse);
  });

  test('Sunday 3:10 PM: live takes first place', () {
    final o = order(HomeSignals(now: sun(15, 10), live: true, nextStart: service, triviaTotal: 5));
    expect(o.first, HomeSection.live);
    expect(o, isNot(contains(HomeSection.startingSoon)));
    expect(o, isNot(contains(HomeSection.replay)));
  });

  test('Sunday 7 PM: the replay sits right under the verse', () {
    final o = order(HomeSignals(now: sun(19), lastStreamEnded: sun(17, 12), triviaTotal: 5, triviaDone: 2));
    expect(o.take(4), [HomeSection.verse, HomeSection.replay, HomeSection.finalDay, HomeSection.trivia]);
  });

  test('the replay disappears 24 hours after the stream ended', () {
    final o = order(HomeSignals(now: DateTime(2026, 12, 7, 17, 30), lastStreamEnded: sun(17, 12)));
    expect(o, isNot(contains(HomeSection.replay)));
  });

  test('Monday: last week’s winners under the verse, no weekly leaderboard further down', () {
    final o = order(HomeSignals(now: DateTime(2026, 12, 7, 7, 30), triviaTotal: 5, plan: PlanStatus.today));
    expect(o.take(4), [HomeSection.verse, HomeSection.lastWeekWinners, HomeSection.trivia, HomeSection.planToday]);
    expect(o, isNot(contains(HomeSection.leaderboard)));
  });

  test('ordinary weekday morning', () {
    final o = order(HomeSignals(now: DateTime(2026, 12, 9, 8), triviaTotal: 5, plan: PlanStatus.today));
    expect(o, [
      HomeSection.verse,
      HomeSection.trivia,
      HomeSection.planToday,
      HomeSection.thisWeek,
      HomeSection.playlists,
      HomeSection.leaderboard,
    ]);
  });

  test('weekday evening, everything done: done row at the bottom', () {
    final o = order(HomeSignals(now: DateTime(2026, 12, 9, 21), triviaTotal: 5, triviaDone: 5, plan: PlanStatus.done));
    expect(o, [HomeSection.verse, HomeSection.thisWeek, HomeSection.playlists, HomeSection.leaderboard, HomeSection.doneToday]);
  });

  test('event today and behind on reading', () {
    final o = order(HomeSignals(now: DateTime(2026, 12, 5, 11), eventToday: true, triviaTotal: 5, plan: PlanStatus.behind));
    expect(o.take(4), [HomeSection.verse, HomeSection.eventToday, HomeSection.trivia, HomeSection.planBehind]);
  });

  test('guest: trivia stays (sign in to play), no final day or done row, start a plan last', () {
    final o = order(HomeSignals(now: sun(19), guest: true, triviaTotal: 5));
    expect(o, isNot(contains(HomeSection.finalDay)));
    expect(o, contains(HomeSection.trivia));
    expect(o, contains(HomeSection.leaderboard));
    expect(o.last, HomeSection.planStart);
  });

  test('a plan that starts later sits with the browse sections', () {
    final o = order(HomeSignals(now: DateTime(2026, 12, 9, 8), plan: PlanStatus.waiting));
    expect(o.indexOf(HomeSection.planToday), greaterThan(o.indexOf(HomeSection.playlists)));
  });

  test('no trivia published: no trivia card', () {
    expect(order(HomeSignals(now: DateTime(2026, 12, 9, 8))), isNot(contains(HomeSection.trivia)));
  });
}
