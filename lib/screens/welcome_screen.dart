import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_auth/smart_auth.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

/// Very dark forest used to shade the sanctuary photo.
const _shade = Color(0xFF0F1B19);

/// Curve for the card entrance (fast out, gentle settle).
const _rise = Cubic(0.2, 0.8, 0.2, 1);

/// Which sign-in method this phone used last; shown as "Last used" on the welcome screen.
class _LastMethod {
  static const _key = 'last_sign_in_method';
  static Future<String?> load() async => (await SharedPreferences.getInstance()).getString(_key);
  static Future<void> save(String method) async => (await SharedPreferences.getInstance()).setString(_key, method);
}

/// Welcome: sanctuary photo, logo and name, the promise, then one button per sign-in method.
/// Phone and email open a floating card over the blurred photo; Apple and Google use their own sheets.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _last;
  String? _busyProvider;

  @override
  void initState() {
    super.initState();
    _LastMethod.load().then((m) {
      if (mounted) setState(() => _last = m);
    });
  }

  void _open(_Step start, {required String method, UserProfile? pendingUser}) {
    final still = reduceMotion(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: still ? Duration.zero : const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => _AuthFlow(start: start, method: method, pendingUser: pendingUser),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: _rise);
        return Stack(fit: StackFit.expand, children: [
          // Blur and darken the welcome screen behind the card.
          AnimatedBuilder(
            animation: anim,
            builder: (_, __) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18 * anim.value, sigmaY: 18 * anim.value),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.35 * anim.value)),
            ),
          ),
          FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
              child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(curved), child: child),
            ),
          ),
        ]);
      },
    );
  }

  Future<void> _provider(String provider) async {
    if (_busyProvider != null) return;
    setState(() => _busyProvider = provider);
    final state = AppScope.read(context);
    try {
      final user = await state.repo.signInWithProvider(provider);
      if (!mounted) return;
      // Same moment as the phone flow: Verified, then Your name for new members, else Home.
      _open(_Step.verified, method: provider, pendingUser: user);
    } catch (e) {
      if (mounted) showBethelToast(context, '$e', icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    String? badge(String m) => _last == m ? 'Last used' : null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _shade,
        body: Stack(fit: StackFit.expand, children: [
          // Keep the lit window on the right in view on wide and narrow screens.
          const BethelImage('assets/church/sanctuary.jpg', fit: BoxFit.cover, alignment: Alignment(0.45, 0)),
          // Shade the top (logo) and bottom (buttons); leave the light rays in the middle.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _shade.withValues(alpha: 0.86),
                  _shade.withValues(alpha: 0.3),
                  _shade.withValues(alpha: 0.3),
                  _shade.withValues(alpha: 0.92),
                  _shade,
                ],
                stops: const [0, 0.3, 0.44, 0.66, 1],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                          child: Column(children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BethelColors.brass)),
                              child: const ClipOval(child: BethelImage('assets/church/logo.png', width: 64, height: 64)),
                            ),
                            const SizedBox(height: 16),
                            const Text('BETHEL\nPRAYER HOUSE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: BethelFonts.display,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 5,
                                  height: 1.35,
                                  color: BethelColors.ivory,
                                )),
                            const SizedBox(height: 8),
                            const Text('Naperville, Illinois',
                                style: TextStyle(
                                  fontFamily: BethelFonts.display,
                                  fontStyle: FontStyle.italic,
                                  fontSize: BethelType.body,
                                  color: BethelColors.stone,
                                )),
                            const Spacer(),
                            const SizedBox(height: 32),
                            const Text('Rooted in faith.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: BethelFonts.display, fontSize: 32, height: 1.15, color: BethelColors.ivory)),
                            const Text('United in Christ.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: BethelFonts.display,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 32,
                                  height: 1.15,
                                  color: BethelColors.brassLight,
                                )),
                            const SizedBox(height: 32),
                            _AuthButton(
                              icon: const Icon(Icons.phone_outlined, size: 18, color: BethelColors.ink),
                              label: 'Continue with phone',
                              badge: badge('phone'),
                              onTap: () => _open(_Step.phone, method: 'phone'),
                            ),
                            const SizedBox(height: 12),
                            _AuthButton(
                              icon: const Icon(Icons.apple, size: 20, color: BethelColors.ink),
                              label: 'Continue with Apple',
                              badge: badge('apple'),
                              busy: _busyProvider == 'apple',
                              onTap: () => _provider('apple'),
                            ),
                            const SizedBox(height: 12),
                            _AuthButton(
                              icon: SvgPicture.asset('assets/google_g.svg', width: 18, height: 18),
                              label: 'Continue with Google',
                              badge: badge('google'),
                              busy: _busyProvider == 'google',
                              onTap: () => _provider('google'),
                            ),
                            const SizedBox(height: 12),
                            _AuthButton(
                              icon: const Icon(Icons.mail_outline_rounded, size: 18, color: BethelColors.ivory),
                              label: 'Continue with email',
                              badge: badge('email'),
                              dark: true,
                              onTap: () => _open(_Step.email, method: 'email'),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: state.continueAsGuest,
                              style: TextButton.styleFrom(foregroundColor: BethelColors.ivory, minimumSize: const Size(0, 48)),
                              child: const Text('Continue as guest'),
                            ),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              _FooterLink('Privacy', onTap: () => openLink(context, AppConfig.privacyUrl)),
                              const SizedBox(width: 24),
                              _FooterLink('Terms', onTap: () => openLink(context, AppConfig.termsUrl)),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

bool _needsName(UserProfile u) => u.name.trim().isEmpty || u.name == 'Friend';

/// Full-width sign-in button: Ivory with Ink text, or translucent for email. Optional "Last used" badge.
class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.icon, required this.label, required this.onTap, this.dark = false, this.badge, this.busy = false});

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool dark;
  final String? badge;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? BethelColors.ivory : BethelColors.ink;
    return Pressable(
      onTap: busy ? null : onTap,
      semanticLabel: label,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: dark ? BethelColors.ivory.withValues(alpha: 0.14) : BethelColors.ivory,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg)),
                ]),
        ),
        if (badge != null)
          Positioned(
            right: 12,
            top: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(color: BethelColors.brass, borderRadius: BorderRadius.circular(999)),
              child: Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: BethelColors.ink)),
            ),
          ),
      ]),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: const TextStyle(fontSize: BethelType.caption, color: BethelColors.stone)),
        ),
      );
}

