import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/bpr_profile_model.dart';
import '../network/network.dart';

class BprService {
  Future<List<BprProfile>> getActiveBprProfiles() async {
    final uri = Uri.parse(NetworkUrl.getBprProfile());
    final payload = <String, dynamic>{'action': 'list'};

    debugPrint('🏦 BPR LIST URL: $uri');
    debugPrint('🏦 BPR LIST BODY: ${jsonEncode(payload)}');

    final response = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    debugPrint('🏦 BPR LIST STATUS: ${response.statusCode}');
    debugPrint('🏦 BPR LIST RESPONSE: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil daftar BPR. HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response daftar BPR tidak valid');
    }

    final code = decoded['code']?.toString() ?? '';
    if (code != '000') {
      throw Exception(
        decoded['message']?.toString() ?? 'Gagal mengambil daftar BPR',
      );
    }

    final rawData = decoded['data'];
    if (rawData is! List) {
      throw Exception('Data daftar BPR tidak tersedia');
    }

    final uniqueByBprId = <String, BprProfile>{};

    for (final item in rawData) {
      if (item is! Map) continue;

      final profile = BprProfile.fromJson(
        Map<String, dynamic>.from(item),
      );

      if (!profile.isActive ||
          profile.bprId.isEmpty ||
          profile.namaBpr.isEmpty) {
        continue;
      }

      uniqueByBprId[profile.bprId] = profile;
    }

    final profiles = uniqueByBprId.values.toList()
      ..sort(
        (a, b) => a.namaBpr.toLowerCase().compareTo(
              b.namaBpr.toLowerCase(),
            ),
      );

    return profiles;
  }
}
