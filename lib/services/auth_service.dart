// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_model.dart';
import '../network/network.dart';

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
  static const String _installationDeviceIdKey =
      'mobile_agent_device_id';

  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _defaultDeviceName = 'Mobile Agent Android';

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toUpperCase();

    if (normalizedUsername.isEmpty) {
      return const LoginResponse(
        code: '001',
        status: 'error',
        message: 'Username wajib diisi.',
      );
    }

    if (password.isEmpty) {
      return const LoginResponse(
        code: '001',
        status: 'error',
        message: 'Password wajib diisi.',
      );
    }

    final deviceId = await getOrCreateDeviceId();
    final fcmToken = await getFcmToken();

    final json = await _postJson(
      NetworkUrl.login(),
      {
        'username': normalizedUsername,
        'password': password,
        'device_id': deviceId,
        'device_name': _defaultDeviceName,
        'fcm_token': fcmToken,
      },
      logLabel: 'LOGIN',
    );

    final result = LoginResponse.fromJson(json);

    if (!result.isSuccess) return result;

    final user = result.user;
    final token = result.token ?? result.sessionToken ?? '';
    final sessionToken = result.sessionToken ?? result.token ?? '';

    if (user == null || token.isEmpty || sessionToken.isEmpty) {
      return const LoginResponse(
        code: 'SESSION_ERROR',
        status: 'error',
        message:
            'Login berhasil, tetapi response session tidak lengkap. Silakan login kembali.',
      );
    }

    if (user.bprId.isEmpty || user.userId.isEmpty) {
      return const LoginResponse(
        code: 'SESSION_ERROR',
        status: 'error',
        message:
            'Login berhasil, tetapi identitas user tidak lengkap. Silakan hubungi administrator.',
      );
    }

    await _saveSession(
      token: token,
      userId: user.userId,
      noCif: user.noCif.isEmpty ? user.userId : user.noCif,
      nama: user.nama.isEmpty ? user.userId : user.nama,
      bprId: user.bprId,
      deviceId: deviceId,
      sessionToken: sessionToken,
      roleUser: user.roleUser ?? '',
      jabatan: user.jabatan ?? '',
    );

    return result;
  }

  // ── AKTIVASI ───────────────────────────────────────────────────────────────
  Future<AuthResponse> requestActivationOtp({
    required String bprId,
    required String username,
    required String phone,
  }) async {
    final validation = _validateIdentity(
      bprId: bprId,
      username: username,
      phone: phone,
    );
    if (validation != null) return validation;

    final deviceId = await getOrCreateDeviceId();
    final json = await _postJson(
      NetworkUrl.activationRequestOtp(),
      {
        'bpr_id': bprId.trim(),
        'username': username.trim().toUpperCase(),
        'phone': phone.trim(),
        'device_id': deviceId,
        'device_name': _defaultDeviceName,
      },
      logLabel: 'ACTIVATION_REQUEST_OTP',
    );

    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> verifyActivationOtp({
    required String challengeToken,
    required String otp,
  }) async {
    if (challengeToken.trim().isEmpty || otp.trim().isEmpty) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Challenge token dan OTP wajib diisi.',
      );
    }

    final json = await _postJson(
      NetworkUrl.activationVerifyOtp(),
      {
        'challenge_token': challengeToken.trim(),
        'otp': otp.trim(),
      },
      logLabel: 'ACTIVATION_VERIFY_OTP',
    );

    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> submitActivation({
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final validation = _validateNewPassword(
      newPassword,
      confirmPassword,
    );
    if (validation != null) return validation;

    final json = await _postJson(
      NetworkUrl.activationSubmit(),
      {
        'verification_token': verificationToken.trim(),
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      logLabel: 'ACTIVATION_SUBMIT',
    );

    return AuthResponse.fromJson(json);
  }

  // ── LUPA SANDI ─────────────────────────────────────────────────────────────
  Future<AuthResponse> requestForgotPasswordOtp({
    required String bprId,
    required String username,
    required String phone,
  }) async {
    final validation = _validateIdentity(
      bprId: bprId,
      username: username,
      phone: phone,
    );
    if (validation != null) return validation;

    final deviceId = await getOrCreateDeviceId();
    final json = await _postJson(
      NetworkUrl.forgotPasswordRequestOtp(),
      {
        'bpr_id': bprId.trim(),
        'username': username.trim().toUpperCase(),
        'phone': phone.trim(),
        'device_id': deviceId,
        'device_name': _defaultDeviceName,
      },
      logLabel: 'FORGOT_PASSWORD_REQUEST_OTP',
    );

    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> verifyForgotPasswordOtp({
    required String challengeToken,
    required String otp,
  }) async {
    if (challengeToken.trim().isEmpty || otp.trim().isEmpty) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Challenge token dan OTP wajib diisi.',
      );
    }

    final json = await _postJson(
      NetworkUrl.forgotPasswordVerifyOtp(),
      {
        'challenge_token': challengeToken.trim(),
        'otp': otp.trim(),
      },
      logLabel: 'FORGOT_PASSWORD_VERIFY_OTP',
    );

    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> resetForgotPassword({
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final validation = _validateNewPassword(
      newPassword,
      confirmPassword,
    );
    if (validation != null) return validation;

    final json = await _postJson(
      NetworkUrl.forgotPasswordReset(),
      {
        'verification_token': verificationToken.trim(),
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      logLabel: 'FORGOT_PASSWORD_RESET',
    );

    return AuthResponse.fromJson(json);
  }

  // ── GANTI PASSWORD ─────────────────────────────────────────────────────────
  Future<AuthResponse> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (oldPassword.isEmpty) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Password lama wajib diisi.',
      );
    }

    final validation = _validateNewPassword(
      newPassword,
      confirmPassword,
      oldPassword: oldPassword,
    );
    if (validation != null) return validation;

    final session = await getSessionData();
    final deviceId = session['device_id'] ?? '';
    final sessionToken = session['session_token'] ?? '';

    if (deviceId.isEmpty || sessionToken.isEmpty) {
      return const AuthResponse(
        code: '401',
        status: 'error',
        message: 'Session tidak tersedia. Silakan login kembali.',
      );
    }

    final json = await _postJson(
      NetworkUrl.changePassword(),
      {
        'device_id': deviceId,
        'session_token': sessionToken,
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      logLabel: 'CHANGE_PASSWORD',
    );

    final result = AuthResponse.fromJson(json);
    if (result.isSuccess) {
      await clearSession();
    }
    return result;
  }

  // ── FCM ────────────────────────────────────────────────────────────────────
  Future<String> getFcmToken() async {
    if (kIsWeb) return '';

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      return token ?? '';
    } catch (e) {
      debugPrint('FCM token tidak tersedia: $e');
      return '';
    }
  }

  Future<AuthResponse> updateFcmToken(String fcmToken) async {
    final session = await getSessionData();
    final deviceId = session['device_id'] ?? '';
    final sessionToken = session['session_token'] ?? '';

    if (deviceId.isEmpty || sessionToken.isEmpty) {
      return const AuthResponse(
        code: '401',
        status: 'error',
        message: 'Session tidak tersedia.',
      );
    }

    final json = await _postJson(
      NetworkUrl.updateFcmToken(),
      {
        'device_id': deviceId,
        'session_token': sessionToken,
        'fcm_token': fcmToken.trim(),
      },
      logLabel: 'UPDATE_FCM',
    );

    return AuthResponse.fromJson(json);
  }

  // ── DEVICE ─────────────────────────────────────────────────────────────────
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationDeviceIdKey)?.trim() ?? '';

    if (existing.isNotEmpty) return existing;

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final newDeviceId = 'MA-$timestamp';
    await prefs.setString(_installationDeviceIdKey, newDeviceId);
    return newDeviceId;
  }

  // ── SESSION CHECK / LOGOUT ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkSessionTimeout({
    bool extendSession = false,
  }) async {
    try {
      final session = await getSessionData();
      final deviceId = session['device_id'] ?? '';
      final sessionToken = session['session_token'] ?? '';

      if (deviceId.isEmpty || sessionToken.isEmpty) {
        return {
          'success': false,
          'should_logout': true,
          'message': 'Session lokal tidak lengkap. Silakan login kembali.',
          'reason': 'LOCAL_SESSION_INCOMPLETE',
        };
      }

      final json = await _postJson(
        NetworkUrl.sessionCheck(),
        {
          'device_id': deviceId,
          'session_token': sessionToken,
          'extend_session': extendSession,
        },
        logLabel: 'SESSION_CHECK',
      );

      final code = json['code']?.toString() ?? '';
      final rawData = json['data'];
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      return {
        'success': code == '000',
        'should_logout':
            data['should_logout'] == true || code == '401' || code == '410',
        'message': json['message']?.toString() ?? '',
        'reason': data['reason']?.toString() ?? '',
        'data': data,
      };
    } catch (e) {
      debugPrint('SESSION_CHECK exception: $e');
      return {
        'success': false,
        'should_logout': false,
        'message': 'Gagal mengecek session.',
        'reason': 'EXCEPTION',
      };
    }
  }

  Future<AuthResponse> logoutCurrentSession() async {
    final session = await getSessionData();
    final deviceId = session['device_id'] ?? '';
    final sessionToken = session['session_token'] ?? '';

    if (deviceId.isEmpty || sessionToken.isEmpty) {
      await clearSession();
      return const AuthResponse(
        code: '000',
        status: 'success',
        message: 'Session lokal dibersihkan.',
      );
    }

    try {
      final json = await _postJson(
        NetworkUrl.sessionLogout(),
        {
          'device_id': deviceId,
          'session_token': sessionToken,
        },
        logLabel: 'SESSION_LOGOUT',
      );
      return AuthResponse.fromJson(json);
    } finally {
      await clearSession();
    }
  }

  Future<AuthResponse> logout() => logoutCurrentSession();

  // ── LOCAL SESSION ──────────────────────────────────────────────────────────
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

    // mobile_agent_device_id sengaja tidak dihapus karena merupakan binding
    // instalasi, bukan session login.
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

  // ── HELPERS ────────────────────────────────────────────────────────────────
  AuthResponse? _validateIdentity({
    required String bprId,
    required String username,
    required String phone,
  }) {
    if (bprId.trim().isEmpty) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'BPR wajib dipilih.',
      );
    }
    if (username.trim().isEmpty) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Username wajib diisi.',
      );
    }
    if (phone.trim().isEmpty) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Nomor HP wajib diisi.',
      );
    }
    return null;
  }

  AuthResponse? _validateNewPassword(
    String newPassword,
    String confirmPassword, {
    String? oldPassword,
  }) {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Password baru dan konfirmasi wajib diisi.',
      );
    }
    if (newPassword.length < 8) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Password baru minimal 8 karakter.',
      );
    }
    if (newPassword.length > 128) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Password baru maksimal 128 karakter.',
      );
    }
    if (newPassword != confirmPassword) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Password baru dan konfirmasi tidak sama.',
      );
    }
    if (oldPassword != null && newPassword == oldPassword) {
      return const AuthResponse(
        code: '001',
        status: 'error',
        message: 'Password baru tidak boleh sama dengan password lama.',
      );
    }
    return null;
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body, {
    required String logLabel,
  }) async {
    try {
      debugPrint('[$logLabel] POST $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: NetworkUrl.jsonHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      debugPrint('[$logLabel] HTTP ${response.statusCode}');

      if (response.body.trim().isEmpty) {
        return {
          'code': 'HTTP_${response.statusCode}',
          'status': 'error',
          'message': 'Server tidak memberikan response.',
          'data': null,
        };
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return {
          'code': 'INVALID_RESPONSE',
          'status': 'error',
          'message': 'Format response server tidak valid.',
          'data': null,
        };
      }

      final result = Map<String, dynamic>.from(decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        result.putIfAbsent(
          'code',
          () => 'HTTP_${response.statusCode}',
        );
        result.putIfAbsent('status', () => 'error');
        result.putIfAbsent(
          'message',
          () => 'Request gagal. HTTP ${response.statusCode}',
        );
      }
      return result;
    } on TimeoutException {
      return {
        'code': 'TIMEOUT',
        'status': 'error',
        'message': 'Waktu koneksi habis. Silakan coba kembali.',
        'data': null,
      };
    } on FormatException {
      return {
        'code': 'INVALID_RESPONSE',
        'status': 'error',
        'message': 'Response server tidak dapat dibaca.',
        'data': null,
      };
    } catch (e) {
      debugPrint('[$logLabel] ERROR: $e');
      return {
        'code': 'CONNECTION_ERROR',
        'status': 'error',
        'message': 'Gagal terhubung ke server. Periksa koneksi Anda.',
        'data': null,
      };
    }
  }
}