// ===================================================================== sign-in card

enum _Step { phone, code, verified, name, email, password, createPassword, forgot }

/// The floating card. One step at a time; Back steps one card back (or closes from the first step).
class _AuthFlow extends StatefulWidget {
  const _AuthFlow({required this.start, required this.method, this.pendingUser});

  final _Step start;

  /// 'phone', 'email', 'apple' or 'google' – saved as the "Last used" method on success.
  final String method;

  /// Set when Apple/Google signed in a new member who still needs to give a name.
  final UserProfile? pendingUser;

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

enum _CodeState { typing, checking, error }

class _AuthFlowState extends State<_AuthFlow> {
  late _Step _step = widget.start;
  final List<_Step> _history = [];

  final _phone = TextEditingController(text: '+1 ');
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _busy = false;
  String? _error;
  int _shake = 0;
  bool _hidePassword = true;
  bool _pendingSignUp = false;
  _CodeState _codeState = _CodeState.typing;

  int _resendIn = 0;
  Timer? _resendTimer;

  static bool get _canReadSms => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    // Apple or Google already signed in: show Verified briefly, then continue.
    final pending = widget.pendingUser;
    if (widget.start == _Step.verified && pending != null) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _afterVerify(pending);
      });
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _stopSmsListener();
    for (final c in [_phone, _code, _email, _password, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- navigation

  void _go(_Step s) => setState(() {
        // The Verified moment isn't a step you can go back to.
        if (_step != _Step.verified) _history.add(_step);
        _step = s;
        _error = null;
      });

  void _back() {
    if (_history.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    if (_step == _Step.code) _stopCode();
    setState(() {
      _step = _history.removeLast();
      _error = null;
    });
  }

  Future<void> _finish(UserProfile user) async {
    await _LastMethod.save(widget.method);
    if (!mounted) return;
    final state = AppScope.read(context);
    Navigator.of(context).pop();
    state.signInAs(user);
  }

  /// Phone, Apple and Google land here: new members give their name first.
  void _afterVerify(UserProfile user) {
    if (_needsName(user)) {
      _go(_Step.name);
    } else {
      _finish(user);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _shake++;
        });
        HapticFeedback.mediumImpact();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- phone

  /// "(630) 555-0123" → "+16305550123". Numbers typed with a country code are kept as they are.
  String get _e164 {
    final raw = _phone.text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('+') && !(digits.length == 11 && digits.startsWith('1')) && digits.length > 10) return '+$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    return '+1$digits';
  }

  /// "+16305550123" → "+1 (630) 555‑0123" (non-breaking hyphen so it never splits).
  String get _prettyPhone {
    final p = _e164;
    if (p.length == 12 && p.startsWith('+1')) return '+1 (${p.substring(2, 5)}) ${p.substring(5, 8)}‑${p.substring(8)}';
    return p;
  }

  Future<void> _sendCode() => _run(() async {
        if (_e164.replaceAll(RegExp(r'\D'), '').length < 11) throw 'Enter your phone number';
        await AppScope.read(context).repo.sendPhoneCode(_e164);
        if (!mounted) return;
        _code.clear();
        _codeState = _CodeState.typing;
        _go(_Step.code);
        _startResendTimer();
        _listenForSms();
      });

  Future<void> _resend() async {
    await _run(() async {
      await AppScope.read(context).repo.sendPhoneCode(_e164);
      if (!mounted) return;
      _code.clear();
      setState(() => _codeState = _CodeState.typing);
      showBethelToast(context, 'New code sent to $_prettyPhone');
      _startResendTimer();
      _listenForSms();
    });
  }

  /// Six digits typed or filled from Messages: check right away.
  Future<void> _verifyCode(String code) async {
    if (_codeState == _CodeState.checking) return;
    setState(() => _codeState = _CodeState.checking);
    try {
      final user = await AppScope.read(context).repo.verifyPhoneCode(code, name: _name.text);
      if (!mounted) return;
      _stopCode();
      HapticFeedback.lightImpact();
      _go(_Step.verified);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _afterVerify(user);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _codeState = _CodeState.error;
        _shake++;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _code.clear();
      setState(() => _codeState = _CodeState.typing);
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 42);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  void _stopCode() {
    _resendTimer?.cancel();
    _stopSmsListener();
  }

  /// Android: wait for the text, ask the person to allow reading it, then fill in the code.
  /// iPhone offers the code above the keyboard through the one-time-code autofill hint.
  Future<void> _listenForSms() async {
    if (!_canReadSms) return;
    await _stopSmsListener();
    final result = await SmartAuth.instance.getSmsWithUserConsentApi();
    final code = result.data?.code;
    if (!mounted || _step != _Step.code || code == null || code.length != 6) return;
    _code.text = code;
    _verifyCode(code);
  }

  Future<void> _stopSmsListener() async {
    if (_canReadSms) await SmartAuth.instance.removeUserConsentApiListener();
  }

  // ---------------------------------------------------------------- email

  void _emailContinue() {
    if (!_email.text.contains('@')) {
      setState(() {
        _error = 'Enter your email';
        _shake++;
      });
      return;
    }
    _go(_Step.password);
  }

  Future<void> _signIn() => _run(() async {
        if (_password.text.isEmpty) throw 'Enter your password';
        try {
          final user = await AppScope.read(context).repo.signIn(_email.text, _password.text);
          await _finish(user);
        } catch (e) {
          final m = '$e';
          throw m.contains('match') || m.contains('password') ? 'Wrong password' : m;
        }
      });

  void _createPassword() {
    if (_password.text.length < 8) {
      setState(() {
        _error = 'Use at least 8 characters';
        _shake++;
      });
      return;
    }
    _pendingSignUp = true;
    _go(_Step.name);
  }

  Future<void> _forgot() => _run(() async {
        await AppScope.read(context).repo.sendPasswordReset(_email.text);
        if (mounted) _go(_Step.forgot);
      });

  // ---------------------------------------------------------------- name

  Future<void> _saveName() => _run(() async {
        if (_name.text.trim().isEmpty) throw 'Enter your name';
        final repo = AppScope.read(context).repo;
        final user = _pendingSignUp
            ? await repo.signUp(_name.text, _email.text, _password.text)
            : await repo.updateName(_name.text);
        await _finish(user);
      });

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final dark = t.brightness == Brightness.dark;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final still = reduceMotion(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        child: AnimatedAlign(
          duration: still ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: insets > 0 ? Alignment.bottomCenter : Alignment.center,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + insets),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 60, offset: Offset(0, 24))],
                ),
                child: Material(
                  color: dark ? tk.card : t.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedSize(
                    duration: still ? Duration.zero : const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: AnimatedSwitcher(
                        duration: still ? Duration.zero : const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(key: ValueKey(_step), child: _content(t, tk)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(ThemeData t, BethelTokens tk) {
    switch (_step) {
      case _Step.phone:
        return _card(t, title: 'Your phone number', children: [
          _Shake(
            trigger: _shake,
            child: TileField(
              controller: _phone,
              label: 'Phone number',
              hint: '+1 (630) 555-0123',
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [_UsPhoneFormatter()],
              autofocus: true,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendCode(),
            ),
          ),
          _primary('Send code', _sendCode),
          Text('SMS rates may apply', textAlign: TextAlign.center, style: t.textTheme.bodySmall),
        ]);

      case _Step.code:
        return _card(t,
            title: 'Enter the code',
            sub: Wrap(alignment: WrapAlignment.center, children: [
              Text('Sent to ', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              GestureDetector(
                onTap: _back,
                child: Text(_prettyPhone, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.primary)),
              ),
            ]),
            children: [
              _Shake(
                trigger: _shake,
                child: _OtpField(
                  controller: _code,
                  error: _codeState == _CodeState.error,
                  enabled: _codeState == _CodeState.typing,
                  onCompleted: _verifyCode,
                ),
              ),
              SizedBox(
                height: 22,
                child: Center(
                  child: switch (_codeState) {
                    _CodeState.checking => Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: t.colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Text('Checking', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ]),
                    _CodeState.error => Text('Wrong code. Try again.', style: t.textTheme.bodyMedium?.copyWith(color: tk.error)),
                    _CodeState.typing => _resendIn > 0
                        ? Text('Resend in 0:${_resendIn.toString().padLeft(2, '0')}',
                            style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))
                        : GestureDetector(
                            onTap: _busy ? null : _resend,
                            child: Text('Resend code', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.primary)),
                          ),
                  },
                ),
              ),
            ]);

      case _Step.verified:
        final via = switch (widget.method) { 'apple' => 'Apple', 'google' => 'Google', _ => '' };
        return _card(t, title: via.isEmpty ? 'Enter the code' : 'Signed in with $via', showBack: false, children: [
          Column(children: [
            _CheckMark(color: t.colorScheme.primary),
            const SizedBox(height: 8),
            Text('Verified', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ]);

      case _Step.name:
        return _card(t, title: 'Your name', subText: 'Shown on the prayer wall', children: [
          _Shake(
            trigger: _shake,
            child: TileField(
              controller: _name,
              label: 'Your name',
              hint: 'Your name',
              autofillHints: const [AutofillHints.name],
              autofocus: true,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveName(),
            ),
          ),
          _primary('Continue', _saveName),
        ]);

      case _Step.email:
        return _card(t, title: 'Your email', children: [
          _Shake(
            trigger: _shake,
            child: TileField(
              controller: _email,
              label: 'Email',
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autofocus: true,
              errorText: _error,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _emailContinue(),
            ),
          ),
          _primary('Continue', () async => _emailContinue()),
        ]);

      case _Step.password:
        return _card(t, title: 'Password', subText: _email.text.trim(), children: [
          _Shake(
            trigger: _shake,
            child: TileField(
              controller: _password,
              label: 'Password',
              hint: 'Password',
              obscureText: _hidePassword,
              autofillHints: const [AutofillHints.password],
              autofocus: true,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(),
              trailing: TextButton(onPressed: _busy ? null : _forgot, child: const Text('Forgot?')),
            ),
          ),
          _primary('Continue', _signIn),
          Center(
            child: TextButton(
              onPressed: () {
                _password.clear();
                _go(_Step.createPassword);
              },
              child: const Text('New here? Create an account'),
            ),
          ),
        ]);

      case _Step.createPassword:
        return _card(t, title: 'Create a password', subText: _email.text.trim(), children: [
          _Shake(
            trigger: _shake,
            child: TileField(
              controller: _password,
              label: 'New password',
              hint: 'At least 8 characters',
              obscureText: _hidePassword,
              autofillHints: const [AutofillHints.newPassword],
              autofocus: true,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _createPassword(),
              trailing: IconButton(
                tooltip: _hidePassword ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: t.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          _primary('Continue', () async => _createPassword()),
        ]);

      case _Step.forgot:
        return _card(t, title: 'Check your email', subText: 'Reset link sent to ${_email.text.trim()}', children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: tk.tile, shape: BoxShape.circle, boxShadow: tk.tileShadow),
              child: Icon(Icons.mail_outline_rounded, size: 30, color: t.colorScheme.primary),
            ),
          ),
          _primary('Done', () async => _back()),
        ]);
    }
  }

  /// Card layout: round Back button on the left, centred title and subtitle, then the step's body.
  Widget _card(ThemeData t, {required String title, String? subText, Widget? sub, bool showBack = true, required List<Widget> children}) {
    final tk = BethelTokens.of(context);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 40,
          height: 40,
          child: showBack
              ? Pressable(
                  onTap: _back,
                  semanticLabel: 'Back',
                  child: Container(
                    decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
                    child: Icon(Icons.chevron_left_rounded, size: 24, color: t.colorScheme.onSurface),
                  ),
                )
              : null,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(children: [
              Text(title, textAlign: TextAlign.center, style: t.textTheme.headlineSmall),
              if (subText != null && subText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subText,
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ],
              if (sub != null) ...[const SizedBox(height: 4), sub],
            ]),
          ),
        ),
        const SizedBox(width: 40),
      ]),
      for (final c in children) ...[const SizedBox(height: 20), c],
    ]);
  }

  Widget _primary(String label, Future<void> Function() onTap) => FilledButton(
        onPressed: _busy ? null : onTap,
        child: _busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BethelColors.ivory))
            : Text(label),
      );
}

