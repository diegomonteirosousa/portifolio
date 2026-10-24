import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'screens/splash_intro.dart';
import 'services/notifications.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.instance.init();
  final state = await AppState.load();
  runApp(ForjaApp(state: state));
}

class ForjaApp extends StatelessWidget {
  final AppState state;
  const ForjaApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Forja',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _intro = true;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final Widget child;
    if (_intro) {
      child = SplashIntro(
        key: const ValueKey('intro'),
        onDone: () => setState(() => _intro = false),
      );
    } else if (state.onboarded) {
      child = const MainShell(key: ValueKey('shell'));
    } else {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      child: child,
    );
  }
}
