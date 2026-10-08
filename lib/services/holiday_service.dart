// lib/services/holiday_service.dart
//
// Cek apakah hari ini hari libur untuk suatu bpr_id — dipakai oleh flow
// login supaya user tidak bisa masuk pada hari libur. Pola & endpoint
// sama persis dengan yang dipakai di aplikasi CIS.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/hari_libur_model.dart';
import '../models/jam_kerja_model.dart';
import '../network/network.dart';

class HolidayService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  // ==================== CEK HARI LIBUR ====================
  // POST {baseCmsUrl}/setup_hari_libur
  // Body: {action: "list", tahun: <tahun berjalan>}
  //
  // 3 jenis libur:
  // - libur_nasional & cuti_bersama: berlaku untuk SEMUA BPR
  // - libur_khusus: cuma berlaku untuk BPR yang ada di field bpr_ids
  //
  // Return: entri hari libur yang berlaku HARI INI untuk bprId ini, atau
  // null kalau bukan hari libur. Kalau API-nya gagal/error, dianggap BUKAN
  // hari libur (fail-open) — supaya petugas gak ke-block login gara-gara
  // API cek libur lagi down, bukan karena beneran hari libur.
  static Future<HariLiburModel?> checkHariLibur({
    required String bprId,
    DateTime? date,
  }) async {
    try {
      final checkDate = date ?? DateTime.now();
      final body = {'action': 'list', 'tahun': checkDate.year};

      final decoded = await _postJson(
        '${NetworkUrl.baseCmsUrl}/setup_hari_libur',
        body,
        logLabel: 'CEK_HARI_LIBUR',
      );
      if (decoded == null) return null;

      final code = (decoded['code'] ?? '').toString();
      if (code != '000') return null;

      final List<dynamic> raw = decoded['data'] ?? [];
      final list = raw.map((e) => HariLiburModel.fromJson(Map<String, dynamic>.from(e))).toList();

      final todayStr =
          '${checkDate.year.toString().padLeft(4, '0')}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      for (final h in list) {
        if (!h.isActive) continue;
        if (h.tanggal != todayStr) continue;
        if (h.appliesToBpr(bprId)) return h;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ERROR CEK HARI LIBUR: $e');
      return null;
    }
  }

  // ==================== CEK JAM KERJA (hari libur mingguan) ====================
  // POST {baseCmsUrl}/setup_jam_kerja
  // Body: {action: "list", bpr_id: "..."}
  //
  // Per HARI DALAM MINGGU (Senin..Minggu berulang tiap minggu), bukan
  // tanggal spesifik. Field 'hari' persis sama konvensinya dengan
  // DateTime.weekday di Dart (1=Senin..7=Minggu).
  //
  // jam_buka/jam_tutup SENGAJA diabaikan — cuma is_libur yang dipakai.
  // Fail-open juga (sama seperti checkHariLibur) kalau API-nya gagal/error.
  static Future<JamKerjaModel?> checkJamKerjaLibur({
    required String bprId,
    DateTime? date,
  }) async {
    try {
      final checkDate = date ?? DateTime.now();
      final body = {'action': 'list', 'bpr_id': bprId};

      final decoded = await _postJson(
        '${NetworkUrl.baseCmsUrl}/setup_jam_kerja',
        body,
        logLabel: 'CEK_JAM_KERJA',
      );
      if (decoded == null) return null;

      final code = (decoded['code'] ?? '').toString();
      if (code != '000') return null;

      final List<dynamic> raw = decoded['data'] ?? [];
      final list = raw.map((e) => JamKerjaModel.fromJson(Map<String, dynamic>.from(e))).toList();

      final todayWeekday = checkDate.weekday;
      for (final j in list) {
        if (j.hari == todayWeekday && j.isLibur) return j;
      }
      return null;
    } catch (e) {
      debugPrint('❌ ERROR CEK JAM KERJA: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _postJson(
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

      if (response.body.trim().isEmpty) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('[$logLabel] ERROR: $e');
      return null;
    }
  }
}
