class EdukasiKategoriModel {
  final String id;
  final String nama;
  final String? deskripsi;
  final DateTime createdAt;

  const EdukasiKategoriModel({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.createdAt,
  });

  factory EdukasiKategoriModel.fromJson(Map<String, dynamic> json) {
    return EdukasiKategoriModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      deskripsi: json['deskripsi'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'nama': nama, if (deskripsi != null) 'deskripsi': deskripsi};
  }
}
