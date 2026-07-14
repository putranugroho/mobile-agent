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

  // Response login petugas: user_id, no_cif, nama, no_hp, kd_kantor, bpr_id, sts_user
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      noCif: json['no_cif'] ?? '',
      nama: json['nama'] ?? '',
      noHp: json['no_hp'] ?? '',
      kdKantor: json['kd_kantor'] ?? '',
      bprId: json['bpr_id'] ?? '',
      stsUser: json['sts_user'] ?? '',
      roleUser: json['role_user']?.toString() ?? '',
      jabatan: json['jabatan']?.toString() ?? '',
    );
  }
}

class LoginResponse {
  final String code;
  final String status;
  final String message;
  final String? token;
  final UserModel? user;

  const LoginResponse({required this.code, required this.status, required this.message, this.token, this.user});

  bool get isSuccess => code == '000';

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return LoginResponse(
      code: json['code'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      token: data?['token'],
      user: data?['user'] != null ? UserModel.fromJson(data!['user']) : null,
    );
  }
}

class AuthResponse {
  final String code;
  final String status;
  final String message;

  const AuthResponse({required this.code, required this.status, required this.message});

  bool get isSuccess => code == '000';

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];

    return AuthResponse(
      code: json['code']?.toString() ?? '',
      status: rawStatus is bool ? (rawStatus ? 'success' : 'error') : rawStatus?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
