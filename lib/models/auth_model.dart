// lib/models/auth_model.dart

class UserModel {
  final String userId;
  final String noCif;
  final String nama;
  final String noHp;
  final String kdKantor;
  final String bprId;
  final String stsUser;
  final String? roleUser;
  final String? jabatan;

  const UserModel({
    required this.userId,
    required this.noCif,
    required this.nama,
    required this.noHp,
    required this.kdKantor,
    required this.bprId,
    required this.stsUser,
    this.roleUser,
    this.jabatan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userId = _stringValue(
      json['user_id'] ?? json['username'] ?? json['userid'],
    );

    return UserModel(
      userId: userId,
      noCif: _stringValue(json['no_cif'], fallback: userId),
      nama: _stringValue(json['nama'], fallback: userId),
      noHp: _stringValue(json['no_hp'] ?? json['phone']),
      kdKantor: _stringValue(json['kd_kantor']),
      bprId: _stringValue(json['bpr_id']),
      stsUser: _stringValue(
        json['sts_user'] ?? json['status_aktif'],
      ),
      roleUser: _stringValue(json['role_user']),
      jabatan: _stringValue(json['jabatan']),
    );
  }
}

class LoginResponse {
  final String code;
  final String status;
  final String message;
  final String? token;
  final String? sessionToken;
  final String? loginExpiredAt;
  final UserModel? user;

  const LoginResponse({
    required this.code,
    required this.status,
    required this.message,
    this.token,
    this.sessionToken,
    this.loginExpiredAt,
    this.user,
  });

  bool get isSuccess => code == '000';

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = _mapValue(json['data']);
    final rawUser = data?['user'] ?? json['user'];
    final userMap = _mapValue(rawUser);

    final token = _nullableString(
      data?['token'] ?? json['token'] ?? data?['session_token'],
    );
    final sessionToken = _nullableString(
      data?['session_token'] ?? json['session_token'] ?? token,
    );

    return LoginResponse(
      code: _stringValue(json['code']),
      status: _normalizeStatus(json['status']),
      message: _stringValue(json['message']),
      token: token,
      sessionToken: sessionToken,
      loginExpiredAt: _nullableString(data?['login_expired_at']),
      user: userMap == null ? null : UserModel.fromJson(userMap),
    );
  }
}

class AuthResponse {
  final String code;
  final String status;
  final String message;
  final Map<String, dynamic>? data;

  const AuthResponse({
    required this.code,
    required this.status,
    required this.message,
    this.data,
  });

  bool get isSuccess => code == '000';

  String get challengeToken =>
      _stringValue(data?['challenge_token']);

  String get verificationToken =>
      _stringValue(data?['verification_token']);

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      code: _stringValue(json['code']),
      status: _normalizeStatus(json['status']),
      message: _stringValue(json['message']),
      data: _mapValue(json['data']),
    );
  }
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

String? _nullableString(dynamic value) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? null : result;
}

String _normalizeStatus(dynamic value) {
  if (value is bool) return value ? 'success' : 'error';
  return value?.toString() ?? '';
}
