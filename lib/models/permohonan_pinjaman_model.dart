// lib/models/permohonan_pinjaman_model.dart
class PengajuanModel {
  final String noCif;
  final String noId;
  final String nama;
  final String noHp;
  final String alamat;
  final String kdJaminan;
  final String nilaiPinjaman;
  final String jkWaktu;
  final String rate;
  final String cicilanPerbulan;
  final String status;
  final String tglinput;
  final String tglproses;
  final String tglkeputusan;
  final String userHandle;
  final String alasan;
  final String fhotojaminan;
  final String kdKantor;

  PengajuanModel({
    required this.noCif,
    required this.noId,
    required this.nama,
    required this.noHp,
    required this.alamat,
    required this.kdJaminan,
    required this.nilaiPinjaman,
    required this.jkWaktu,
    required this.rate,
    required this.cicilanPerbulan,
    required this.status,
    required this.tglinput,
    required this.tglproses,
    required this.tglkeputusan,
    required this.userHandle,
    required this.alasan,
    this.fhotojaminan = '',
    this.kdKantor = '',
  });

  factory PengajuanModel.fromJson(Map<String, dynamic> json) {
    return PengajuanModel(
      // Backend mobile-agent response memakai "cif"
      // Beberapa endpoint lain bisa memakai "no_cif"
      noCif: json['cif']?.toString() ?? json['no_cif']?.toString() ?? json['nocif']?.toString() ?? '',

      noId: json['no_id']?.toString() ?? json['no_identitas']?.toString() ?? '',

      nama: json['nama']?.toString() ?? '',
      noHp: json['no_hp']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',

      // Beberapa response bisa memakai "jaminan", "kd_jaminan", atau "kdJaminan"
      kdJaminan: json['jaminan']?.toString() ?? json['kd_jaminan']?.toString() ?? json['kdJaminan']?.toString() ?? '',

      nilaiPinjaman: json['nilai_pinjaman']?.toString() ?? json['nominal']?.toString() ?? '0',

      jkWaktu: json['jk_waktu']?.toString() ?? json['jangka_waktu']?.toString() ?? '0',

      rate: json['rate']?.toString() ?? json['suku_bunga']?.toString() ?? '0',

      cicilanPerbulan: json['cicilan_perbulan']?.toString() ?? json['cicilan']?.toString() ?? '0',

      status: json['status']?.toString() ?? '',
      tglinput: json['tgl_input']?.toString() ?? json['created_at']?.toString() ?? '',
      tglproses: json['tgl_proses']?.toString() ?? '',
      tglkeputusan: json['tgl_keputusan']?.toString() ?? '',
      userHandle: json['user_handle']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
      fhotojaminan: json['fhoto_jaminan']?.toString() ?? '',
      kdKantor: json['kd_kantor']?.toString() ?? json['kdKantor']?.toString() ?? '',
    );
  }
}
