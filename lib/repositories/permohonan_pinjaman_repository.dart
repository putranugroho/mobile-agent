// lib/repositories/permohonan_pinjaman_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network.dart';
import '../models/permohonan_pinjaman_model.dart';
import '../models/jaminan_model.dart';
import '../services/token_interceptor.dart';

class PengajuanRepository {
  Future<String> _getUserHandle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }

  Future<String> _getRoleUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role_user') ?? '';
  }

  Future<String> _getUserHandleForInquiry() async {
    final userHandle = await _getUserHandle();
    final roleUser = await _getRoleUser();

    // role_user 1 = pejabat, lihat semua permohonan
    if (roleUser == '1') {
      return '';
    }

    // role_user 2 = petugas, filter sesuai user_handle login
    if (roleUser == '2') {
      return userHandle;
    }

    // fallback paling aman: filter by user sendiri
    return userHandle;
  }

  Future<String> _getBprId() async {
    final prefs = await SharedPreferences.getInstance();
    final bprId = prefs.getString('bpr_id')?.trim() ?? '';

    if (bprId.isEmpty) {
      throw StateError(
        'BPR ID tidak ditemukan pada session. Silakan login kembali.',
      );
    }

    return bprId;
  }

  Future<List<PengajuanModel>> _getAllPengajuan() async {
    try {
      final userHandle = await _getUserHandleForInquiry();
      final bprId = await _getBprId();

      final requestBody = {
        'bpr_id': bprId,
        'filter': {
          'status': '',
          'nama': '',
          'no_hp': '',
          'user_handle': userHandle,
          'nilai_pinjaman': {'min': 0, 'max': 0},
          'jk_waktu': 0,
          'created_at': {'from': '', 'to': ''},
        },
        'pagination': {'page': 1, 'limit': 100},
        'sort': {'by': 'created_at', 'order': 'desc'},
      };

      final response = await TokenInterceptor.post(Uri.parse(NetworkUrl.getPengajuan()), body: jsonEncode(requestBody));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['code'] == '000') {
          final List<dynamic> dataList = jsonData['data']?['data'] ?? [];
          return dataList.map((item) => PengajuanModel.fromJson(item)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Gagal memuat data');
        }
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<PengajuanModel>> getPengajuan() async {
    final allData = await _getAllPengajuan();
    final roleUser = await _getRoleUser();

    return allData.where((item) {
      final status = item.status.toString().trim();

      // Pejabat / role_user 1:
      // tampilkan permohonan baru dan yang sedang proses
      if (roleUser == '1') {
        return status == '0' || status == '1';
      }

      // Petugas / role_user 2:
      // hanya tampilkan yang sudah masuk proses / ditugaskan
      if (roleUser == '2') {
        return status == '1';
      }

      // fallback aman
      return status == '1';
    }).toList();
  }

  Future<List<PengajuanModel>> getHistori() async {
    final allData = await _getAllPengajuan();
    return allData.where((item) => item.status == '2' || item.status == '3').toList();
  }

  Future<List<JaminanModel>> getAllJaminan() async {
    try {
      final bprId = await _getBprId();

      final requestBody = {'bpr_id': bprId, 'user_login': 'system', 'term': 'WEB'};

      final response = await http.post(Uri.parse(NetworkUrl.getJaminanAll()), headers: NetworkUrl.jsonHeaders(), body: jsonEncode(requestBody));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['code'] == '000') {
          final List<dynamic> dataList = jsonData['data'] ?? [];
          return dataList.map((item) => JaminanModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String?> getBprLogoFilename(String bprId) async {
    try {
      final requestBody = {'action': 'detail', 'bpr_id': bprId};

      final response = await http.post(Uri.parse(NetworkUrl.getBprProfile()), headers: NetworkUrl.jsonHeaders(), body: jsonEncode(requestBody));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['code'] == '000') {
          return jsonData['data']?['logo_bpr']?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateStatus({
    required String noId,
    required String noHp,
    required String status,
    required String alasan,
    required String tglKeputusan,
  }) async {
    try {
      final bprId = await _getBprId();
      final userHandle = await _getUserHandle();

      final requestBody = {
        'bpr_id': bprId,
        'no_id': noId,
        'no_hp': noHp,
        'alasan': alasan,
        'status': status,
        'user_login': userHandle,
        'term': 'WEB',
        'user_handle': userHandle,
        'tgl_keputusan': tglKeputusan,
      };

      final response = await TokenInterceptor.post(Uri.parse(NetworkUrl.updateStatus()), body: jsonEncode(requestBody));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['code'] == '000';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
