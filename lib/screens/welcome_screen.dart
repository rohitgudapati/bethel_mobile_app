import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_auth/smart_auth.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

/// First screen: "Sacred Simplicity, Modern Elegance".
/// Sanctuary photo, the church logo and name at the top, a short promise in the middle,
/// one clear action at the bottom.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Very dark forest, used for the photo's shading.
  static const _shade = Color(0xFF0F1B19);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final ivory = BethelColors.ivory;
    return Scaffold(
      backgroundColor: _shade,
      body: Stack(fit: StackFit.expand, children: [
        // Keep the lit window on the right in view on wide and narrow screens.
        const BethelImage('assets/church/sanctuary.jpg', fit: BoxFit.cover, alignment: Alignment(0.45, 0)),
        // Shade the top (logo) and bottom (actions); leave the light rays in the middle.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _shade.withValues(alpha: 0.85),
                _shade.withValues(alpha: 0.35),
                _shade.withValues(alpha: 0.25),
                _shade.withValues(alpha: 0.88),
                _shade,
              ],
              stops: const [0, 0.32, 0.55, 0.8, 1],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            // Scrolls on very short screens; otherwise the spacers spread the three blocks out.
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                        child: Column(children: [
                          // ---- Logo and name
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: BethelColors.brass.withValues(alpha: 0.7), width: 1.2),
                              boxShadow: [BoxShadow(color: BethelColors.brass.withValues(alpha: 0.22), blurRadius: 30)],
                            ),
                            child: const ClipOval(child: BethelImage('assets/church/logo.png', width: 76, height: 76)),
                          ),
                          const SizedBox(height: 18),
                          Text('BETHEL\nPRAYER HOUSE',
                              textAlign: TextAlign.center,
                              style: _serif(25, ivory).copyWith(letterSpacing: 5, height: 1.3)),
                          const SizedBox(height: 10),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _rule(),
                            const SizedBox(width: 12),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Naperville, Illinois',
                                    style: _serif(15.5, ivory.withValues(alpha: 0.88), italic: true)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _rule(),
                          ]),
                          const Spacer(flex: 3),
                          const SizedBox(height: 28),
                          // ---- Promise
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(children: [
                              Text('Rooted in faith.', style: _serif(40, ivory).copyWith(height: 1.15, shadows: _glow)),
                              Text('United in Christ.',
                                  style: _serif(40, const Color(0xFFD6BF97), italic: true)
                                      .copyWith(height: 1.15, shadows: _glow)),
                            ]),
                          ),
                          const SizedBox(height: 18),
                          Text('Your church family,\nwherever life takes you.',
                              textAlign: TextAlign.center,
                              style: _sw(17, FontWeight.w400, ivory.withValues(alpha: 0.86))
                                  .copyWith(height: 1.45, shadows: _glow)),
                          const Spacer(flex: 4),
                          const SizedBox(height: 28),
                          // ---- Actions
                          _BrassButton(label: 'Get started', onTap: () => _openAuth(context, signUp: true)),
                          const SizedBox(height: 14),
                          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                            Text('Already a member? ', style: _sw(16, FontWeight.w400, ivory)),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _openAuth(context, signUp: false),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                                child: Text('Sign in',
                                    style: _sw(16, FontWeight.w600, BethelColors.brassLight).copyWith(
                                      decoration: TextDecoration.underline,
                                      decorationColor: BethelColors.brass,
                                      decorationThickness: 1.6,
                                    )),
                              ),
                            ),
                          ]),
                          TextButton(
                            onPressed: state.continueAsGuest,
                            style: TextButton.styleFrom(
                              foregroundColor: ivory.withValues(alpha: 0.8),
                              textStyle: _sw(15.5, FontWeight.w500),
                            ),
                            child: const Text('Continue as guest'),
                          ),
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
    );
  }

  /// Soft dark halo so text stays readable over the bright light rays.
  static const _glow = [Shadow(color: Color(0xB3000000), blurRadius: 20)];

  static Widget _rule() => Container(width: 34, height: 1, color: BethelColors.brass.withValues(alpha: 0.8));

  static TextStyle _serif(double size, Color color, {bool italic = false}) => TextStyle(
        fontFamily: BethelFonts.display,
        fontSize: size,
        fontWeight: FontWeight.w500,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color,
      );

  static TextStyle _sw(double size, FontWeight weight, [Color? color]) =>
      TextStyle(fontFamily: BethelFonts.welcome, fontSize: size, fontWeight: weight, color: color);

  /// Sign in / sign up as a floating card in the middle of the screen.
  void _openAuth(BuildContext context, {required bool signUp}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0x8C0B1626),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => AuthCard(signUp: signUp),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * anim.value, sigmaY: 8 * anim.value),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
          ),
        );
      },
    );
  }
}