// ===================================================================== code entry

/// Six code tiles over a hidden text field. iPhone offers the texted code above the keyboard
/// (one-time-code autofill); typing or filling six digits calls [onCompleted].
class _OtpField extends StatefulWidget {
  const _OtpField({required this.controller, required this.onCompleted, this.error = false, this.enabled = true});

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool error;
  final bool enabled;

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    final v = widget.controller.text;
    if (v.length == 6 && widget.enabled) widget.onCompleted(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final code = widget.controller.text;
    return Stack(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < 6; i++)
            _Tile(
              digit: i < code.length ? code[i] : null,
              active: widget.enabled && i == code.length && _focus.hasFocus,
              error: widget.error,
              ringColor: widget.error ? tk.error : t.colorScheme.primary,
            ),
        ]),
        // The real input sits on top, invisible, so taps focus it and autofill can fill it.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: Semantics(
              label: '6-digit code',
              child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              showCursor: false,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(filled: false, border: InputBorder.none, counterText: ''),
              onTap: () => setState(() {}),
            ),
            ),
          ),
        ),
      ]);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.digit, required this.active, required this.error, required this.ringColor});

  final String? digit;
  final bool active;
  final bool error;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final still = reduceMotion(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: tk.tile,
        borderRadius: BorderRadius.circular(12),
        boxShadow: tk.tileShadow,
        border: Border.all(color: (active || error) ? ringColor : Colors.transparent, width: 2),
      ),
      alignment: Alignment.center,
      child: digit != null
          ? TweenAnimationBuilder<double>(
              key: ValueKey(digit),
              tween: Tween(begin: still ? 1 : 0.4, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: v, child: child)),
              child: Text(digit!,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: error ? tk.error : t.colorScheme.onSurface)),
            )
          : active
              ? _Caret(color: ringColor)
              : null,
    );
  }
}

