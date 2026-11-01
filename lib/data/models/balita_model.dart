class BalitaModel {
  final String id;
  final String? parentId;
  final String nik;
  final String nama;
  final String? tempatLahir;
  final DateTime tanggalLahir;
  final String jenisKelamin;
  final String namaOrtu;
  final String? kontakOrtu;
  final String? alamat;
  final String statusVerifikasi;
  final DateTime createdAt;
  final DateTime updatedAt;

  BalitaModel({
    required this.id,
    this.parentId,
    required this.nik,
    required this.nama,
    this.tempatLahir,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.namaOrtu,
    this.kontakOrtu,
    this.alamat,
    required this.statusVerifikasi,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BalitaModel.fromJson(Map<String, dynamic> json) {
    return BalitaModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      nik: json['nik'] as String,
      nama: json['nama'] as String,
      tempatLahir: json['tempat_lahir'] as String?,
      tanggalLahir: DateTime.parse(json['tanggal_lahir'] as String),
      jenisKelamin: json['jenis_kelamin'] as String,
      namaOrtu: json['nama_ortu'] as String,
      kontakOrtu: json['kontak_ortu'] as String?,
      alamat: json['alamat'] as String?,
      statusVerifikasi: json['status_verifikasi'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_id': parentId,
      'nik': nik,
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir':
          '${tanggalLahir.year}-${tanggalLahir.month.toString().padLeft(2, '0')}-${tanggalLahir.day.toString().padLeft(2, '0')}',
      'jenis_kelamin': jenisKelamin,
      'nama_ortu': namaOrtu,
      'kontak_ortu': kontakOrtu,
      'alamat': alamat,
      'status_verifikasi': statusVerifikasi,
    };
  }

  BalitaModel copyWith({
    String? nik,
    String? nama,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? namaOrtu,
    String? kontakOrtu,
    String? alamat,
    String? statusVerifikasi,
  }) {
    return BalitaModel(
      id: id,
      parentId: parentId,
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      namaOrtu: namaOrtu ?? this.namaOrtu,
      kontakOrtu: kontakOrtu ?? this.kontakOrtu,
      alamat: alamat ?? this.alamat,
      statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
