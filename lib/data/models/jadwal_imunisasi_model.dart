class JadwalImunisasiModel {
  final String id;
  final String balitaId;
  final String? jenisImunisasiId;
  final DateTime tanggalJadwal;
  final String status;
  final bool reminderTerkirim;
  final DateTime createdAt;

  // Relasi
  final String? namaImunisasi;
  final int? usiaBulanImunisasi;
  final String? namaBalita;
  final String? balitaJenisKelamin;
  final DateTime? balitaTanggalLahir;

  JadwalImunisasiModel({
    required this.id,
    required this.balitaId,
    this.jenisImunisasiId,
    required this.tanggalJadwal,
    required this.status,
    this.reminderTerkirim = false,
    required this.createdAt,
    this.namaImunisasi,
    this.usiaBulanImunisasi,
    this.namaBalita,
    this.balitaJenisKelamin,
    this.balitaTanggalLahir,
  });

  factory JadwalImunisasiModel.fromJson(Map<String, dynamic> json) {
    final tanggal = _parseDate(json['tanggal_jadwal'] as String);
    String status = json['status'] as String? ?? 'terjadwal';
    // Koreksi client-side: tandai terlambat jika tanggal sudah lewat
    if (status == 'terjadwal') {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      if (DateTime(tanggal.year, tanggal.month, tanggal.day).isBefore(today)) {
        status = 'terlambat';
      }
    }
    return JadwalImunisasiModel(
      id: json['id'] as String,
      balitaId: json['balita_id'] as String,
      jenisImunisasiId: json['jenis_imunisasi_id'] as String?,
      tanggalJadwal: tanggal,
      status: status,
      reminderTerkirim: json['reminder_terkirim'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      namaImunisasi:
          (json['jenis_imunisasi'] as Map?)?['nama_imunisasi'] as String?,
      usiaBulanImunisasi:
          (json['jenis_imunisasi'] as Map?)?['usia_bulan'] as int?,
      namaBalita: (json['balita'] as Map?)?['nama'] as String?,
      balitaJenisKelamin:
          (json['balita'] as Map?)?['jenis_kelamin'] as String?,
      balitaTanggalLahir: (json['balita'] as Map?)?['tanggal_lahir'] != null
          ? _parseDate((json['balita'] as Map)['tanggal_lahir'] as String)
          : null,
    );
  }

  static DateTime _parseDate(String s) {
    final d = s.length >= 10 ? s.substring(0, 10) : s;
    final p = d.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  Map<String, dynamic> toJson() {
    return {
      'balita_id': balitaId,
      'jenis_imunisasi_id': jenisImunisasiId,
      'tanggal_jadwal':
          '${tanggalJadwal.year}-${tanggalJadwal.month.toString().padLeft(2, '0')}-${tanggalJadwal.day.toString().padLeft(2, '0')}',
      'status': status,
    };
  }
}
