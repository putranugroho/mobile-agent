class NetworkUrl {
  /// API key web_service (sama dengan API_KEY di .env Go, default "123").
  static const String apiKey = String.fromEnvironment('GW_MEDFO_API_KEY', defaultValue: '123');

  /// Override base URL web_service: --dart-define=WS_BASE_URL=http://host:4002
  static const String _wsBaseUrlOverride = String.fromEnvironment('WS_BASE_URL', defaultValue: '');

  // Base URL
  static const String baseUrl = 'https://api-dev-medfo.medtrans.id';
  static String get baseAuthUrl {
    final override = _wsBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;
    return 'https://web-service-medfo.medtrans.id';
  }

  static const String baseCmsUrl = 'https://api-dev-cms.medtrans.id';
  static const String baseCmsIp = 'http://103.129.149.131:8090';

  static Map<String, String> jsonHeaders() => {'Content-Type': 'application/json', 'X-API-Key': apiKey};

  // Auth Petugas Endpoints
  static String login() => '$baseAuthUrl/petugas/login';
  static String updateFcmToken() => '$baseUrl/mobile-agent/fcm-token/update';
  static String logout() => '$baseAuthUrl/petugas/logout';
  static String sessionStart() => '$baseUrl/mobile-agent/session/start';
  static String sessionCheck() => '$baseUrl/mobile-agent/session/check';
  static String changePassword() => '$baseAuthUrl/petugas/change-password';

  // Endpoints
  static String getPengajuan() => '$baseAuthUrl/permohonan-pinjaman/inquiry';
  static String updateStatus() => '$baseAuthUrl/permohonan-pinjaman/update-status';
  static String getJaminan() => '$baseUrl/inquiry/jaminan-by-kd-jaminan';
  static String getJaminanAll() => '$baseUrl/inquiry/jaminan-all';

  // BPR Profile
  static String getBprProfile() => '$baseCmsIp/bpr_profile';

  // Photo viewer
  static String getLogoBpr(String file) => '$baseCmsUrl/photo/view?type=logo_bpr&file=$file';
}
