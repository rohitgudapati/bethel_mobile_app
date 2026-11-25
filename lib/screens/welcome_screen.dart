import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../widgets/common.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Scaffold(
      backgroundColor: BethelColors.navyDeep,
      body: Stack(fit: StackFit.expand, children: [
        const BethelImage('assets/church.jpg'),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Color(0x33000000), Color(0xEE14273F), BethelColors.navyDeep],
              stops: [0, 0.3, 0.68, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const ClipOval(child: BethelImage('assets/bethel_logo.png', width: 44, height: 44)),
                ),
                const SizedBox(width: 12),
                const Text(AppConfig.churchCity,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
              ]),
              const Spacer(),
              const Text('Welcome home.',
                  style: TextStyle(color: BethelColors.goldSoft, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('Bethel\nPrayer House',
                  style: TextStyle(fontFamily: 'Quintessential', color: Colors.white, fontSize: 46, height: 1.05)),
              const SizedBox(height: 14),
              const Text(
                'Worship live, read today\'s verse, share prayer requests and stay close to your church family, all in one place.',
                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: BethelColors.gold, foregroundColor: Colors.white),
                  onPressed: () => _openAuth(context, signUp: true),
                  child: const Text('Create an account'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, side: const BorderSide(color: Color(0x66FFFFFF))),
                  onPressed: () => _openAuth(context, signUp: false),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: state.continueAsGuest,
                  style: TextButton.styleFrom(foregroundColor: const Color(0xCCFFFFFF)),
                  child: const Text('Explore as a guest'),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  void _openAuth(BuildContext context, {required bool signUp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AuthSheet(signUp: signUp),
    );
  }
}

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.signUp});
  final bool signUp;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  late bool _signUp = widget.signUp;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  Future<void> _submit() async {
    final state = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signUp && _name.text.trim().isEmpty) throw 'Please tell us your name.';
      final user = _signUp
          ? await state.repo.signUp(_name.text, _email.text, _password.text)
          : await state.repo.signIn(_email.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      state.signInAs(user);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_signUp ? 'Join the family' : 'Welcome back', style: t.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(_signUp ? 'Create your Bethel account.' : 'Sign in to continue.',
            style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        if (_signUp) ...[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _hide,
          onSubmitted: (_) => _submit(),
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
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: t.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
              : Text(_signUp ? 'Create account' : 'Sign in'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showToast(context, 'Google sign-in connects to the API\'s OAuthSignIn endpoint.'),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _signUp = !_signUp;
            _error = null;
          }),
          child: Text(_signUp ? 'Already have an account? Sign in' : 'New here? Create an account'),
        ),
      ]),
    );
  }
}
