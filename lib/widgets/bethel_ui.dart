import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

/// Building blocks from the redesign wireframes. Screens compose these instead of styling inline,
/// so spacing, colours and type stay identical everywhere.

bool reduceMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

/// The short brass rule taken from the logo lockup. Sits before section titles.
class BrassRule extends StatelessWidget {
  const BrassRule({super.key, this.width = 20});
  final double width;

  @override
  Widget build(BuildContext context) => Container(width: width, height: 1, color: BethelColors.brass);
}

/// Section title: brass rule, serif title, optional action on the right ("All events").
class BethelSectionTitle extends StatelessWidget {
  const BethelSectionTitle(this.title, {super.key, this.action, this.onAction, this.padding = EdgeInsets.zero});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(children: [
        const BrassRule(),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: t.textTheme.titleLarge)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
            child: Text(action!),
          ),
      ]),
    );
  }
}

/// Song numbers set like a church hymn board: serif number on a stone plaque.
class HymnPlaque extends StatelessWidget {
  const HymnPlaque(this.number, {super.key, this.large = false});

  final String number;

  /// The song page uses the large plaque with "No." above the number.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final tk = BethelTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: large ? 64 : 44,
      height: large ? 72 : 44,
      decoration: BoxDecoration(
        color: tk.raised,
        border: Border.all(color: tk.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: large
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              Text('No.', style: TextStyle(fontSize: BethelType.caption, color: cs.onSurfaceVariant, height: 1.1)),
              Text(number,
                  style: TextStyle(
                      fontFamily: BethelFonts.display, fontSize: BethelType.display, height: 1.1, color: cs.onSurface)),
            ])
          : Text(number,
              style: TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.title, color: cs.onSurface)),
    );
  }
}

/// Weekday over day number ("Fri / 27"), used in event rows.
class DatePlaque extends StatelessWidget {
  const DatePlaque(this.date, {super.key});
  final DateTime date;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final tk = BethelTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: tk.raised,
        border: Border.all(color: tk.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_days[date.weekday - 1],
            style: TextStyle(fontSize: BethelType.caption, color: cs.onSurfaceVariant, height: 1.1)),
        Text('${date.day}',
            style: TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.title, height: 1.1, color: cs.onSurface)),
      ]),
    );
  }
}

/// Scales slightly while pressed (0.97, 120 ms). The house press feedback for cards and custom buttons.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.haptic = false, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down && !still ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A list row with a hairline below: optional leading (plaque, icon), title, subtitle, trailing (chevron by default).
class HairlineRow extends StatelessWidget {
  const HairlineRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.serifTitle = false,
    this.titleStyle,
    this.showChevron = true,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Serif titles for sermons and reading-plan days.
  final bool serifTitle;
  final TextStyle? titleStyle;
  final bool showChevron;

  /// 44 px settings rows (More screen) instead of 64 px content rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final style = titleStyle ?? (serifTitle ? t.textTheme.titleMedium : t.textTheme.titleSmall);
    final trail = trailing ??
        (showChevron && onTap != null ? Icon(Icons.chevron_right_rounded, size: 20, color: t.colorScheme.onSurfaceVariant) : null);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        highlightColor: tk.raised,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 44 : 64),
          padding: EdgeInsets.symmetric(vertical: compact ? 0 : 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
          child: Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: style),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: t.textTheme.bodySmall),
                ],
              ]),
            ),
            if (trail != null) ...[const SizedBox(width: 12), trail],
          ]),
        ),
      ),
    );
  }
}

/// Muted 24 px icon column for rows (keeps labels aligned).
class RowIcon extends StatelessWidget {
  const RowIcon(this.icon, {super.key, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 24, child: Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant));
}

/// One row of text tabs with a 2 px underline under the selected one. Scrolls sideways if it doesn't fit.
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({super.key, required this.labels, required this.selected, required this.onSelected, this.gap = 24});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Semantics(
              selected: i == selected,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: i == selected ? t.colorScheme.primary : Colors.transparent, width: 2)),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                        fontSize: BethelType.body,
                        fontWeight: i == selected ? FontWeight.w500 : FontWeight.w400,
                        color: i == selected ? t.colorScheme.onSurface : t.colorScheme.onSurfaceVariant,
                      )),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Input on a white (dark: lighter) tile with a soft shadow and no border; focus adds a 2 px Forest ring.
class TileField extends StatelessWidget {
  const TileField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.errorText,
    this.trailing,
    this.autofocus = false,
    this.onSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.onChanged,
    this.focusNode,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? hint;

  /// Read by screen readers when there's no visible label.
  final String? label;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? errorText;
  final Widget? trailing;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final tk = BethelTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: tk.tileShadow),
        child: Semantics(
          // The hint is read too, so skip a label that only repeats it ("Your name, Your name").
          label: label == hint ? null : label,
          child: TextField(
          controller: controller,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          obscureText: obscureText,
          autofocus: autofocus,
          maxLines: obscureText ? 1 : maxLines,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: BethelType.title),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: trailing,
            enabledBorder: errorText == null
                ? null
                : OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tk.error, width: 2)),
            focusedBorder: errorText == null
                ? null
                : OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tk.error, width: 2)),
          ),
        ),
        ),
      ),
      if (errorText != null) ...[
        const SizedBox(height: 8),
        Text(errorText!, textAlign: TextAlign.center, style: TextStyle(fontSize: BethelType.body, color: tk.error)),
      ],
    ]);
  }
}

/// Shows a toast above the tab bar: brass icon, Ivory text on Ink.
void showBethelToast(BuildContext context, String message, {IconData icon = Icons.check_rounded}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, size: 20, color: BethelColors.brassLight),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
      duration: const Duration(seconds: 3),
    ));
}

/// Opens a bottom sheet with the house padding (24 sides, 44 bottom) that lifts above the keyboard.
Future<T?> showBethelSheet<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(top: false, child: builder(ctx)),
    ),
  );
}

/// Empty, error and "not signed in" states: icon in a circle, serif headline, one line, optional action.
class BethelEmptyState extends StatelessWidget {
  const BethelEmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: t.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: t.textTheme.titleLarge),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(message, textAlign: TextAlign.center, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ]),
      ),
    );
  }
}

/// Grey placeholder block for loading states.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: BethelTokens.of(context).raised, borderRadius: BorderRadius.circular(radius)),
      );
}

/// Screen title used at the top of each tab (Songs, Watch, Prayer, More).
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.displaySmall)),
        if (trailing != null) trailing!,
      ]);
}
