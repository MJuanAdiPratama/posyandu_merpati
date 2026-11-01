# Monitoring Balita Keseluruhan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give kader a single screen that shows the status (gizi, imunisasi, kepatuhan pemeriksaan) of every verified balita at once, with balita needing follow-up surfaced first.

**Architecture:** Add a pure, dependency-free merge function that combines existing `BalitaModel`/`PertumbuhanModel`/`JadwalImunisasiModel` data into a `MonitoringBalitaItem` view model; wrap it in a new `MonitoringBalitaProvider` (Provider pattern, matches every other kader feature); expose it via a new screen reached from a new stat card on the kader beranda. Consolidate the status-gizi → color/icon mapping (currently duplicated and inconsistent across two screens) into one shared widget helper used by the new screen and the two existing ones.

**Tech Stack:** Flutter, Dart, Provider, Supabase (existing `BalitaRepository`, `PertumbuhanRepository`, `JadwalImunisasiRepository`), `flutter_test`.

## Global Constraints

- Tidak akses Supabase langsung dari screen — semua lewat repository (CLAUDE.md).
- Semua state halaman dikelola lewat Provider (CLAUDE.md).
- Model yang merepresentasikan baris database wajib `fromJson`/`toJson`; `MonitoringBalitaItem` adalah view model runtime (bukan baris tabel) sehingga sengaja tidak memilikinya — didokumentasikan di spec `docs/superpowers/specs/2026-07-28-monitoring-balita-design.md`.
- Label UI berbahasa Indonesia (CLAUDE.md).
- Wajib loading state, empty state, dan snackbar sukses/gagal (CLAUDE.md) — pakai `LoadingWidget`, `EmptyStateWidget`, `CustomSnackbar` yang sudah ada.
- Perhitungan status gizi/usia tidak boleh di screen — pakai `AgeCalculator` dan `GrowthStatusHelper` yang sudah ada (CLAUDE.md).
- Commit setiap task selesai dengan pesan sesuai perubahan (CLAUDE.md) — setiap task di bawah diakhiri langkah commit.
- Ambang "belum diperiksa bulan ini": tidak ada data pertumbuhan sejak tanggal 1 bulan berjalan (dari spec).
- Hanya balita `status_verifikasi == 'disetujui'` yang dimonitor (dari spec).

---

## File Structure Overview

| File | Tanggung jawab |
|---|---|
| `lib/data/models/monitoring_balita_item.dart` (baru) | View model gabungan 1 balita untuk layar monitoring. |
| `lib/features/kader/providers/monitoring_balita_merger.dart` (baru) | Fungsi murni penggabung + pengurut data (testable tanpa Supabase). |
| `lib/features/kader/providers/monitoring_balita_provider.dart` (baru) | `ChangeNotifier` yang memanggil repository lalu mendelegasikan penggabungan ke merger. |
| `lib/core/widgets/growth_status_badge.dart` (baru) | Satu sumber kebenaran warna/icon status gizi, dipakai 3 layar. |
| `lib/features/kader/screens/monitoring/monitoring_balita_screen.dart` (baru) | UI layar Monitoring Balita. |
| `lib/data/repositories/pertumbuhan_repository.dart` (ubah) | Tambah `getSemuaTerakhir()`. |
| `lib/core/utils/growth_status_helper.dart` (ubah) | Tambah `isBermasalah()`. |
| `lib/features/kader/screens/pertumbuhan/riwayat_pertumbuhan_kader_screen.dart` (ubah) | Pakai badge helper, hapus duplikasi. |
| `lib/features/kader/screens/balita/detail_balita_screen.dart` (ubah) | Pakai badge helper, hapus duplikasi. |
| `lib/app.dart` (ubah) | Daftarkan `MonitoringBalitaProvider`. |
| `lib/routes/app_routes.dart` (ubah) | Tambah route `monitoringBalita`. |
| `lib/features/kader/screens/dashboard_kader_screen.dart` (ubah) | Panggil `muatData()` saat dashboard dibuka. |
| `lib/features/kader/screens/beranda/beranda_kader_tab.dart` (ubah) | Kartu baru "Perlu Perhatian" + refresh provider. |

---

### Task 1: `GrowthStatusHelper.isBermasalah`

**Files:**
- Modify: `lib/core/utils/growth_status_helper.dart`
- Test: `test/growth_status_helper_test.dart`

**Interfaces:**
- Produces: `static bool GrowthStatusHelper.isBermasalah(String? status)` — dipakai oleh Task 4 (merger) untuk menentukan `perluPerhatian`.

