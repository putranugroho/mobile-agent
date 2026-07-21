// lib/repositories/permohonan_pinjaman_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Apakah user yang sedang login berperan sebagai Pejabat (role_user='1').
  /// Dipakai untuk membatasi aksi Setuju/Tolak -- SAMA seperti aturan di
  /// CMS Medfo (lihat komentar "TOMBOL HANYA UNTUK PETUGAS, PEJABAT TIDAK
  /// BISA" di permohonan_pinjaman_page.dart): Pejabat cuma boleh MELIHAT
  /// semua pengajuan, keputusan Setuju/Tolak tetap wewenang petugas
  /// (role_user='2') yang ditugaskan.
  Future<bool> isPejabat() async {
    final role = await _getRoleUser();
    return role.trim() == '1';
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
    String noCif = '',
    String nama = '',
    String nilaiPinjaman = '',
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

      if (response.statusCode != 200) return false;
      final jsonData = jsonDecode(response.body);
      final success = jsonData['code'] == '000';

      // Update status di atas SUDAH SELESAI (berhasil/gagal) pada titik
      // ini. Kirim notif ke nasabah SEBAGAI LANGKAH TERPISAH, bukan bagian
      // dari sukses/gagalnya updateStatus -- kalau notif gagal, itu TIDAK
      // BOLEH bikin admin/petugas mengira update status-nya sendiri gagal
      // (padahal sudah berhasil di server), sama seperti pola yang sudah
      // diterapkan di CMS & mobile-info untuk kasus serupa.
      if (success && noCif.trim().isNotEmpty) {
        await _notifyNasabah(bprId: bprId, noCif: noCif, status: status, nama: nama, nilaiPinjaman: nilaiPinjaman);
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Kirim notif ke nasabah saat petugas memproses pengajuan lewat
  /// mobile-agent -- judul & isi pesan disamakan PERSIS dengan
  /// notifyBorrower di CMS Medfo (permohonan_pinjaman_repository.dart),
  /// supaya nasabah menerima pesan yang konsisten dari mana pun
  /// pengajuannya diproses. Sebelumnya updateStatus() di sini TIDAK
  /// mengirim notif sama sekali -- nasabah cuma diberi tahu kalau
  /// pengajuannya diproses lewat CMS, tidak kalau diproses langsung oleh
  /// petugas di lapangan lewat mobile-agent.
  ///
  /// Fire-and-forget: kegagalan di sini TIDAK dilempar sebagai exception
  /// ke pemanggil (lihat updateStatus di atas).
  Future<void> _notifyNasabah({
    required String bprId,
    required String noCif,
    required String status,
    required String nama,
    required String nilaiPinjaman,
  }) async {
    try {
      String title;
      String body;
      switch (status) {
        case '2':
          title = "Permohonan Pinjaman Disetujui";
          body = "Selamat $nama, permohonan pinjaman Anda sebesar Rp $nilaiPinjaman dapat DIPROSES. Silakan menunggu informasi selanjutnya dari petugas kami.";
          break;
        case '3':
          title = "Permohonan Pinjaman Ditolak";
          body = "Mohon maaf $nama, permohonan pinjaman Anda sebesar Rp $nilaiPinjaman belum dapat kami setujui. Silakan hubungi petugas kami untuk informasi lebih lanjut.";
          break;
        default:
          title = "Update Permohonan Pinjaman";
          body = "Halo $nama, status permohonan pinjaman Anda telah diperbarui.";
      }

      final payload = {
        "bpr_id": bprId,
        "no_cif": noCif,
        "title": title,
        "body": body,
      };

      final response = await TokenInterceptor.post(Uri.parse(NetworkUrl.pushNotif()), body: jsonEncode(payload));

      if (response.statusCode != 200) {
        debugPrint('⚠️ Notif ke nasabah (CIF=$noCif) gagal: HTTP ${response.statusCode}');
        return;
      }
      final jsonData = jsonDecode(response.body);
      if (jsonData['code'] != '000') {
        debugPrint('⚠️ Notif ke nasabah (CIF=$noCif) ditolak backend: ${jsonData['message']}');
      }
    } catch (e) {
      debugPrint('⚠️ Notif ke nasabah (CIF=$noCif) exception: $e');
    }
  }
}
