class BprProfile {
  final int? id;
  final String bprId;
  final String namaBpr;
  final String alamat;
  final String logoBpr;
  final bool isActive;

  const BprProfile({
    required this.id,
    required this.bprId,
    required this.namaBpr,
    required this.alamat,
    required this.logoBpr,
    required this.isActive,
  });

  factory BprProfile.fromJson(Map<String, dynamic> json) {
    return BprProfile(
      id: _parseInt(json['id']),
      bprId: json['bpr_id']?.toString().trim() ?? '',
      namaBpr: json['nama_bpr']?.toString().trim() ?? '',
      alamat: json['alamat']?.toString().trim() ?? '',
      logoBpr: json['logo_bpr']?.toString().trim() ?? '',
      isActive: _parseBool(json['is_active']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'y' ||
        normalized == 'yes';
  }
}
