class NetworkUrl {
  /// API key medfo-go (sama dengan API_KEY di environment backend).
  static const String apiKey = String.fromEnvironment(
    'GW_MEDFO_API_KEY',
    defaultValue: '123',
  );

  /// Override web-service operasional lama bila diperlukan.
  static const String _wsBaseUrlOverride = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: '',
  );

  /// Override medfo-go untuk development/local testing.
  static const String _medfoBaseUrlOverride = String.fromEnvironment(
    'MEDFO_BASE_URL',
    defaultValue: '',
  );

  static const String _defaultMedfoBaseUrl =
      'https://api-dev-medfo.medtrans.id';

  static String get baseUrl {
    final override = _medfoBaseUrlOverride.trim();
    return override.isNotEmpty ? override : _defaultMedfoBaseUrl;
  }

  static String get baseAuthUrl {
    final override = _wsBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;
    return 'https://web-service-medfo.medtrans.id';
  }

  static const String baseCmsUrl = 'https://api-dev-cms.medtrans.id';
  static const String baseCmsIp = 'http://103.129.149.131:8090';

  static Map<String, String> jsonHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': apiKey,
        'api-key': apiKey,
      };

  // Mobile Agent Authentication
  static String login() => '$baseUrl/mobile-agent/login';

  static String activationRequestOtp() =>
      '$baseUrl/mobile-agent/aktivasi/request-otp';
  static String activationVerifyOtp() =>
      '$baseUrl/mobile-agent/aktivasi/verify-otp';
  static String activationSubmit() =>
      '$baseUrl/mobile-agent/aktivasi/submit';

  static String forgotPasswordRequestOtp() =>
      '$baseUrl/mobile-agent/password/forgot/request-otp';
  static String forgotPasswordVerifyOtp() =>
      '$baseUrl/mobile-agent/password/forgot/verify-otp';
  static String forgotPasswordReset() =>
      '$baseUrl/mobile-agent/password/forgot/reset';
  static String changePassword() =>
      '$baseUrl/mobile-agent/password/change';

  static String updateFcmToken() =>
      '$baseUrl/mobile-agent/fcm-token/update';
  static String sessionCheck() => '$baseUrl/mobile-agent/session/check';
  static String sessionLogout() => '$baseUrl/mobile-agent/session/logout';


  // Endpoints operasional yang masih berada di web-service lama.
  static String getPengajuan() =>
      '$baseAuthUrl/permohonan-pinjaman/inquiry';
  static String updateStatus() =>
      '$baseAuthUrl/permohonan-pinjaman/update-status';
  static String getJaminan() =>
      '$baseUrl/inquiry/jaminan-by-kd-jaminan';
  static String getJaminanAll() => '$baseUrl/inquiry/jaminan-all';

  // BPR Profile
  static String getBprProfile() => '$baseCmsUrl/bpr_profile';

  // Photo viewer
  static String getLogoBpr(String file) =>
      '$baseCmsUrl/photo/view?type=logo_bpr&file=$file';
}
