// lib/services/session_guard.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import 'auth_service.dart';

class SessionGuard extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const SessionGuard({super.key, required this.child, required this.navigatorKey});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> with WidgetsBindingObserver {
  static const Duration _idleDuration = Duration(minutes: 5);
  static const Duration _backgroundTimeoutDuration = Duration(minutes: 2);
  static const Duration _activityTouchInterval = Duration(seconds: 60);

  final AuthService _authService = AuthService();

  Timer? _idleTimer;
  Timer? _backgroundTimer;   // ← timer 3 menit saat app di background
  bool _isLoggingOut = false;
  bool _isCheckingSession = false;
  DateTime? _lastServerTouchAt;
  DateTime? _backgroundedAt;  // ← kapan app masuk background

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _resetIdleTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        _checkSessionFromServer(extendSession: false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _backgroundTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 AppLifecycleState: $state');

    if (kIsWeb) {
      debugPrint('🌐 Web lifecycle ignored for session: $state');
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // App kembali ke foreground — batalkan timer background
      _backgroundTimer?.cancel();
      _backgroundTimer = null;

      if (_backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        debugPrint('⏱ App resumed setelah ${elapsed.inSeconds}s di background');
        _backgroundedAt = null;

        // Kalau sudah > 3 menit saat resumed (race condition), langsung logout
        if (elapsed >= _backgroundTimeoutDuration) {
          debugPrint('🔒 Background terlalu lama (${elapsed.inMinutes}m), logout');
          _checkThenLogout(reason: 'Background lebih dari 3 menit');
          return;
        }
      }

      _checkSessionFromServer(extendSession: false);
      return;
    }

    // App masuk background (home button ditekan, dll.)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
      debugPrint('🏠 App di background, mulai timer ${_backgroundTimeoutDuration.inMinutes} menit');

      _backgroundTimer?.cancel();
      _backgroundTimer = Timer(_backgroundTimeoutDuration, () {
        debugPrint('⏰ Timer background ${_backgroundTimeoutDuration.inMinutes} menit habis → logout');
        _checkThenLogout(reason: 'Background lebih dari ${_backgroundTimeoutDuration.inMinutes} menit');
      });
    }

    // App benar-benar ditutup (swipe kill) → langsung logout
    if (state == AppLifecycleState.detached) {
      _backgroundTimer?.cancel();
      _checkThenLogout(reason: 'App closed / detached');
    }
  }

  Future<bool> _hasLocalSession() async {
    final session = await _authService.getSessionData();

    final bprId = session['bpr_id']?.toString() ?? '';
    final userId = session['user_id']?.toString() ?? '';
    final token = session['session_token']?.toString() ?? session['login_session_token']?.toString() ?? session['token']?.toString() ?? '';

    return bprId.isNotEmpty && userId.isNotEmpty && token.isNotEmpty;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();

    _idleTimer = Timer(_idleDuration, () {
      _checkThenLogout(reason: 'Idle 5 menit');
    });
  }

  void _onUserActivity() {
    _resetIdleTimer();

    final now = DateTime.now();

    if (_lastServerTouchAt == null || now.difference(_lastServerTouchAt!) >= _activityTouchInterval) {
      _lastServerTouchAt = now;

      if (!kIsWeb) {
        _checkSessionFromServer(extendSession: true);
      }
    }
  }

  Future<void> _checkSessionFromServer({required bool extendSession}) async {
    if (_isCheckingSession || _isLoggingOut) return;

    final hasSession = await _hasLocalSession();
    if (!hasSession) return;

    _isCheckingSession = true;

    try {
      final result = await _authService.checkSessionTimeout(extendSession: extendSession);

      final shouldLogout = result['should_logout'] == true;

      if (shouldLogout) {
        debugPrint('🔒 Server meminta logout: ${result['message']}');
        await _logoutAndGoLogin(reason: result['reason']?.toString() ?? 'SESSION_INVALID');
      }
    } catch (e) {
      debugPrint('❌ Check session error: $e');
    } finally {
      _isCheckingSession = false;
    }
  }

  Future<void> _checkThenLogout({required String reason}) async {
    if (_isLoggingOut) return;

    final hasSession = await _hasLocalSession();
    if (!hasSession) return;

    try {
      await _authService.checkSessionTimeout(extendSession: false);
    } catch (e) {
      debugPrint('❌ Check before logout error: $e');
    }

    await _logoutAndGoLogin(reason: reason);
  }

  Future<void> _logoutAndGoLogin({required String reason}) async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;

    try {
      final session = await _authService.getSessionData();
      final token = session['session_token']?.toString() ?? session['login_session_token']?.toString() ?? session['token']?.toString() ?? '';

      if (token.isEmpty) {
        debugPrint('🔒 Logout skipped: session kosong');
        await _authService.clearSession();
      } else {
        debugPrint('🔒 Logout triggered: $reason');
        await _authService.logoutCurrentSession();
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      await _authService.clearSession();
    } finally {
      _idleTimer?.cancel();
      _backgroundTimer?.cancel();
      _isLoggingOut = false;

      final navigator = widget.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      onPointerSignal: (_) => _onUserActivity(),
      child: widget.child,
    );
  }
}