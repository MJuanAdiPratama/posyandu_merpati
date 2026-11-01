class EdukasiModel {
  final String id;
  final String judul;
  final String isi;
  final String? ringkasan;
  final String? kategoriId;
  final String? kategori;
  final String? gambarUrl;
  final String? createdBy;
  final DateTime createdAt;

  EdukasiModel({
    required this.id,
    required this.judul,
    required this.isi,
    this.ringkasan,
    this.kategoriId,
    this.kategori,
    this.gambarUrl,
    this.createdBy,
    required this.createdAt,
  });

  String get ringkasanDisplay {
    if (ringkasan != null && ringkasan!.isNotEmpty) return ringkasan!;
    return isi.length > 120 ? '${isi.substring(0, 120)}...' : isi;
  }

  int get estimasiMenitBaca {
    final words = isi.split(RegExp(r'\s+')).length;
    final menit = (words / 200).ceil();
    return menit < 1 ? 1 : menit;
  }

  factory EdukasiModel.fromJson(Map<String, dynamic> json) {
    return EdukasiModel(
      id: json['id'] as String,
      judul: json['judul'] as String,
      isi: json['isi'] as String,
      ringkasan: json['ringkasan'] as String?,
      kategoriId: json['kategori_id'] as String?,
      kategori: json['kategori'] as String?,
      gambarUrl: json['gambar_url'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'judul': judul,
      'isi': isi,
      'ringkasan': ringkasan,
      'kategori': kategori,
      'gambar_url': gambarUrl,
      'created_by': createdBy,
    };
    if (kategoriId != null) data['kategori_id'] = kategoriId;
    return data;
  }
}
