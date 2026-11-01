class JadwalPosyanduModel {
  final String id;
  final String judul;
  final String? deskripsi;
  final DateTime tanggal;
  final String? jamMulai;
  final String? jamSelesai;
  final String? lokasi;
  final String? createdBy;
  final bool reminderTerkirim;
  final DateTime createdAt;

  JadwalPosyanduModel({
    required this.id,
    required this.judul,
    this.deskripsi,
    required this.tanggal,
    this.jamMulai,
    this.jamSelesai,
    this.lokasi,
    this.createdBy,
    this.reminderTerkirim = false,
    required this.createdAt,
  });

  factory JadwalPosyanduModel.fromJson(Map<String, dynamic> json) {
    return JadwalPosyanduModel(
      id: json['id'] as String,
      judul: json['judul'] as String,
      deskripsi: json['deskripsi'] as String?,
      tanggal: _parseDate(json['tanggal'] as String),
      jamMulai: json['jam_mulai'] as String?,
      jamSelesai: json['jam_selesai'] as String?,
      lokasi: json['lokasi'] as String?,
      createdBy: json['created_by'] as String?,
      reminderTerkirim: json['reminder_terkirim'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static DateTime _parseDate(String s) {
    final d = s.length >= 10 ? s.substring(0, 10) : s;
    final p = d.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  Map<String, dynamic> toJson() {
    return {
      'judul': judul,
      'deskripsi': deskripsi,
      'tanggal':
          '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'lokasi': lokasi,
      'created_by': createdBy,
    };
  }
}