- [ ] **Step 1: Write the failing test**

Tambahkan grup baru di akhir `test/growth_status_helper_test.dart`, sebelum `});` penutup `main()`:

```dart
  group('GrowthStatusHelper.isBermasalah', () {
    test('status Normal bukan bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Normal'), isFalse);
    });

    test('status null bukan bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah(null), isFalse);
    });

    test('status "Tidak diketahui" bukan bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Tidak diketahui'), isFalse);
    });

    test('status Stunting bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Stunting'), isTrue);
    });

    test('status Gizi Kurang bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Gizi Kurang'), isTrue);
    });

    test('status Obesitas bermasalah', () {
      expect(GrowthStatusHelper.isBermasalah('Obesitas'), isTrue);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/growth_status_helper_test.dart`
Expected: FAIL — `isBermasalah` belum ada (compile error / method tidak ditemukan).

- [ ] **Step 3: Implement**

Di `lib/core/utils/growth_status_helper.dart`, tambahkan method statis baru di dalam class `GrowthStatusHelper`, setelah `statusGiziKeWarna`:

```dart
  /// True jika status menandakan masalah gizi yang perlu ditindaklanjuti
  /// (bukan Normal dan bukan hasil yang tidak bisa dihitung).
  static bool isBermasalah(String? status) {
    return status != null && status != 'Normal' && status != 'Tidak diketahui';
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/growth_status_helper_test.dart`
Expected: PASS, semua test termasuk yang sudah ada sebelumnya.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/growth_status_helper.dart test/growth_status_helper_test.dart
git commit -m "Tambah GrowthStatusHelper.isBermasalah untuk deteksi status gizi bermasalah"
```

---

### Task 2: `growth_status_badge.dart` — warna & icon status gizi terpusat

**Files:**
- Create: `lib/core/widgets/growth_status_badge.dart`
- Test: `test/growth_status_badge_test.dart`

**Interfaces:**
- Consumes: `GrowthStatusHelper.statusGiziKeWarna(String status) -> String` (sudah ada).
- Produces: `Color growthStatusColor(String status)`, `IconData growthStatusIcon(String status)` — dipakai Task 3 (refactor 2 layar lama) dan Task 6 (layar monitoring baru).

- [ ] **Step 1: Write the failing test**

Create `test/growth_status_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posyandu_merpati/core/constants/app_colors.dart';
import 'package:posyandu_merpati/core/widgets/growth_status_badge.dart';

