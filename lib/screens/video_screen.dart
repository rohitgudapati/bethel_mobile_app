import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../app/theme.dart';
import '../widgets/common.dart';

/// Plays a YouTube video inside the app.
class InlineYouTube extends StatefulWidget {
  const InlineYouTube({super.key, required this.videoId, this.autoPlay = false, this.aspectRatio = 16 / 9});
  final String videoId;
  final bool autoPlay;
  final double aspectRatio;

  @override
  State<InlineYouTube> createState() => _InlineYouTubeState();
}

class _InlineYouTubeState extends State<InlineYouTube> {
  late final YoutubePlayerController _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: widget.autoPlay,
    params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true, playsInline: true),
  );
  StreamSubscription<YoutubePlayerValue>? _sub;
  YoutubeError _error = YoutubeError.none;

  @override
  void initState() {
    super.initState();
    // When YouTube refuses to play the video here (embedding turned off, private, region
    // or player errors), show a clear way to watch it on YouTube instead of a black box.
    _sub = _controller.stream.listen((v) {
      if (v.error != YoutubeError.none && v.error != _error && mounted) setState(() => _error = v.error);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }

  String get _reason => switch (_error) {
        YoutubeError.videoNotFound || YoutubeError.cannotFindVideo => 'This video is private or was removed.',
        YoutubeError.notEmbeddable || YoutubeError.sameAsNotEmbeddable => 'This video can only be played on YouTube.',
        _ => 'This video can’t play inside the app right now.',
      };

  @override
  Widget build(BuildContext context) {
    if (_error == YoutubeError.none) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: YoutubePlayer(controller: _controller, aspectRatio: widget.aspectRatio),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(fit: StackFit.expand, children: [
          Image.network('https://i.ytimg.com/vi/${widget.videoId}/hqdefault.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
          const ColoredBox(color: Color(0xC7000000)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_reason, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                onPressed: () => openLink(context, 'https://www.youtube.com/watch?v=${widget.videoId}'),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Watch on YouTube'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Full-screen page for a live stream, short, testimony or interview.
class VideoScreen extends StatelessWidget {
  const VideoScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.vertical = false,
    this.isLive = false,
  });

  final String videoId;
  final String title;
  final String subtitle;
  final String description;
  final bool vertical;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isLive ? 'Live' : 'Watch')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: vertical ? 360 : double.infinity),
            child: InlineYouTube(videoId: videoId, autoPlay: true, aspectRatio: vertical ? 9 / 16 : 16 / 9),
          ),
        ),
        const SizedBox(height: 16),
        if (isLive) const Align(alignment: Alignment.centerLeft, child: LivePill()),
        const SizedBox(height: 8),
        Text(title, style: t.textTheme.titleLarge),
        if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(description, style: const TextStyle(height: 1.6)),
        ],
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => openLink(context, 'https://www.youtube.com/watch?v=$videoId'),
          icon: const Icon(Icons.open_in_new_rounded, color: BethelColors.rose),
          label: const Text('Open in YouTube'),
        ),
      ]),
    );
  }
}

/// Opens a video in the app when we know its YouTube id, otherwise follows the link.
void playVideo(BuildContext context,
    {String? youtubeId,
    String? url,
    required String title,
    String subtitle = '',
    String description = '',
    bool vertical = false,
    bool isLive = false}) {
  if (youtubeId != null && youtubeId.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoScreen(
          videoId: youtubeId,
          title: title,
          subtitle: subtitle,
          description: description,
          vertical: vertical,
          isLive: isLive,
        ),
      ),
    );
  } else {
    openLink(context, url ?? '');
  }
}
