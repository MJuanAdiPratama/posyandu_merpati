class JenisImunisasiModel {
  final String id;
  final String namaImunisasi;
  final int usiaBulan;
  final String? deskripsi;
  final String? kandungan;
  final DateTime createdAt;

  JenisImunisasiModel({
    required this.id,
    required this.namaImunisasi,
    required this.usiaBulan,
    this.deskripsi,
    this.kandungan,
    required this.createdAt,
  });

  factory JenisImunisasiModel.fromJson(Map<String, dynamic> json) {
    return JenisImunisasiModel(
      id: json['id'] as String,
      namaImunisasi: json['nama_imunisasi'] as String,
      usiaBulan: json['usia_bulan'] as int,
      deskripsi: json['deskripsi'] as String?,
      kandungan: json['kandungan'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_imunisasi': namaImunisasi,
      'usia_bulan': usiaBulan,
      'deskripsi': deskripsi,
      'kandungan': kandungan,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
