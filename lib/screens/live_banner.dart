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

/// Live service hero for Watch.
///
/// Says "Live now" only while the church is actually streaming on YouTube (Sunday
/// service or a special event). Otherwise it shows the next scheduled stream,
/// or the next Sunday service.
class LiveBanner extends StatelessWidget {
  const LiveBanner({super.key, required this.streams, this.height = 208});
  final List<LiveStream> streams;
  final double height;

  @override
  Widget build(BuildContext context) {
    final live = streams.where((s) => s.isLive).firstOrNull;
    if (live != null) {
      return _Hero(
        image: live.image,
        height: height,
        live: true,
        overline: live.description.isNotEmpty ? live.description : 'Streaming now',
        title: live.title,
        label: 'Watch live: ${live.title}',
        onTap: () => playVideo(context,
            youtubeId: live.youtubeId, url: live.youtubeUrl, title: live.title, subtitle: live.description, isLive: true),
      );
    }

    final upcoming = streams.where((s) => s.scheduledStart != null).firstOrNull;
    if (upcoming != null) {
      return _Hero(
        image: upcoming.image,
        height: height,
        overline: 'Next stream · ${_when(upcoming.scheduledStart!.toLocal())}',
        title: upcoming.title,
        label: '${upcoming.title}, next stream ${_when(upcoming.scheduledStart!.toLocal())}',
        onTap: () => playVideo(context,
            youtubeId: upcoming.youtubeId, url: upcoming.youtubeUrl, title: upcoming.title, subtitle: 'Upcoming'),
      );
    }

    final next = nextSundayService();
    return _Hero(
      image: 'assets/church/worship.jpg',
      height: height,
      overline: 'Next stream · ${_when(next)} CT',
      title: 'Sunday Worship Service',
      label: 'Sunday Worship Service, next stream ${_when(next)}',
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.image,
      required this.height,
      required this.overline,
      required this.title,
      required this.label,
      required this.onTap,
      this.live = false});
  final String image;
  final double height;
  final String overline;
  final String title;
  final String label;
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            BethelImage(image),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x26152824), Color(0xD1152824)],
                ),
              ),
            ),
            if (live)
              const Positioned(
                left: 20,
                top: 20,
                child: Row(children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle),
                    child: SizedBox(width: 8, height: 8),
                  ),
                  SizedBox(width: 8),
                  Text('Live now',
                      style: TextStyle(color: BethelColors.ivory, fontSize: BethelType.caption, fontWeight: FontWeight.w500)),
                ]),
              ),
            Positioned(
              left: 20,
              right: 88,
              bottom: 20,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(overline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: BethelColors.stone, fontSize: BethelType.caption)),
                const SizedBox(height: 4),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: BethelFonts.display, fontSize: BethelType.title, height: 1.25, color: BethelColors.ivory)),
              ]),
            ),
            const Positioned(right: 16, bottom: 16, child: PlayCircle()),
          ]),
        ),
      ),
    );
  }
}

/// Ivory play button used on video heroes.
class PlayCircle extends StatelessWidget {
  const PlayCircle({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: BethelColors.ivory, shape: BoxShape.circle),
        child: Icon(Icons.play_arrow_rounded, color: BethelColors.forest, size: size * 0.5),
      );
}
