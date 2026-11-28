import 'config.dart';
import 'launch.dart';

/// The app's idea of "now". In the demo it can be moved, so every Home situation can be
/// tried without waiting for Sunday: `?now=2026-12-06T15:10` on the web demo, or
/// `--dart-define=DEMO_NOW=2026-12-06T15:10`. With live data it is always the real time.
DateTime appNow() {
  final o = _testNow ?? _override;
  if (o == null) return DateTime.now();
  return o.add(DateTime.now().difference(_startedAt));
}

final DateTime _startedAt = DateTime.now();
DateTime? _testNow;

final DateTime? _override = () {
  if (!AppConfig.isDemo) return null;
  const fromDefine = String.fromEnvironment('DEMO_NOW');
  final raw = LaunchOptions.now ?? (fromDefine.isEmpty ? null : fromDefine);
  return raw == null ? null : DateTime.tryParse(raw);
}();

/// Tests: pin the clock (null to release it).
void setTestNow(DateTime? now) => _testNow = now;
