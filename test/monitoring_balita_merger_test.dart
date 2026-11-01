import 'package:flutter_test/flutter_test.dart';
import 'package:posyandu_merpati/data/models/balita_model.dart';
import 'package:posyandu_merpati/data/models/jadwal_imunisasi_model.dart';
import 'package:posyandu_merpati/data/models/pertumbuhan_model.dart';
import 'package:posyandu_merpati/features/kader/providers/monitoring_balita_merger.dart';

BalitaModel _balita({
  required String id,
  required String nama,
  String statusVerifikasi = 'disetujui',
  DateTime? tanggalLahir,
}) {
  final now = DateTime(2026, 7, 28);
  return BalitaModel(
    id: id,
    nik: '00$id',
    nama: nama,
    tanggalLahir: tanggalLahir ?? DateTime(2024, 1, 1),
    jenisKelamin: 'Laki-laki',
    namaOrtu: 'Ortu $nama',
    statusVerifikasi: statusVerifikasi,
    createdAt: now,
    updatedAt: now,
  );
}

PertumbuhanModel _pertumbuhan({
  required String balitaId,
  required DateTime tanggalPemeriksaan,
  String? statusGizi,
}) {
  return PertumbuhanModel(
    id: 'p-$balitaId',
    balitaId: balitaId,
    tanggalPemeriksaan: tanggalPemeriksaan,
    usiaBulan: 12,
    beratBadan: 10,
    tinggiBadan: 75,
    statusGizi: statusGizi,
    createdAt: tanggalPemeriksaan,
  );
}

JadwalImunisasiModel _jadwal({
  required String balitaId,
  required String status,
  DateTime? tanggalJadwal,
}) {
  final tgl = tanggalJadwal ?? DateTime(2026, 1, 1);
  return JadwalImunisasiModel(
    id: 'j-$balitaId-$status-${tgl.toIso8601String()}',
    balitaId: balitaId,
    tanggalJadwal: tgl,
    status: status,
    createdAt: tgl,
  );
}

void main() {
  final sekarang = DateTime(2026, 7, 28);

  test('balita belum disetujui tidak muncul di hasil', () {
    final hasil = gabungkanMonitoringBalita(
      semuaBalita: [_balita(id: '1', nama: 'Andi', statusVerifikasi: 'pending')],
      pertumbuhanTerakhir: {},
      semuaJadwal: [],
      sekarang: sekarang,
    );
    expect(hasil, isEmpty);
  });

  test('balita disetujui tanpa data pertumbuhan -> belum diperiksa & perlu perhatian', () {
    final hasil = gabungkanMonitoringBalita(
      semuaBalita: [_balita(id: '1', nama: 'Andi')],
      pertumbuhanTerakhir: {},
      semuaJadwal: [],
      sekarang: sekarang,
    );
    expect(hasil, hasLength(1));
    expect(hasil.first.pertumbuhanTerakhir, isNull);
    expect(hasil.first.statusGizi, 'Belum ada data');
    expect(hasil.first.belumDiperiksaBulanIni, isTrue);
    expect(hasil.first.perluPerhatian, isTrue);
  });

  test('balita dengan pertumbuhan bulan ini status Normal, tanpa jadwal terlambat -> tidak perlu perhatian', () {
    final hasil = gabungkanMonitoringBalita(
      semuaBalita: [_balita(id: '1', nama: 'Andi')],
      pertumbuhanTerakhir: {
        '1': _pertumbuhan(
          balitaId: '1',
          tanggalPemeriksaan: DateTime(2026, 7, 10),
          statusGizi: 'Normal',
        ),
      },
      semuaJadwal: [],
      sekarang: sekarang,
    );
    expect(hasil.first.belumDiperiksaBulanIni, isFalse);
    expect(hasil.first.perluPerhatian, isFalse);
  });

  test('pertumbuhan bulan lalu (sebelum tanggal 1 bulan ini) -> belum diperiksa bulan ini', () {
    final hasil = gabungkanMonitoringBalita(
      semuaBalita: [_balita(id: '1', nama: 'Andi')],
      pertumbuhanTerakhir: {
        '1': _pertumbuhan(
          balitaId: '1',
          tanggalPemeriksaan: DateTime(2026, 6, 30),
          statusGizi: 'Normal',
        ),
      },
      semuaJadwal: [],
      sekarang: sekarang,
    );
    expect(hasil.first.belumDiperiksaBulanIni, isTrue);
    expect(hasil.first.perluPerhatian, isTrue);
  });

  test('status gizi Stunting -> perlu perhatian walau sudah diperiksa bulan ini & imunisasi lancar', () {
    final hasil = gabungkanMonitoringBalita(
      semuaBalita: [_balita(id: '1', nama: 'Andi')],
      pertumbuhanTerakhir: {
        '1': _pertumbuhan(
          balitaId: '1',
          tanggalPemeriksaan: DateTime(2026, 7, 10),
          statusGizi: 'Stunting',
        ),
      },
      semuaJadwal: [],
      sekarang: sekarang,
    );
    expect(hasil.first.perluPerhatian, isTrue);
  });

  test('jadwal imunisasi terlambat dihitung per balita dan memicu perlu perhatian', () {
    final hasil = gabungkanMonitoringBalita(
      semuaBalita: [_balita(id: '1', nama: 'Andi'), _balita(id: '2', nama: 'Budi')],
      pertumbuhanTerakhir: {
        '1': _pertumbuhan(balitaId: '1', tanggalPemeriksaan: DateTime(2026, 7, 10), statusGizi: 'Normal'),
        '2': _pertumbuhan(balitaId: '2', tanggalPemeriksaan: DateTime(2026, 7, 10), statusGizi: 'Normal'),
      },
      semuaJadwal: [
        _jadwal(balitaId: '1', status: 'terlambat'),
        _jadwal(balitaId: '1', status: 'terlambat'),
        _jadwal(balitaId: '2', status: 'terjadwal'),
      ],
      sekarang: sekarang,
    );
    final andi = hasil.firstWhere((i) => i.balita.id == '1');
    final budi = hasil.firstWhere((i) => i.balita.id == '2');
    expect(andi.jumlahImunisasiTerlambat, 2);
    expect(andi.perluPerhatian, isTrue);
    expect(budi.jumlahImunisasiTerlambat, 0);
    expect(budi.perluPerhatian, isFalse);
  });

  test('pengurutan: perlu perhatian dulu, lalu alfabetis dalam grup masing-masing', () {
    final hasil = gabungkanMonitoringBalita(
      semuaBalita: [
        _balita(id: '1', nama: 'Zaki'), // normal
        _balita(id: '2', nama: 'Budi'), // perlu perhatian (belum diperiksa)
        _balita(id: '3', nama: 'Ani'), // normal
        _balita(id: '4', nama: 'Cici'), // perlu perhatian (belum diperiksa)
      ],
      pertumbuhanTerakhir: {
        '1': _pertumbuhan(balitaId: '1', tanggalPemeriksaan: DateTime(2026, 7, 10), statusGizi: 'Normal'),
        '3': _pertumbuhan(balitaId: '3', tanggalPemeriksaan: DateTime(2026, 7, 10), statusGizi: 'Normal'),
      },
      semuaJadwal: [],
      sekarang: sekarang,
    );
    expect(hasil.map((i) => i.balita.nama).toList(), ['Budi', 'Cici', 'Ani', 'Zaki']);
  });
}
