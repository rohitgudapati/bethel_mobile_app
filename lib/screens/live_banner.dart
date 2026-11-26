import 'package:flutter/material.dart';

import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'events_screen.dart';
import 'video_screen.dart';

/// The Sunday service: every Sunday at 3:00 PM (Central time).
DateTime nextSundayService([DateTime? from]) {
  final now = from ?? DateTime.now();
  var d = DateTime(now.year, now.month, now.day, AppConfig.sundayServiceHour);
  while (d.weekday != DateTime.sunday || !d.isAfter(now.subtract(const Duration(hours: 2)))) {
    d = DateTime(d.year, d.month, d.day + 1, AppConfig.sundayServiceHour);
  }
  return d;
}

String _when(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final today = DateTime.now();
  final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
  return '${isToday ? 'Today' : fmtShort(d)} · $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// Live service banner for Home and Watch.
///
/// Shows LIVE only while the church is actually streaming on YouTube (Sunday
/// service or a special event). Otherwise it shows the next scheduled stream,
/// or the next Sunday service.
class LiveBanner extends StatelessWidget {
  const LiveBanner({super.key, required this.streams, this.height = 210});
  final List<LiveStream> streams;
  final double height;

  @override
  Widget build(BuildContext context) {
    final live = streams.where((s) => s.isLive).firstOrNull;
    if (live != null) {
      return OverlayCard(
        image: live.image,
        height: height,
        title: live.title,
        subtitle: live.description,
        top: const LivePill(),
        trailing: const PlayBadge(size: 52),
        onTap: () => playVideo(context,
            youtubeId: live.youtubeId,
            url: live.youtubeUrl,
            title: live.title,
            subtitle: live.description,
            isLive: true),
      );
    }

    final upcoming = streams.where((s) => s.scheduledStart != null).firstOrNull;
    if (upcoming != null) {
      return OverlayCard(
        image: upcoming.image,
        height: height,
        title: upcoming.title,
        subtitle: 'Starts ${_when(upcoming.scheduledStart!.toLocal())}',
        top: const Pill('UPCOMING', icon: Icons.schedule_rounded),
        trailing: const _Badge(icon: Icons.notifications_active_outlined),
        onTap: () => playVideo(context,
            youtubeId: upcoming.youtubeId, url: upcoming.youtubeUrl, title: upcoming.title, subtitle: 'Upcoming'),
      );
    }

    final next = nextSundayService();
    return OverlayCard(
      image: 'assets/church/worship.jpg',
      height: height,
      title: 'Sunday Worship Service',
      subtitle: '${_when(next)} CT',
      top: const Pill('NEXT SERVICE', icon: Icons.event_rounded),
      trailing: const _Badge(icon: Icons.calendar_month_rounded),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: BethelColors.forest, size: 24),
      );
}
