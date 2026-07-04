// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/auth_model.dart';
import '../network/network.dart';
import 'token_interceptor.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _namaKey = 'nama';
  static const String _bprIdKey = 'bpr_id';
  static const String _deviceIdKey = 'device_id';
  static const String _sessionTokenKey = 'session_token';
  static const String _noCifKey = 'no_cif';
  static const String _roleUserKey = 'role_user';
  static const String _jabatanKey = 'jabatan';

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  Future<LoginResponse> login({required String bprId, required String userId, required String password}) async {
    final normalizedUserId = userId.trim().toUpperCase();
    final deviceId = await getOrCreateDeviceId();

    // PRECHECK DEVICE BINDING DULU sebelum login lama.
    // Tujuan: kalau user/device sudah tidak valid, jangan panggil /petugas/login
    // supaya endpoint lama tidak sempat mengubah is_login.
    final precheck = await precheckDeviceBinding(
      bprId: bprId,
      username: normalizedUserId,
      deviceId: deviceId,
    );

    if (precheck['success'] != true) {
      return LoginResponse(
        code: precheck['code']?.toString() ?? '423',
        status: 'error',
        message: precheck['message']?.toString() ?? 'Perangkat tidak valid untuk login.',
        token: null,
        user: null,
      );
    }

    final response = await http.post(
      Uri.parse(NetworkUrl.login()),
      headers: NetworkUrl.jsonHeaders(),
      body: jsonEncode({
        'bpr_id': bprId,
        'user_id': normalizedUserId,
        'password': password,
        'device_id': deviceId,
        'device_name': 'Mobile Agent',
      }),
    );

    final result = LoginResponse.fromJson(jsonDecode(response.body));

    if (result.isSuccess && result.token != null) {
      final resolvedUserId = result.user?.userId ?? normalizedUserId;
      final resolvedNoCif = result.user?.noCif ?? resolvedUserId;
      final resolvedNama = result.user?.nama ?? normalizedUserId;
      final resolvedBprId = result.user?.bprId ?? bprId;
      final resolvedRoleUser = result.user?.roleUser ?? '';
      final resolvedJabatan = result.user?.jabatan ?? '';

      final sessionToken = result.token!;

      await _saveSession(
        token: result.token!,
        userId: resolvedUserId,
        noCif: resolvedNoCif,
        nama: resolvedNama,
        bprId: resolvedBprId,
        deviceId: deviceId,
        sessionToken: sessionToken,
        roleUser: resolvedRoleUser,
        jabatan: resolvedJabatan,
      );

      final startSessionResult = await startSession(
        bprId: resolvedBprId,
        username: resolvedUserId,
        noCif: resolvedNoCif,
        deviceId: deviceId,
        deviceName: 'Mobile Agent',
        sessionToken: sessionToken,
        roleUser: resolvedRoleUser,
        jabatan: resolvedJabatan,
      );

      if (startSessionResult['success'] != true) {
        // Karena login lama sudah sempat berhasil, panggil logout lama diam-diam
        // agar status session lama tidak menggantung jika startSession gagal.
        await logoutLegacySilently(bprId: resolvedBprId, userId: resolvedUserId);
        await clearSession();

        return LoginResponse(
          code: startSessionResult['code']?.toString() ?? 'SESSION_ERROR',
          status: 'error',
          message: startSessionResult['message']?.toString() ?? 'Login berhasil, tetapi gagal memulai session.',
          token: null,
          user: null,
        );
      }

      try {
        final fcmToken = await getFcmToken();

        if (fcmToken.isNotEmpty) {
          await updateFcmToken(
            bprId: resolvedBprId,
            noCif: resolvedNoCif,
            username: resolvedUserId,
            fcmToken: fcmToken,
            deviceId: deviceId,
            sessionToken: sessionToken,
          );
        }
      } catch (_) {
        // Login tetap sukses walaupun update FCM token gagal.
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> precheckDeviceBinding({
    required String bprId,
    required String username,
    required String deviceId,
  }) async {
    try {
      final payload = {
        'bpr_id': bprId.trim(),
        'username': username.trim().toUpperCase(),
        'device_id': deviceId.trim(),
      };

      debugPrint('🔐 SESSION PRECHECK URL: ${NetworkUrl.sessionPrecheck()}');
      debugPrint('🔐 SESSION PRECHECK BODY: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(NetworkUrl.sessionPrecheck()),
        headers: {'Content-Type': 'application/json', 'api-key': NetworkUrl.apiKey, 'X-API-Key': NetworkUrl.apiKey, 'API-Key': NetworkUrl.apiKey},
        body: jsonEncode(payload),
      );

      debugPrint('🔐 SESSION PRECHECK STATUS: ${response.statusCode}');
      debugPrint('🔐 SESSION PRECHECK RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        return {'success': false, 'code': 'HTTP_${response.statusCode}', 'message': 'Gagal mengecek perangkat. HTTP ${response.statusCode}', 'data': null};
      }

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['code']?.toString() == '000',
        'code': jsonData['code']?.toString() ?? '',
        'message': jsonData['message']?.toString() ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      debugPrint('❌ precheckDeviceBinding error: $e');
      return {'success': false, 'code': 'EXCEPTION', 'message': 'Gagal mengecek perangkat: $e', 'data': null};
    }
  }

  Future<String> getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      return token ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    const key = 'mobile_agent_device_id';
    final existing = prefs.getString(key);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newDeviceId = 'MA-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(key, newDeviceId);

    return newDeviceId;
  }

  Future<AuthResponse> updateFcmToken({
    required String bprId,
    required String noCif,
    required String username,
    required String fcmToken,
    String? deviceId,
    String? sessionToken,
  }) async {
    final payload = {
      'bpr_id': bprId,
      'no_cif': noCif.trim(),
      'username': username.trim().toUpperCase(),
      'fcm_token': fcmToken.trim(),
      if ((deviceId ?? '').trim().isNotEmpty) 'device_id': deviceId!.trim(),
      if ((sessionToken ?? '').trim().isNotEmpty) 'session_token': sessionToken!.trim(),
    };

    debugPrint('🔥 UPDATE FCM URL: ${NetworkUrl.updateFcmToken()}');
    debugPrint('🔥 UPDATE FCM PAYLOAD: ${jsonEncode(payload)}');

    final response = await http.post(
      Uri.parse(NetworkUrl.updateFcmToken()),
      headers: {'Content-Type': 'application/json', 'api-key': NetworkUrl.apiKey, 'X-API-Key': NetworkUrl.apiKey},
      body: jsonEncode(payload),
    );

    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  // ── LOGOUT ─────────────────────────────────────────────────────────────────
  Future<AuthResponse> logout({required String bprId, required String userId}) async {
    // Tambahan: logout session di medfo-go agar is_login menjadi N,
    // tetapi device binding tetap disimpan di backend.
    // Flow logout lama di bawah tetap dipertahankan.
    try {
      await logoutAgentSession();
    } catch (e) {
      debugPrint('⚠️ logoutAgentSession gagal: $e');
    }

    try {
      final response = await TokenInterceptor.post(Uri.parse(NetworkUrl.logout()), body: jsonEncode({'bpr_id': bprId, 'user_id': userId}));

      final result = AuthResponse.fromJson(jsonDecode(response.body));
      await clearSession();
      return result;
    } catch (_) {
      await clearSession();
      return const AuthResponse(code: '000', status: 'success', message: 'Logout berhasil');
    }
  }

  Future<void> logoutLegacySilently({required String bprId, required String userId}) async {
    try {
      await TokenInterceptor.post(
        Uri.parse(NetworkUrl.logout()),
        body: jsonEncode({'bpr_id': bprId, 'user_id': userId}),
      );
    } catch (e) {
      debugPrint('⚠️ logoutLegacySilently gagal: $e');
    }
  }

  Future<AuthResponse> logoutAgentSession() async {
    final session = await getSessionData();

    final payload = {
      'bpr_id': session['bpr_id'] ?? '',
      'username': (session['user_id'] ?? '').toString().toUpperCase(),
      'no_cif': session['no_cif'] ?? '',
      'device_id': session['device_id'] ?? '',
      'session_token': session['session_token'] ?? '',
    };

    debugPrint('🚪 SESSION LOGOUT URL: ${NetworkUrl.sessionLogout()}');
    debugPrint('🚪 SESSION LOGOUT BODY: ${jsonEncode(payload)}');

    final response = await http.post(
      Uri.parse(NetworkUrl.sessionLogout()),
      headers: {'Content-Type': 'application/json', 'api-key': NetworkUrl.apiKey, 'X-API-Key': NetworkUrl.apiKey, 'API-Key': NetworkUrl.apiKey},
      body: jsonEncode(payload),
    );

    debugPrint('🚪 SESSION LOGOUT STATUS: ${response.statusCode}');
    debugPrint('🚪 SESSION LOGOUT RESPONSE: ${response.body}');

    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> checkSessionTimeout({bool extendSession = false}) async {
    try {
      final session = await getSessionData();

      final bprId = session['bpr_id']?.toString() ?? '';
      final userId = session['user_id']?.toString() ?? '';
      final username = session['username']?.toString() ?? session['user_login']?.toString() ?? userId;

      final deviceId = session['device_id']?.toString() ?? session['login_device_id']?.toString() ?? '';

      final sessionToken = session['session_token']?.toString() ?? session['login_session_token']?.toString() ?? session['token']?.toString() ?? '';

      if (bprId.isEmpty || username.isEmpty || deviceId.isEmpty || sessionToken.isEmpty) {
        return {
          'success': false,
          'should_logout': true,
          'message': 'Session lokal tidak lengkap. Silakan login kembali.',
          'reason': 'LOCAL_SESSION_INCOMPLETE',
        };
      }

      final payload = {
        'user_id': 0,
        'username': username,
        'bpr_id': bprId,
        'device_id': deviceId,
        'session_token': sessionToken,
        'extend_session': extendSession,
      };

      debugPrint('🧭 SESSION CHECK URL: ${NetworkUrl.sessionCheck()}');
      debugPrint('🧭 SESSION CHECK BODY: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(NetworkUrl.sessionCheck()),
        headers: {'Content-Type': 'application/json', 'api-key': '123'},
        body: jsonEncode(payload),
      );

      debugPrint('🧭 SESSION CHECK STATUS: ${response.statusCode}');
      debugPrint('🧭 SESSION CHECK RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        return {'success': false, 'should_logout': false, 'message': 'HTTP ${response.statusCode}', 'reason': 'HTTP_ERROR'};
      }

      final jsonData = jsonDecode(response.body);
      final data = jsonData['data'];

      final code = jsonData['code']?.toString() ?? '';
      final shouldLogout = data is Map ? data['should_logout'] == true : code == '401';

      return {
        'success': code == '000',
        'should_logout': shouldLogout,
        'message': jsonData['message']?.toString() ?? '',
        'reason': data is Map ? data['reason']?.toString() ?? '' : '',
        'data': data,
      };
    } catch (e) {
      debugPrint('❌ checkSessionTimeout error: $e');

      return {'success': false, 'should_logout': false, 'message': 'Gagal mengecek session: $e', 'reason': 'EXCEPTION'};
    }
  }

  Future<AuthResponse> logoutCurrentSession() async {
    final session = await getSessionData();

    final bprId = session['bpr_id']?.toString() ?? '';
    final userId = session['user_id']?.toString() ?? session['username']?.toString() ?? session['user_login']?.toString() ?? '';

    if (bprId.isEmpty || userId.isEmpty) {
      await clearSession();

      return const AuthResponse(code: '000', status: 'success', message: 'Session lokal dibersihkan');
    }

    final result = await logout(bprId: bprId, userId: userId);

    await clearSession();

    return result;
  }

  // ── GANTI PASSWORD ─────────────────────────────────────────────────────────
  Future<AuthResponse> changePassword({
    required String bprId,
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await TokenInterceptor.post(
      Uri.parse(NetworkUrl.changePassword()),
      body: jsonEncode({'bpr_id': bprId, 'user_id': userId, 'old_password': oldPassword, 'new_password': newPassword}),
    );

    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  // ── SESSION ────────────────────────────────────────────────────────────────
  Future<void> _saveSession({
    required String token,
    required String userId,
    required String noCif,
    required String nama,
    required String bprId,
    required String deviceId,
    required String sessionToken,
    required String roleUser,
    required String jabatan,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_noCifKey, noCif);
    await prefs.setString(_namaKey, nama);
    await prefs.setString(_bprIdKey, bprId);
    await prefs.setString(_deviceIdKey, deviceId);
    await prefs.setString(_sessionTokenKey, sessionToken);
    await prefs.setString(_roleUserKey, roleUser);
    await prefs.setString(_jabatanKey, jabatan);

    debugPrint('✅ SESSION SAVED: user_id=$userId, role_user=$roleUser, jabatan=$jabatan');
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_noCifKey);
    await prefs.remove(_namaKey);
    await prefs.remove(_bprIdKey);
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_roleUserKey);
    await prefs.remove(_jabatanKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'token': prefs.getString(_tokenKey) ?? '',
      'session_token': prefs.getString(_sessionTokenKey) ?? '',
      'user_id': prefs.getString(_userIdKey) ?? '',
      'username': prefs.getString(_userIdKey) ?? '',
      'no_cif': prefs.getString(_noCifKey) ?? '',
      'nama': prefs.getString(_namaKey) ?? '',
      'bpr_id': prefs.getString(_bprIdKey) ?? '',
      'device_id': prefs.getString(_deviceIdKey) ?? '',
      'role_user': prefs.getString(_roleUserKey) ?? '',
      'jabatan': prefs.getString(_jabatanKey) ?? '',
    };
  }

  Future<Map<String, dynamic>> startSession({
    required String bprId,
    required String username,
    required String noCif,
    required String deviceId,
    required String deviceName,
    required String sessionToken,
    required String roleUser,
    required String jabatan,
  }) async {
    try {
      final payload = {
        'bpr_id': bprId,
        'username': username.trim().toUpperCase(),
        'no_cif': noCif.trim(),
        'device_id': deviceId.trim(),
        'device_name': deviceName.trim(),
        'session_token': sessionToken.trim(),
        'role_user': roleUser.trim(),
        'jabatan': jabatan.trim(),
      };

      debugPrint('🚀 SESSION START URL: ${NetworkUrl.sessionStart()}');
      debugPrint('🚀 SESSION START BODY: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(NetworkUrl.sessionStart()),
        headers: {'Content-Type': 'application/json', 'api-key': NetworkUrl.apiKey, 'X-API-Key': NetworkUrl.apiKey, 'API-Key': NetworkUrl.apiKey},
        body: jsonEncode(payload),
      );

      debugPrint('🚀 SESSION START STATUS: ${response.statusCode}');
      debugPrint('🚀 SESSION START RESPONSE: ${response.body}');

      final jsonData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 && jsonData['code']?.toString() == '000',
        'code': jsonData['code']?.toString() ?? '',
        'message': jsonData['message']?.toString() ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      debugPrint('❌ startSession error: $e');

      return {'success': false, 'code': 'EXCEPTION', 'message': 'Gagal memulai session: $e', 'data': null};
    }
  }
}
