// lib/widgets/app_lock_gate.dart
// Wraps the app and intercepts lifecycle events.
// When app comes to foreground, checks if lock should show.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_lock_service.dart';
import '../screens/lock/lock_screen.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _showingLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for lock immediately after first frame (handles cold start)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        AppLockService.instance.markBackground();
        break;
      case AppLifecycleState.resumed:
        _checkLock();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _checkLock() async {
    if (_showingLock) return;
    final svc = AppLockService.instance;
    if (!svc.isEnabled) return;
    final shouldLock = await svc.shouldShowLock();
    if (!shouldLock) return;
    if (!mounted) return;

    _showingLock = true;
    // Use root navigator so lock screen overlays everything
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const LockScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    _showingLock = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