/// The main call to action: a brass pill with dark text.
class _BrassButton extends StatelessWidget {
  const _BrassButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BethelColors.brassLight, BethelColors.brass],
        ),
        boxShadow: [
          BoxShadow(color: BethelColors.brass.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            width: double.infinity,
            child: Center(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: BethelFonts.welcome,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: BethelColors.ink)),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Method { email, phone }

class AuthCard extends StatefulWidget {
  const AuthCard({super.key, required this.signUp});
  final bool signUp;

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  late bool _signUp = widget.signUp;
  _Method _method = _Method.email;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  /// True once a code has been texted: the card shows the "Verify your phone number" step.
  bool _codeSent = false;
  String? _error;

  /// Seconds until "Resend" can be tapped again.
  int _resendIn = 0;
  Timer? _resendTimer;

  /// Android only: reads the code from the incoming text after the person allows it.
  static bool get _canReadSms => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _stopSmsListener();
    for (final c in [_name, _email, _password, _phone, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "(630) 555-0123" → "+16305550123". Numbers typed with a leading + are kept as they are.
  String get _e164 {
    final raw = _phone.text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('+')) return '+$digits';
    return digits.length == 11 && digits.startsWith('1') ? '+$digits' : '+1$digits';
  }

  /// "+16305550123" → "+1 (630) 555-0123", with non-breaking spaces so it never splits across lines.
  String get _prettyPhone {
    final p = _e164;
    if (p.length == 12 && p.startsWith('+1')) {
      return '+1 (${p.substring(2, 5)}) ${p.substring(5, 8)}‑${p.substring(8)}';
    }
    return p;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _done(UserProfile user) {
    if (!mounted) return;
    final state = AppScope.read(context);
    Navigator.of(context).pop();
    state.signInAs(user);
  }

  void _checkName() {
    if (_signUp && _name.text.trim().isEmpty) throw 'Please tell us your name.';
  }

  Future<void> _submitEmail() => _run(() async {
        _checkName();
        final repo = AppScope.read(context).repo;
        _done(_signUp
            ? await repo.signUp(_name.text, _email.text, _password.text)
            : await repo.signIn(_email.text, _password.text));
      });

  Future<void> _sendCode() => _run(() async {
        _checkName();
        if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 10) throw 'Please enter your phone number.';
        await AppScope.read(context).repo.sendPhoneCode(_e164);
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _code.clear();
        });
        _startResendTimer();
        _listenForSms();
      });

  Future<void> _resend() async {
    await _run(() async {
      await AppScope.read(context).repo.sendPhoneCode(_e164);
      if (!mounted) return;
      _code.clear();
      showToast(context, 'We sent a new code to $_prettyPhone.');
      _startResendTimer();
      _listenForSms();
    });
  }

  Future<void> _verifyCode() async {
    if (_busy) return;
    await _run(() async {
      _done(await AppScope.read(context).repo.verifyPhoneCode(_code.text, name: _name.text));
    });
    // A wrong code: empty the boxes so it can be typed again (the message stays until then).
    if (mounted && _error != null) _code.clear();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  /// Android: wait for the text, ask the person to allow reading it, then fill in and verify the code.
  /// (iPhone and the web offer the code above the keyboard through the one-time-code autofill hint.)
  Future<void> _listenForSms() async {
    if (!_canReadSms) return;
    await _stopSmsListener();
    final result = await SmartAuth.instance.getSmsWithUserConsentApi();
    final code = result.data?.code;
    if (!mounted || !_codeSent || code == null || code.length != _OtpBoxes.length) return;
    _code.text = code;
    _verifyCode();
  }

  Future<void> _stopSmsListener() async {
    if (_canReadSms) await SmartAuth.instance.removeUserConsentApiListener();
  }

  void _changeNumber() {
    _stopSmsListener();
    _resendTimer?.cancel();
    setState(() {
      _codeSent = false;
      _resendIn = 0;
      _code.clear();
      _error = null;
    });
  }

  void _setMethod(_Method m) => setState(() {
        _method = m;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final verifying = _method == _Method.phone && _codeSent;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + insets),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x47000000), blurRadius: 48, spreadRadius: -6, offset: Offset(0, 22)),
                  BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Material(
                color: t.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: verifying
                          ? KeyedSubtree(key: const ValueKey('verify'), child: _verifyView(t))
                          : KeyedSubtree(key: const ValueKey('form'), child: _formView(t)),
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

  Widget _closeButton(ThemeData t) => IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.close_rounded, color: t.colorScheme.onSurfaceVariant),
      );

  TextStyle _titleStyle(ThemeData t) => TextStyle(
      fontFamily: BethelFonts.display,
      fontSize: 32,
      height: 1.1,
      fontWeight: FontWeight.w600,
      color: t.colorScheme.onSurface);

  // ----------------------------------------------------------------- step 1: details

  Widget _formView(ThemeData t) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Logo centred, close button in the top-right corner.
      Stack(alignment: Alignment.center, children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: ClipOval(child: BethelImage('assets/church/logo.png', width: 48, height: 48)),
        ),
        Align(alignment: Alignment.topRight, child: _closeButton(t)),
      ]),
      const SizedBox(height: 14),
      Text(_signUp ? 'Join the family' : 'Welcome back', textAlign: TextAlign.center, style: _titleStyle(t)),
      const SizedBox(height: 6),
      Text(_signUp ? 'Create your Bethel account.' : 'Sign in to continue.',
          textAlign: TextAlign.center, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 20),
      _MethodSwitch(value: _method, onChanged: _busy ? null : _setMethod),
      const SizedBox(height: 16),
      if (_signUp) ...[
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 12),
      ],
      ...(_method == _Method.email ? _emailFields(t) : _phoneFields(t)),
      if (_error != null) ...[
        const SizedBox(height: 10),
        Text(_error!, style: TextStyle(color: t.colorScheme.error)),
      ],
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : (_method == _Method.email ? _submitEmail : _sendCode),
        child: _busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
            : Text(_method == _Method.phone ? 'Send code' : (_signUp ? 'Create account' : 'Sign in')),
      ),
      const SizedBox(height: 16),
      Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
        ),
        const Expanded(child: Divider()),
      ]),
      const SizedBox(height: 14),
      Center(
        child: _GoogleButton(
            onTap: () => showToast(context, 'Google sign-in connects to the API\'s OAuthSignIn endpoint.')),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => setState(() {
          _signUp = !_signUp;
          _error = null;
        }),
        child: Text(_signUp ? 'Already have an account? Sign in' : 'New here? Create an account'),
      ),
    ]);
  }

  List<Widget> _emailFields(ThemeData t) => [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _hide,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submitEmail(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
        ),
        if (!_signUp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => showToast(context, 'We\'ll email you a code to reset your password.'),
              child: const Text('Forgot password?'),
            ),
          ),
      ];

  List<Widget> _phoneFields(ThemeData t) => [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          onSubmitted: (_) => _sendCode(),
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '(630) 555-0123',
            prefixIcon: Icon(Icons.phone_iphone_rounded),
            prefixText: '+1  ',
          ),
        ),
        const SizedBox(height: 8),
        Text('We\'ll text you a 6-digit code. Message and data rates may apply.',
            style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
      ];

  // ----------------------------------------------------------------- step 2: verify phone

  Widget _verifyView(ThemeData t) {
    final muted = TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.5);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        IconButton(
          tooltip: 'Change number',
          onPressed: _busy ? null : _changeNumber,
          icon: Icon(Icons.arrow_back_rounded, color: t.colorScheme.onSurfaceVariant),
        ),
        const Spacer(),
        _closeButton(t),
      ]),
      const SizedBox(height: 4),
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.brightness == Brightness.dark ? BethelColors.nightCard : BethelColors.brassSoft,
          ),
          child: const Icon(Icons.sms_outlined, color: BethelColors.brass, size: 28),
        ),
      ),
      const SizedBox(height: 18),
      Text('Verify your phone number', textAlign: TextAlign.center, style: _titleStyle(t).copyWith(fontSize: 28)),
      const SizedBox(height: 10),
      Text.rich(
        TextSpan(style: muted, children: [
          const TextSpan(text: 'Enter the 6-digit code we sent to '),
          TextSpan(text: _prettyPhone, style: TextStyle(fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
          const TextSpan(text: '. It expires in 10 minutes.'),
        ]),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      _OtpBoxes(controller: _code, enabled: !_busy, onCompleted: _verifyCode),
      // Status: checking the code, or what went wrong.
      SizedBox(
        height: 44,
        child: Center(
          child: _busy
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('Verifying…', style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w500)),
                ])
              : _error != null
                  ? Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: t.colorScheme.error))
                  : null,
        ),
      ),
      // Wraps onto two lines on narrow phones instead of overflowing.
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('Didn\'t get a code? ', style: muted),
        if (_resendIn > 0)
          Text('Resend in 0:${_resendIn.toString().padLeft(2, '0')}',
              style: muted.copyWith(fontWeight: FontWeight.w700))
        else
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _busy ? null : _resend,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text('Resend',
                  style: TextStyle(fontWeight: FontWeight.w700, color: t.colorScheme.primary, fontSize: 14)),
            ),
          ),
      ]),
      const SizedBox(height: 4),
    ]);
  }
}

