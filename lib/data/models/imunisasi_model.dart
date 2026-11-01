class ImunisasiModel {
  final String id;
  final String balitaId;
  final String? jenisImunisasiId;
  final DateTime tanggalImunisasi;
  final double? beratBadan;
  final double? tinggiBadan;
  final double? suhuBadan;
  final double? lingkarKepala;
  final String? catatan;
  final String? petugasId;
  final DateTime createdAt;

  // Relasi (join)
  final String? namaImunisasi;
  final String? namaBalita;
  final String? namaPetugas;

  ImunisasiModel({
    required this.id,
    required this.balitaId,
    this.jenisImunisasiId,
    required this.tanggalImunisasi,
    this.beratBadan,
    this.tinggiBadan,
    this.suhuBadan,
    this.lingkarKepala,
    this.catatan,
    this.petugasId,
    required this.createdAt,
    this.namaImunisasi,
    this.namaBalita,
    this.namaPetugas,
  });

  factory ImunisasiModel.fromJson(Map<String, dynamic> json) {
    return ImunisasiModel(
      id: json['id'] as String,
      balitaId: json['balita_id'] as String,
      jenisImunisasiId: json['jenis_imunisasi_id'] as String?,
      tanggalImunisasi: DateTime.parse(json['tanggal_imunisasi'] as String),
      beratBadan: (json['berat_badan'] as num?)?.toDouble(),
      tinggiBadan: (json['tinggi_badan'] as num?)?.toDouble(),
      suhuBadan: (json['suhu_badan'] as num?)?.toDouble(),
      lingkarKepala: (json['lingkar_kepala'] as num?)?.toDouble(),
      catatan: json['catatan'] as String?,
      petugasId: json['petugas_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      namaImunisasi:
          (json['jenis_imunisasi'] as Map?)?['nama_imunisasi'] as String?,
      namaBalita: (json['balita'] as Map?)?['nama'] as String?,
      namaPetugas: (json['petugas'] as Map?)?['nama'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balita_id': balitaId,
      'jenis_imunisasi_id': jenisImunisasiId,
      'tanggal_imunisasi':
          '${tanggalImunisasi.year}-${tanggalImunisasi.month.toString().padLeft(2, '0')}-${tanggalImunisasi.day.toString().padLeft(2, '0')}',
      'berat_badan': beratBadan,
      'tinggi_badan': tinggiBadan,
      'suhu_badan': suhuBadan,
      'lingkar_kepala': lingkarKepala,
      'catatan': catatan,
      'petugas_id': petugasId,
    };
  }
}