void main() {
  group('growthStatusColor', () {
    test('Normal -> hijau (success)', () {
      expect(growthStatusColor('Normal'), AppColors.success);
    });

    test('Gizi Kurang -> kuning (warning)', () {
      expect(growthStatusColor('Gizi Kurang'), AppColors.warning);
    });

    test('Risiko Stunting -> kuning (warning)', () {
      expect(growthStatusColor('Risiko Stunting'), AppColors.warning);
    });

    test('Stunting -> merah tua (error)', () {
      expect(growthStatusColor('Stunting'), AppColors.error);
    });

    test('Gizi Buruk -> merah tua (error)', () {
      expect(growthStatusColor('Gizi Buruk'), AppColors.error);
    });

    test('Obesitas -> deepOrange', () {
      expect(growthStatusColor('Obesitas'), Colors.deepOrange);
    });

    test('status tak dikenal -> abu (textSecondary)', () {
      expect(growthStatusColor('Belum ada data'), AppColors.textSecondary);
    });
  });

  group('growthStatusIcon', () {
    test('Normal -> sentiment_satisfied_alt_rounded', () {
      expect(growthStatusIcon('Normal'), Icons.sentiment_satisfied_alt_rounded);
    });

    test('Gizi Buruk -> warning_amber_rounded', () {
      expect(growthStatusIcon('Gizi Buruk'), Icons.warning_amber_rounded);
    });

    test('status tak dikenal -> info_outline_rounded', () {
      expect(growthStatusIcon('Belum ada data'), Icons.info_outline_rounded);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/growth_status_badge_test.dart`
Expected: FAIL — file `lib/core/widgets/growth_status_badge.dart` belum ada.

- [ ] **Step 3: Implement**

Create `lib/core/widgets/growth_status_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/growth_status_helper.dart';

/// Warna badge status gizi, satu sumber kebenaran dipakai di semua layar
/// (sebelumnya terduplikasi dan tidak konsisten di beberapa layar).
Color growthStatusColor(String status) {
  switch (GrowthStatusHelper.statusGiziKeWarna(status)) {
    case 'hijau':
      return AppColors.success;
    case 'kuning':
      return AppColors.warning;
    case 'merah_tua':
      return AppColors.error;
    case 'oranye':
    case 'merah':
      return Colors.deepOrange;
    default:
      return AppColors.textSecondary;
  }
}

IconData growthStatusIcon(String status) {
  switch (GrowthStatusHelper.statusGiziKeWarna(status)) {
    case 'hijau':
      return Icons.sentiment_satisfied_alt_rounded;
    case 'kuning':
    case 'merah_tua':
      return Icons.warning_amber_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/growth_status_badge_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/growth_status_badge.dart test/growth_status_badge_test.dart
git commit -m "Tambah growth_status_badge sebagai sumber tunggal warna/icon status gizi"
```

---

### Task 3: Refactor layar lama untuk pakai `growth_status_badge.dart`

**Files:**
- Modify: `lib/features/kader/screens/pertumbuhan/riwayat_pertumbuhan_kader_screen.dart`
- Modify: `lib/features/kader/screens/balita/detail_balita_screen.dart`

**Interfaces:**
- Consumes: `growthStatusColor`, `growthStatusIcon` dari Task 2.

- [ ] **Step 1: Refactor `riwayat_pertumbuhan_kader_screen.dart`**

Tambah import setelah import `growth_status_helper.dart` (baris 8):

```dart
import '../../../../core/widgets/growth_status_badge.dart';
```

Ganti pemanggilan `_statusColor(status)` di `_HistoryRow.build` (baris ±509) dan `_SummaryCard.build` (baris ±605) menjadi `growthStatusColor(status)`. Ganti `_statusIcon(label)` di `_StatusBadge.build` (baris ±1016) dan `_statusIcon(status)` di `_SummaryCard.build` (baris ±623) menjadi `growthStatusIcon(...)`.

Hapus definisi lama di akhir file (baris ±1115-1146):

```dart
Color _statusColor(String status) {
  ...
}

IconData _statusIcon(String status) {
  ...
}
```

- [ ] **Step 2: Refactor `detail_balita_screen.dart`**

Tambah import setelah import `age_calculator.dart` (baris 6):

```dart
import '../../../../core/widgets/growth_status_badge.dart';
```

Di `_HealthSummaryCard.build`, ganti `_statusGiziColor(pertumbuhan!.statusGizi ?? 'Normal')` menjadi `growthStatusColor(pertumbuhan!.statusGizi ?? 'Normal')` (dua pemakaian: `color:` pada `_HealthMetric` label "Status Gizi").

Hapus definisi lama di akhir file (baris ±1004-1016):

```dart
Color _statusGiziColor(String status) {
  ...
}
```

- [ ] **Step 3: Verify no leftover references**

Run: `grep -rn "_statusColor\|_statusGiziColor\|_statusIcon" lib/features/kader/screens/pertumbuhan/riwayat_pertumbuhan_kader_screen.dart lib/features/kader/screens/balita/detail_balita_screen.dart`
Expected: no output (semua pemakaian sudah diganti dan definisi lama sudah dihapus).

- [ ] **Step 4: Run static analysis**

Run: `flutter analyze lib/features/kader/screens/pertumbuhan/riwayat_pertumbuhan_kader_screen.dart lib/features/kader/screens/balita/detail_balita_screen.dart`
Expected: No issues found.

- [ ] **Step 5: Run existing tests to ensure nothing broke**

Run: `flutter test`
Expected: PASS (semua test dari Task 1-2 tetap hijau; file-file ini tidak punya test dedicated).

- [ ] **Step 6: Commit**

```bash
git add lib/features/kader/screens/pertumbuhan/riwayat_pertumbuhan_kader_screen.dart lib/features/kader/screens/balita/detail_balita_screen.dart
git commit -m "Konsolidasi warna/icon status gizi ke growth_status_badge, hapus duplikasi"
```

---

### Task 4: `MonitoringBalitaItem` + `monitoring_balita_merger.dart` (logika murni)

**Files:**
- Create: `lib/data/models/monitoring_balita_item.dart`
- Create: `lib/features/kader/providers/monitoring_balita_merger.dart`
- Test: `test/monitoring_balita_merger_test.dart`

**Interfaces:**
- Consumes: `BalitaModel`, `PertumbuhanModel`, `JadwalImunisasiModel` (semua sudah ada), `GrowthStatusHelper.isBermasalah` (Task 1), `AgeCalculator.hitungUsiaBulan(DateTime tanggalLahir, DateTime tanggalAcuan) -> int` (sudah ada).
- Produces:
  - `class MonitoringBalitaItem` dengan field `balita`, `pertumbuhanTerakhir`, `usiaBulan`, `jumlahImunisasiTerlambat`, `belumDiperiksaBulanIni`, `perluPerhatian`, dan getter `statusGizi`.
  - `List<MonitoringBalitaItem> gabungkanMonitoringBalita({required List<BalitaModel> semuaBalita, required Map<String, PertumbuhanModel> pertumbuhanTerakhir, required List<JadwalImunisasiModel> semuaJadwal, required DateTime sekarang})` — dipakai Task 5 (provider).

- [ ] **Step 1: Write the failing test**

Create `test/monitoring_balita_merger_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/monitoring_balita_merger_test.dart`
Expected: FAIL — `monitoring_balita_merger.dart` dan `monitoring_balita_item.dart` belum ada.

- [ ] **Step 3: Implement `MonitoringBalitaItem`**

Create `lib/data/models/monitoring_balita_item.dart`:

```dart
import 'balita_model.dart';
import 'pertumbuhan_model.dart';

/// View model gabungan untuk layar Monitoring Balita, dihitung saat runtime
/// dari BalitaModel + data pertumbuhan terakhir + jumlah jadwal imunisasi
/// terlambat. Bukan representasi baris tabel database, sehingga tidak
/// memiliki fromJson/toJson.
class MonitoringBalitaItem {
  final BalitaModel balita;
  final PertumbuhanModel? pertumbuhanTerakhir;
  final int usiaBulan;
  final int jumlahImunisasiTerlambat;
  final bool belumDiperiksaBulanIni;
  final bool perluPerhatian;

  MonitoringBalitaItem({
    required this.balita,
    required this.pertumbuhanTerakhir,
    required this.usiaBulan,
    required this.jumlahImunisasiTerlambat,
    required this.belumDiperiksaBulanIni,
    required this.perluPerhatian,
  });

  String get statusGizi => pertumbuhanTerakhir?.statusGizi ?? 'Belum ada data';
}
```

- [ ] **Step 4: Implement `gabungkanMonitoringBalita`**

Create `lib/features/kader/providers/monitoring_balita_merger.dart`:

```dart
import '../../../core/utils/age_calculator.dart';
import '../../../core/utils/growth_status_helper.dart';
import '../../../data/models/balita_model.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/models/monitoring_balita_item.dart';
import '../../../data/models/pertumbuhan_model.dart';

/// Gabungkan data balita, pertumbuhan terakhir, dan jadwal imunisasi jadi
/// daftar MonitoringBalitaItem, diurutkan: perlu perhatian dulu, lalu
/// alfabetis. Fungsi murni (tanpa akses network) agar mudah dites.
List<MonitoringBalitaItem> gabungkanMonitoringBalita({
  required List<BalitaModel> semuaBalita,
  required Map<String, PertumbuhanModel> pertumbuhanTerakhir,
  required List<JadwalImunisasiModel> semuaJadwal,
  required DateTime sekarang,
}) {
  final awalBulan = DateTime(sekarang.year, sekarang.month, 1);
  final balitaDisetujui = semuaBalita
      .where((b) => b.statusVerifikasi == 'disetujui')
      .toList();

  final items = balitaDisetujui.map((balita) {
    final pertumbuhan = pertumbuhanTerakhir[balita.id];
    final jumlahTerlambat = semuaJadwal
        .where((j) => j.balitaId == balita.id && j.status == 'terlambat')
        .length;
    final belumDiperiksaBulanIni = pertumbuhan == null ||
        pertumbuhan.tanggalPemeriksaan.isBefore(awalBulan);
    final bermasalah = GrowthStatusHelper.isBermasalah(pertumbuhan?.statusGizi);

    return MonitoringBalitaItem(
      balita: balita,
      pertumbuhanTerakhir: pertumbuhan,
      usiaBulan: AgeCalculator.hitungUsiaBulan(balita.tanggalLahir, sekarang),
      jumlahImunisasiTerlambat: jumlahTerlambat,
      belumDiperiksaBulanIni: belumDiperiksaBulanIni,
      perluPerhatian: bermasalah || jumlahTerlambat > 0 || belumDiperiksaBulanIni,
    );
  }).toList();

  items.sort((a, b) {
    if (a.perluPerhatian != b.perluPerhatian) {
      return a.perluPerhatian ? -1 : 1;
    }
    return a.balita.nama.toLowerCase().compareTo(b.balita.nama.toLowerCase());
  });

  return items;
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/monitoring_balita_merger_test.dart`
Expected: PASS, semua 7 test.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/monitoring_balita_item.dart lib/features/kader/providers/monitoring_balita_merger.dart test/monitoring_balita_merger_test.dart
git commit -m "Tambah MonitoringBalitaItem dan logika penggabungan monitoring balita"
```

---

### Task 5: `PertumbuhanRepository.getSemuaTerakhir()` + `MonitoringBalitaProvider`

**Files:**
- Modify: `lib/data/repositories/pertumbuhan_repository.dart`
- Create: `lib/features/kader/providers/monitoring_balita_provider.dart`

**Interfaces:**
- Consumes: `gabungkanMonitoringBalita(...)` (Task 4), `BalitaRepository.getDaftarBalita()` (sudah ada), `JadwalImunisasiRepository.getSemua()` (sudah ada).
- Produces: `MonitoringBalitaProvider` dengan `daftar` (`List<MonitoringBalitaItem>`), `jumlahPerluPerhatian` (`int`), `isLoading` (`bool`), `error` (`String?`), `Future<void> muatData()` — dipakai Task 6 (screen) dan Task 7 (beranda).

Catatan: repository ini mengakses Supabase langsung sehingga tidak ditulis unit test (konsisten dengan repository lain di project — tidak ada test repository yang sudah ada). Verifikasi lewat `flutter analyze` dan pengecekan manual end-to-end di Task 8.

- [ ] **Step 1: Tambah `getSemuaTerakhir()` di `PertumbuhanRepository`**

Di `lib/data/repositories/pertumbuhan_repository.dart`, tambahkan method baru setelah `getTerakhir`:

```dart
  /// Ambil data pertumbuhan terbaru untuk setiap balita (untuk layar
  /// Monitoring Balita yang butuh ringkasan seluruh balita sekaligus).
  Future<Map<String, PertumbuhanModel>> getSemuaTerakhir() async {
    final data = await _client
        .from('pertumbuhan')
        .select()
        .order('tanggal_pemeriksaan', ascending: false);
    final hasil = <String, PertumbuhanModel>{};
    for (final row in data as List) {
      final model = PertumbuhanModel.fromJson(row);
      hasil.putIfAbsent(model.balitaId, () => model);
    }
    return hasil;
  }
```

- [ ] **Step 2: Implement `MonitoringBalitaProvider`**

Create `lib/features/kader/providers/monitoring_balita_provider.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../data/models/balita_model.dart';
import '../../../data/models/jadwal_imunisasi_model.dart';
import '../../../data/models/monitoring_balita_item.dart';
import '../../../data/models/pertumbuhan_model.dart';
import '../../../data/repositories/balita_repository.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';
import '../../../data/repositories/pertumbuhan_repository.dart';
import 'monitoring_balita_merger.dart';

class MonitoringBalitaProvider extends ChangeNotifier {
  final _balitaRepo = BalitaRepository();
  final _pertumbuhanRepo = PertumbuhanRepository();
  final _jadwalRepo = JadwalImunisasiRepository();

  List<MonitoringBalitaItem> _daftar = [];
  bool _isLoading = false;
  String? _error;

  List<MonitoringBalitaItem> get daftar => _daftar;
  int get jumlahPerluPerhatian => _daftar.where((i) => i.perluPerhatian).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> muatData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final semuaBalita = await _balitaRepo.getDaftarBalita();
      final pertumbuhanTerakhir = await _pertumbuhanRepo.getSemuaTerakhir();
      final semuaJadwal = await _jadwalRepo.getSemua();
      _daftar = gabungkanMonitoringBalita(
        semuaBalita: semuaBalita,
        pertumbuhanTerakhir: pertumbuhanTerakhir,
        semuaJadwal: semuaJadwal,
        sekarang: DateTime.now(),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

Catatan: tiga panggilan di atas sengaja berurutan (bukan `Future.wait`) supaya tipe tiap hasil (`List<BalitaModel>`, `Map<String, PertumbuhanModel>`, `List<JadwalImunisasiModel>`) tetap eksplisit tanpa perlu cast manual — menghindari `List<dynamic>` yang dihasilkan `Future.wait` pada list heterogen. Import `balita_model.dart`, `jadwal_imunisasi_model.dart`, dan `pertumbuhan_model.dart` di atas dipakai untuk anotasi tipe implisit dari pemanggilan repository tersebut.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/data/repositories/pertumbuhan_repository.dart lib/features/kader/providers/monitoring_balita_provider.dart`
Expected: No issues found. Jika ada warning cast seperti disebut di atas, perbaiki sesuai catatan lalu jalankan ulang.

- [ ] **Step 4: Run full test suite to confirm no regression**

Run: `flutter test`
Expected: PASS (provider tidak dites langsung karena bergantung Supabase, tapi memastikan tidak ada compile error yang menjalar).

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/pertumbuhan_repository.dart lib/features/kader/providers/monitoring_balita_provider.dart
git commit -m "Tambah MonitoringBalitaProvider dan PertumbuhanRepository.getSemuaTerakhir"
```

---

### Task 6: Layar `MonitoringBalitaScreen` + route

**Files:**
- Create: `lib/features/kader/screens/monitoring/monitoring_balita_screen.dart`
- Modify: `lib/routes/app_routes.dart`
- Modify: `lib/app.dart`

**Interfaces:**
- Consumes: `MonitoringBalitaProvider` (Task 5), `BalitaKaderProvider.pilihBalita(BalitaModel)` (sudah ada), `growthStatusColor`/`growthStatusIcon` (Task 2), `AgeCalculator.formatUsia(int usiaBulan) -> String` (sudah ada), `AppRoutes.detailBalita` (sudah ada).
- Produces: `AppRoutes.monitoringBalita` (route baru) — dipakai Task 7 (kartu beranda).

- [ ] **Step 1: Implement `MonitoringBalitaScreen`**

Create `lib/features/kader/screens/monitoring/monitoring_balita_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/age_calculator.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/growth_status_badge.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../data/models/monitoring_balita_item.dart';
import '../../../../routes/app_routes.dart';
import '../../providers/balita_kader_provider.dart';
import '../../providers/monitoring_balita_provider.dart';

class MonitoringBalitaScreen extends StatefulWidget {
  const MonitoringBalitaScreen({super.key});

  @override
  State<MonitoringBalitaScreen> createState() =>
      _MonitoringBalitaScreenState();
}

class _MonitoringBalitaScreenState extends State<MonitoringBalitaScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showSearch = false;
  String _filter = 'semua';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MonitoringBalitaItem> _terapkanFilter(List<MonitoringBalitaItem> all) {
    var list = switch (_filter) {
      'perlu_perhatian' => all.where((i) => i.perluPerhatian).toList(),
      'normal' => all.where((i) => !i.perluPerhatian).toList(),
      _ => all,
    };
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((i) => i.balita.nama.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _muatUlang() async {
    await context.read<MonitoringBalitaProvider>().muatData();
    if (!mounted) return;
    final error = context.read<MonitoringBalitaProvider>().error;
    if (error != null) {
      CustomSnackbar.gagal(context, 'Gagal memuat data monitoring balita');
    }
  }

  void _bukaDetail(MonitoringBalitaItem item) {
    context.read<BalitaKaderProvider>().pilihBalita(item.balita);
    Navigator.pushNamed(context, AppRoutes.detailBalita);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MonitoringBalitaProvider>();
    final filtered = _terapkanFilter(provider.daftar);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MonitoringHeader(
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onSearch: (v) => setState(() => _query = v),
            onClear: () => setState(() {
              _searchCtrl.clear();
              _query = '';
            }),
            onToggleSearch: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _query = '';
              }
            }),
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RingkasanCard(
                total: provider.daftar.length,
                perluPerhatian: provider.jumlahPerluPerhatian,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _FilterBar(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.groups_rounded,
                        pesan: provider.daftar.isEmpty
                            ? 'Belum ada balita terverifikasi untuk dipantau'
                            : 'Tidak ada balita yang cocok dengan filter ini',
                        onRetry: _muatUlang,
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _muatUlang,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (_, index) => _MonitoringCard(
                            item: filtered[index],
                            onTap: () => _bukaDetail(filtered[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringHeader extends StatelessWidget {
  final bool showSearch;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final VoidCallback onToggleSearch;

  const _MonitoringHeader({
    required this.showSearch,
    required this.searchCtrl,
    required this.onSearch,
    required this.onClear,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, 0, 16, showSearch ? 20 : 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Monitoring Balita',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showSearch
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    color: Colors.white,
                  ),
                  onPressed: onToggleSearch,
                ),
              ],
            ),
            if (showSearch) ...[
              const SizedBox(height: 10),
              TextField(
                controller: searchCtrl,
                autofocus: true,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama balita',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: onClear,
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RingkasanCard extends StatelessWidget {
  final int total;
  final int perluPerhatian;

  const _RingkasanCard({required this.total, required this.perluPerhatian});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _RingkasanItem(
              label: 'Total Balita Dipantau',
              value: '$total',
              color: AppColors.primary,
              icon: Icons.groups_rounded,
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.divider),
          Expanded(
            child: _RingkasanItem(
              label: 'Perlu Perhatian',
              value: '$perluPerhatian',
              color: perluPerhatian > 0 ? AppColors.warning : AppColors.success,
              icon: Icons.health_and_safety_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingkasanItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _RingkasanItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'Semua',
            selected: selected == 'semua',
            color: AppColors.primary,
            onTap: () => onChanged('semua'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Perlu Perhatian',
            selected: selected == 'perlu_perhatian',
            color: AppColors.warning,
            onTap: () => onChanged('perlu_perhatian'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Normal',
            selected: selected == 'normal',
            color: AppColors.success,
            onTap: () => onChanged('normal'),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  final MonitoringBalitaItem item;
  final VoidCallback onTap;

  const _MonitoringCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final balita = item.balita;
    final isBoy = balita.jenisKelamin == 'Laki-laki';
    final statusColor = growthStatusColor(item.statusGizi);
    final statusIcon = growthStatusIcon(item.statusGizi);

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isBoy
                        ? AppColors.surfaceTeal
                        : const Color(0xFFFFE4EE),
                    child: Icon(
                      isBoy ? Icons.boy_rounded : Icons.girl_rounded,
                      color: isBoy
                          ? AppColors.primary
                          : const Color(0xFFE91E8C),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balita.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Usia ${AgeCalculator.formatUsia(item.usiaBulan)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(label: item.statusGizi, color: statusColor, icon: statusIcon),
                  if (item.jumlahImunisasiTerlambat > 0)
                    _Badge(
                      label: '${item.jumlahImunisasiTerlambat} Imunisasi Terlambat',
                      color: AppColors.error,
                      icon: Icons.vaccines_rounded,
                    )
                  else
                    const _Badge(
                      label: 'Imunisasi Sesuai Jadwal',
                      color: AppColors.success,
                      icon: Icons.vaccines_rounded,
                    ),
                  if (item.belumDiperiksaBulanIni)
                    const _Badge(
                      label: 'Belum Diperiksa Bulan Ini',
                      color: AppColors.warning,
                      icon: Icons.event_busy_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Daftarkan route di `lib/routes/app_routes.dart`**

Tambah import setelah baris `import '../features/kader/screens/balita/verifikasi_balita_screen.dart';` (baris 11):

```dart
import '../features/kader/screens/monitoring/monitoring_balita_screen.dart';
```

Tambah konstanta setelah `static const String verifikasiBalita = '/kader/balita/verifikasi';` (baris 56):

```dart
  static const String monitoringBalita = '/kader/monitoring';
```

Tambah entri map setelah `verifikasiBalita: (_) => const VerifikasiBalitaScreen(),` (baris 98):

```dart
    monitoringBalita: (_) => const MonitoringBalitaScreen(),
```

- [ ] **Step 3: Daftarkan provider di `lib/app.dart`**

Tambah import setelah `import 'features/kader/providers/manajemen_pengguna_provider.dart';` (baris 20):

```dart
import 'features/kader/providers/monitoring_balita_provider.dart';
```

Tambah ke `MultiProvider.providers` setelah `ChangeNotifierProvider(create: (_) => BalitaKaderProvider()),` (baris 65):

```dart
        ChangeNotifierProvider(create: (_) => MonitoringBalitaProvider()),
```

- [ ] **Step 4: Run static analysis**

Run: `flutter analyze`
Expected: No issues found (project-wide, memastikan wiring route/provider baru tidak merusak file lain).

- [ ] **Step 5: Run full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/kader/screens/monitoring/monitoring_balita_screen.dart lib/routes/app_routes.dart lib/app.dart
git commit -m "Tambah layar Monitoring Balita dan daftarkan route/provider"
```

---

### Task 7: Integrasi Beranda Kader

**Files:**
- Modify: `lib/features/kader/screens/beranda/beranda_kader_tab.dart`
- Modify: `lib/features/kader/screens/dashboard_kader_screen.dart`

**Interfaces:**
- Consumes: `MonitoringBalitaProvider` (Task 5), `AppRoutes.monitoringBalita` (Task 6).

- [ ] **Step 1: Muat data monitoring saat dashboard kader dibuka**

Di `lib/features/kader/screens/dashboard_kader_screen.dart`, tambah import:

```dart
import '../providers/monitoring_balita_provider.dart';
```

Di `_DashboardKaderScreenState.initState`, tambahkan pemanggilan setelah `context.read<JadwalPosyanduProvider>().muatDaftar();`:

```dart
      context.read<MonitoringBalitaProvider>().muatData();
```

- [ ] **Step 2: Tambah kartu "Perlu Perhatian" di beranda**

Di `lib/features/kader/screens/beranda/beranda_kader_tab.dart`, tambah import:

```dart
import '../../providers/monitoring_balita_provider.dart';
```

Di `BerandaKaderTab.build`, tambahkan `final monitoring = context.watch<MonitoringBalitaProvider>();` setelah baris `final auth = context.watch<AuthProvider>();`.

Tambahkan `MonitoringBalitaProvider.muatData()` ke `Future.wait` di `onRefresh` (RefreshIndicator), sejajar dengan provider lain:

```dart
      onRefresh: () async {
        await Future.wait([
          context.read<DashboardKaderProvider>().muatDashboard(),
          context.read<BalitaKaderProvider>().muatDaftar(),
          context.read<JadwalPosyanduProvider>().muatDaftar(),
          context.read<MonitoringBalitaProvider>().muatData(),
        ]);
      },
```

Tambahkan satu `_StatCard` baru ke `GridView.count` (dalam `children:`), setelah kartu "Jadwal Terdekat":

```dart
                        _StatCard(
                          label: 'Perlu Perhatian',
                          value: '${monitoring.jumlahPerluPerhatian}',
                          caption: 'Balita butuh tindak lanjut',
                          icon: Icons.health_and_safety_rounded,
                          color: AppColors.warning,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.monitoringBalita,
                          ),
                        ),
```

`GridView.count` dengan 5 item dan `crossAxisCount: 2` otomatis menghasilkan baris ke-3 dengan 1 kartu — tidak perlu ubah `crossAxisCount`/`childAspectRatio`.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 4: Run full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/kader/screens/beranda/beranda_kader_tab.dart lib/features/kader/screens/dashboard_kader_screen.dart
git commit -m "Tambah kartu Perlu Perhatian di beranda kader menuju Monitoring Balita"
```

---

### Task 8: Verifikasi manual end-to-end

**Files:** tidak ada perubahan kode — hanya verifikasi.

- [ ] **Step 1: Jalankan aplikasi**

Run: `flutter run` (pilih device/emulator yang tersedia), login sebagai akun kader.

- [ ] **Step 2: Verifikasi beranda**

Di tab Beranda, pastikan kartu "Perlu Perhatian" tampil dengan angka yang masuk akal (bukan selalu 0 jika ada balita bermasalah/belum diperiksa/imunisasi telat), dan tap kartu membuka layar Monitoring Balita.

- [ ] **Step 3: Verifikasi layar Monitoring Balita**

- Pastikan daftar balita disetujui tampil semua, balita `pending`/`ditolak` tidak muncul.
- Balita dengan status gizi bermasalah, imunisasi terlambat, atau belum diperiksa bulan ini tampil di bagian atas daftar.
- Coba filter "Perlu Perhatian" dan "Normal", pastikan hasil sesuai.
- Coba search nama balita, pastikan hasil sesuai.
- Pull-to-refresh berfungsi tanpa error.
- Tap salah satu kartu balita, pastikan masuk ke Detail Balita balita yang benar (nama & data cocok).

- [ ] **Step 4: Verifikasi tidak ada regresi di layar lama**

Buka Detail Balita salah satu balita → Riwayat Pertumbuhan, pastikan badge status gizi tampil dengan warna/icon yang sama seperti sebelumnya (Normal hijau, Gizi Buruk/Stunting merah, dst — sesuai hasil refactor Task 3).

- [ ] **Step 5: Commit (jika ada perbaikan kecil dari verifikasi manual)**

Jika verifikasi manual menemukan bug kecil, perbaiki, lalu:

```bash
git add -A
git commit -m "Perbaikan hasil verifikasi manual fitur Monitoring Balita"
```

Jika tidak ada perbaikan, tidak perlu commit — task ini murni verifikasi.
