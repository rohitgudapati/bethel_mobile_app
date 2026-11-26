import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme.dart';

/// Shows an asset (`assets/...`) or a network image with a soft placeholder.
class BethelImage extends StatelessWidget {
  const BethelImage(this.source,
      {super.key,
      this.fit = BoxFit.cover,
      this.radius = 0,
      this.width,
      this.height,
      this.alignment = Alignment.center});

  final String source;
  final BoxFit fit;
  final double radius;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    final Widget img = source.isEmpty
        ? placeholder
        : source.startsWith('http')
            ? Image.network(source,
                fit: fit, width: width, height: height, alignment: alignment, errorBuilder: (_, __, ___) => placeholder)
            : Image.asset(source,
                fit: fit,
                width: width,
                height: height,
                alignment: alignment,
                errorBuilder: (_, __, ___) => placeholder);
    return radius == 0 ? img : ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 28, 12, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: t.textTheme.titleLarge)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: t.colorScheme.primary),
              child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

/// Rounded label used for categories, "LIVE", dates etc.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.textColor, this.icon});

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? BethelColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color ?? BethelColors.brassSoft, borderRadius: BorderRadius.circular(40)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.2)),
      ]),
    );
  }
}

class LivePill extends StatelessWidget {
  const LivePill({super.key});
  @override
  Widget build(BuildContext context) =>
      const Pill('LIVE', color: BethelColors.rose, textColor: Colors.white, icon: Icons.circle);
}

/// Loads a future once and shows a spinner / error / data.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder, this.sliver = false});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final bool sliver;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        Widget child;
        if (snap.hasData) return widget.builder(context, snap.data as T);
        if (snap.hasError) {
          child = Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Couldn\'t load this right now.\n${snap.error}', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(onPressed: () => setState(() => _future = widget.load()), child: const Text('Try again')),
            ]),
          );
        } else {
          child = const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4))),
          );
        }
        return widget.sliver ? SliverToBoxAdapter(child: child) : child;
      },
    );
  }
}

Future<void> openLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link not available yet.')));
    }
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
String fmtShort(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
String fmtMonth(DateTime d) => _months[d.month - 1].toUpperCase();

String compactCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
  return '$n';
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return fmtShort(d);
}

/// Image card with gradient and white text overlay (used for heroes/sermons).
class OverlayCard extends StatelessWidget {
  const OverlayCard({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    this.top,
    this.height = 200,
    this.onTap,
    this.trailing,
  });

  final String image;
  final String title;
  final String? subtitle;
  final Widget? top;
  final double height;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.black,
          child: InkWell(
            onTap: onTap,
            child: Stack(fit: StackFit.expand, children: [
              BethelImage(image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x10000000), Color(0x22000000), Color(0xCC0F1520)],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (top != null) top!,
                  const Spacer(),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, height: 1.25)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13)),
                        ],
                      ]),
                    ),
                    if (trailing != null) trailing!,
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class PlayBadge extends StatelessWidget {
  const PlayBadge({super.key, this.size = 46});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(Icons.play_arrow_rounded, color: BethelColors.forest, size: size * 0.6),
      );
}
