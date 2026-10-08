// lib/models/jam_kerja_model.dart

class JamKerjaModel {
  // 1 = Senin, ..., 7 = Minggu — sama persis dengan DateTime.weekday di Dart.
  final int hari;
  final String hariNama;
  final bool isLibur;
  // Sengaja TIDAK dipakai untuk validasi login (jam_buka/jam_tutup) —
  // beberapa petugas masih ada yang lembur di luar jam kerja normal, jadi
  // jam buka/tutup gak relevan buat validasi login.
  final String jamBuka;
  final String jamTutup;

  JamKerjaModel({
    required this.hari,
    required this.hariNama,
    required this.isLibur,
    required this.jamBuka,
    required this.jamTutup,
  });

  factory JamKerjaModel.fromJson(Map<String, dynamic> json) {
    return JamKerjaModel(
      hari: json['hari'] is int ? json['hari'] : int.tryParse('${json['hari']}') ?? 0,
      hariNama: (json['hari_nama'] ?? '').toString(),
      isLibur: json['is_libur'] == true,
      jamBuka: (json['jam_buka'] ?? '').toString(),
      jamTutup: (json['jam_tutup'] ?? '').toString(),
    );
  }
}