/// Blinking cursor in the active code box.
class _Caret extends StatefulWidget {
  const _Caret({required this.color});
  final Color color;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Opacity(
          opacity: reduceMotion(context) || _c.value < 0.5 ? 1 : 0,
          child: Container(width: 2, height: 28, decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(1))),
        ),
      );
}

/// Shakes its child sideways whenever [trigger] changes (wrong code, wrong password).
class _Shake extends StatefulWidget {
  const _Shake({required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void didUpdateWidget(covariant _Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(math.sin(_c.value * math.pi * 4) * 8 * (1 - _c.value), 0),
          child: child,
        ),
      );
}

/// The check that draws itself after a correct code.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: reduceMotion(context) ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (_, v, __) => CustomPaint(size: const Size(88, 88), painter: _CheckPainter(v, color)),
      );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(4 * s, 12.5 * s)
      ..lineTo(9 * s, 17.5 * s)
      ..lineTo(20 * s, 6 * s);
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress || old.color != color;
}

/// Formats US numbers as "+1 (630) 555-0123" while typing. Numbers starting with another country code
/// (+44 …) are left as typed. Backspace over punctuation removes the digit before it.
class _UsPhoneFormatter extends TextInputFormatter {
  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.trim();
    if (raw.startsWith('+') && !raw.startsWith('+1')) return newValue;
    var d = _digits(raw);
    if (d.startsWith('1')) d = d.substring(1);
    final deleting = newValue.text.length < oldValue.text.length;
    if (deleting && _digits(newValue.text) == _digits(oldValue.text) && d.isNotEmpty) d = d.substring(0, d.length - 1);
    if (d.length > 10) d = d.substring(0, 10);
    final b = StringBuffer('+1 ');
    if (d.isNotEmpty) b.write('(${d.substring(0, d.length < 3 ? d.length : 3)}');
    if (d.length >= 3) b.write(') ');
    if (d.length > 3) b.write(d.substring(3, d.length < 6 ? d.length : 6));
    if (d.length > 6) b.write('-${d.substring(6)}');
    final text = b.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
