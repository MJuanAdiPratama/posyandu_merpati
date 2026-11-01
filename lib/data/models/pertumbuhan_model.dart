class PertumbuhanModel {
  final String id;
  final String balitaId;
  final DateTime tanggalPemeriksaan;
  final int usiaBulan;
  final double beratBadan;
  final double tinggiBadan;
  final double? lingkarKepala;
  final String? statusGizi;
  final String? statusTinggiBadan;
  final String? statusBeratBadan;
  final String? statusPertumbuhan;
  final String? catatan;
  final DateTime createdAt;

  PertumbuhanModel({
    required this.id,
    required this.balitaId,
    required this.tanggalPemeriksaan,
    required this.usiaBulan,
    required this.beratBadan,
    required this.tinggiBadan,
    this.lingkarKepala,
    this.statusGizi,
    this.statusTinggiBadan,
    this.statusBeratBadan,
    this.statusPertumbuhan,
    this.catatan,
    required this.createdAt,
  });

  factory PertumbuhanModel.fromJson(Map<String, dynamic> json) {
    return PertumbuhanModel(
      id: json['id'] as String,
      balitaId: json['balita_id'] as String,
      tanggalPemeriksaan: DateTime.parse(json['tanggal_pemeriksaan'] as String),
      usiaBulan: (json['usia_bulan'] as int?) ?? 0,
      beratBadan: (json['berat_badan'] as num?)?.toDouble() ?? 0.0,
      tinggiBadan: (json['tinggi_badan'] as num?)?.toDouble() ?? 0.0,
      lingkarKepala: (json['lingkar_kepala'] as num?)?.toDouble(),
      statusGizi: json['status_gizi'] as String?,
      statusTinggiBadan: json['status_tinggi_badan'] as String?,
      statusBeratBadan: json['status_berat_badan'] as String?,
      statusPertumbuhan: json['status_pertumbuhan'] as String?,
      catatan: json['catatan'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balita_id': balitaId,
      'tanggal_pemeriksaan':
          '${tanggalPemeriksaan.year}-${tanggalPemeriksaan.month.toString().padLeft(2, '0')}-${tanggalPemeriksaan.day.toString().padLeft(2, '0')}',
      'usia_bulan': usiaBulan,
      'berat_badan': beratBadan,
      'tinggi_badan': tinggiBadan,
      'lingkar_kepala': lingkarKepala,
      'status_gizi': statusGizi,
      'status_tinggi_badan': statusTinggiBadan,
      'status_berat_badan': statusBeratBadan,
      'status_pertumbuhan': statusPertumbuhan,
      'catatan': catatan,
    };
  }
}
