// lib/widgets/app_lock_gate.dart
// Wraps the app and intercepts lifecycle events.
// When app comes to foreground, checks if lock should show.

import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../screens/lock/lock_screen.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _checkingLock = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check immediately - whether to show lock on cold start
    _checkColdStartLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkColdStartLock() async {
    final svc = AppLockService.instance;
    debugPrint("AppLockGate: cold start check. enabled=${svc.isEnabled}");
    if (svc.isEnabled) {
      debugPrint("AppLockGate: locking on cold start");
      if (mounted) {
        setState(() {
          _locked = true;
          _checkingLock = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _checkingLock = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final svc = AppLockService.instance;
    debugPrint("AppLockGate: lifecycle=\$state, enabled=\${svc.isEnabled}");
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        svc.markBackground();
        break;
      case AppLifecycleState.resumed:
        if (svc.isEnabled && !_locked) {
          // Check elapsed time
          svc.shouldShowLock().then((shouldLock) {
            debugPrint("AppLockGate: resumed - shouldLock=\$shouldLock");
            if (shouldLock && mounted) {
              setState(() => _locked = true);
            }
          });
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onUnlock() {
    debugPrint("AppLockGate: unlocked!");
    if (mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLock) {
      // While we're checking on cold start, show a blank screen so user doesnt
      // briefly see the home screen before lock appears
      return const Material(
        color: Color(0xFFF1F5FF),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_locked) {
      return LockScreen(onUnlocked: _onUnlock);
    }

    return widget.child;
  }
}