/// Round "Sign in with Google" button showing only the Google logo.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Tooltip(
      message: 'Continue with Google',
      child: Semantics(
        button: true,
        label: 'Continue with Google',
        child: Material(
          color: t.colorScheme.surfaceContainerLow,
          shape: CircleBorder(side: BorderSide(color: t.colorScheme.outlineVariant)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(child: SvgPicture.asset('assets/google_main.svg', width: 24, height: 24)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Six separate boxes for the texted code.
///
/// One invisible text field sits on top of the boxes and holds the whole code, so typing,
/// backspace, pasting a full code and SMS autofill all work; the boxes just show its digits.
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({required this.controller, required this.onCompleted, this.enabled = true});
  final TextEditingController controller;
  final VoidCallback onCompleted;
  final bool enabled;

  static const length = 6;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    // Repaint when the code is filled in or cleared from outside (SMS autofill, wrong code).
    widget.controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final code = widget.controller.text;
    return SizedBox(
      height: 58,
      child: Stack(children: [
        Row(children: [
          for (var i = 0; i < _OtpBoxes.length; i++) ...[
            // 3 – 3, like the code is usually read out.
            if (i == 3)
              SizedBox(
                width: 26,
                child: Center(
                  child: Container(
                    width: 10,
                    height: 2.2,
                    decoration:
                        BoxDecoration(color: t.colorScheme.onSurfaceVariant, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              )
            else if (i > 0)
              const SizedBox(width: 8),
            Expanded(child: _box(t, i, code)),
          ],
        ]),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: true,
              enabled: widget.enabled,
              showCursor: false,
              enableInteractiveSelection: false,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_OtpBoxes.length),
              ],
              onChanged: (v) {
                setState(() {});
                if (v.length == _OtpBoxes.length) widget.onCompleted();
              },
              decoration: const InputDecoration(border: InputBorder.none, filled: false, counterText: ''),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _box(ThemeData t, int i, String code) {
    final filled = i < code.length;
    final active =
        _focus.hasFocus && (i == code.length || (i == _OtpBoxes.length - 1 && code.length == _OtpBoxes.length));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? t.colorScheme.primary : (filled ? BethelColors.brass : t.colorScheme.outlineVariant),
          width: active ? 1.8 : 1.2,
        ),
      ),
      child: filled
          ? Text(code[i], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface))
          : active
              ? Container(width: 2, height: 22, color: t.colorScheme.primary) // caret
              : null,
    );
  }
}

/// Two-option pill switch: Email | Phone.
class _MethodSwitch extends StatelessWidget {
  const _MethodSwitch({required this.value, required this.onChanged});
  final _Method value;
  final ValueChanged<_Method>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget option(_Method m, IconData icon, String label) {
      final selected = m == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged!(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? t.colorScheme.surfaceContainerLow : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  selected ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: selected ? t.colorScheme.primary : t.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? t.colorScheme.onSurface : t.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        option(_Method.email, Icons.mail_outline_rounded, 'Email'),
        option(_Method.phone, Icons.phone_iphone_rounded, 'Phone'),
      ]),
    );
  }
}
