# Desain: Monitoring Balita Keseluruhan (Kader)

## Latar Belakang

Saat ini kader hanya dapat melihat data pertumbuhan/imunisasi satu balita dalam satu waktu, lewat alur:
Daftar Balita → Detail Balita → Riwayat Pertumbuhan / Riwayat Imunisasi.

Kebutuhan baru (permintaan pembimbing saat sidang): kader dapat memonitor **seluruh balita sekaligus** —
status gizi, status imunisasi, dan siapa yang belum diperiksa bulan ini — dalam satu layar, tanpa harus
membuka data balita satu per satu.

## Tujuan

- Kader dapat melihat ringkasan status seluruh balita binaannya dalam satu layar.
- Balita yang butuh tindak lanjut (status gizi bermasalah, imunisasi terlambat, atau belum diperiksa
  bulan ini) ditandai/diprioritaskan secara jelas.
- Tetap bisa masuk ke detail satu balita dari layar monitoring (reuse layar Detail Balita yang sudah ada).

## Di Luar Cakupan

- Tidak membuat grafik/statistik agregat (pie chart distribusi status gizi dll).
- Tidak mengubah alur input pertumbuhan/imunisasi yang sudah ada.
- Tidak mengubah layar Daftar Balita / Detail Balita yang sudah ada (hanya konsumsi ulang).

## Arsitektur

### Repository

Tidak ada perubahan pada method yang sudah ada. Tambahan:

- `PertumbuhanRepository.getSemuaTerakhir()` (baru): ambil seluruh baris tabel `pertumbuhan` diurutkan
  `tanggal_pemeriksaan` menurun, lalu direduksi di sisi Dart menjadi satu data terbaru per `balita_id`
  (`Map<String, PertumbuhanModel>`). Tidak perlu SQL view/`DISTINCT ON` baru — cukup dengan pola yang
  sudah dipakai repository lain di project ini (fetch lalu proses di Dart).
- `JadwalImunisasiRepository.getSemua()` — **sudah ada**, dipakai ulang untuk menghitung jumlah jadwal
  berstatus `terlambat` per balita (status `terlambat` sudah dikoreksi otomatis di `JadwalImunisasiModel.fromJson`
  saat tanggal jadwal lewat).
- `BalitaRepository.getDaftarBalita()` — **sudah ada**, hasilnya difilter di provider ke
  `status_verifikasi == 'disetujui'` (balita `pending`/`ditolak` belum bisa diinput datanya sehingga tidak
  relevan dimonitor — konsisten dengan pengecekan `bolehInput` yang sudah ada di `DetailBalitaScreen`).

### Model

`MonitoringBalitaItem` (baru) — `lib/data/models/monitoring_balita_item.dart`. Ini **bukan** representasi
baris tabel database, melainkan hasil gabungan (view model) dari `BalitaModel` + `PertumbuhanModel?` +
jumlah jadwal terlambat, dihitung saat runtime. Karena tidak pernah diserialisasi ke/dari JSON, model ini
**tidak** memerlukan `fromJson`/`toJson` (aturan tersebut berlaku untuk model yang merepresentasikan data
di database).

Field:
- `balita` (`BalitaModel`)
- `pertumbuhanTerakhir` (`PertumbuhanModel?`)
- `usiaBulan` (`int`, dihitung dari `AgeCalculator` terhadap tanggal hari ini)
- `jumlahImunisasiTerlambat` (`int`)
- `belumDiperiksaBulanIni` (`bool`)
- getter turunan `perluPerhatian` (`bool`): true jika status gizi dari `pertumbuhanTerakhir` termasuk
  kategori bermasalah (`Gizi Kurang`, `Gizi Buruk`, `Risiko Stunting`, `Stunting`, `Risiko Gizi Lebih`,
  `Gizi Lebih`, `Obesitas`), atau `jumlahImunisasiTerlambat > 0`, atau `belumDiperiksaBulanIni == true`.

### Provider

`MonitoringBalitaProvider extends ChangeNotifier` (baru) —
`lib/features/kader/providers/monitoring_balita_provider.dart`. Didaftarkan di `app.dart` pada
`MultiProvider` yang sama dengan provider kader lainnya.

- `muatData()`:
  1. `Future.wait` untuk: `BalitaRepository.getDaftarBalita()`, `PertumbuhanRepository.getSemuaTerakhir()`,
     `JadwalImunisasiRepository.getSemua()`.
  2. Filter balita ke `status_verifikasi == 'disetujui'`.
  3. Untuk tiap balita: ambil pertumbuhan terakhir dari map (jika ada), hitung usia via `AgeCalculator`,
     hitung jumlah jadwal `status == 'terlambat'` milik balita tsb dari hasil `getSemua()`, hitung
     `belumDiperiksaBulanIni` = `pertumbuhanTerakhir == null || tanggalPemeriksaan < awal bulan berjalan`.
  4. Susun `List<MonitoringBalitaItem>`, urutkan: `perluPerhatian == true` lebih dulu, lalu di dalam
     masing-masing kelompok urut alfabetis berdasarkan `nama`.
  5. Simpan ke state, `notifyListeners()`.
- State/getters: `daftar` (`List<MonitoringBalitaItem>`), `jumlahPerluPerhatian` (`int`), `isLoading`,
  `error`.
- Try/catch di `muatData()` mengikuti pola provider lain di project (`DashboardKaderProvider`): tangkap
  error, simpan ke `error`, `isLoading = false`, `notifyListeners()`.

### Refactor pendukung

Logika pemetaan status gizi → warna/icon saat ini terduplikasi dan **tidak konsisten** di dua tempat:
`riwayat_pertumbuhan_kader_screen.dart` (`_statusColor`/`_statusIcon`, private) dan
`detail_balita_screen.dart` (`_statusGiziColor`, private, logikanya beda). Karena layar monitoring
membutuhkan pemetaan yang sama, konsolidasikan ke satu tempat baru:
`lib/core/widgets/growth_status_badge.dart`, berisi fungsi `growthStatusColor(String status) -> Color`
dan `growthStatusIcon(String status) -> IconData`. Helper `GrowthStatusHelper` sendiri tetap murni Dart
tanpa dependency Flutter (tidak diubah selain dipakai sebagai sumber kategori via
`statusGiziKeWarna()` yang sudah ada); pemetaan ke `Color`/`IconData` diletakkan di widget helper karena
memang butuh Flutter UI. Ketiga layar (`riwayat_pertumbuhan_kader_screen.dart`,
`detail_balita_screen.dart`, `monitoring_balita_screen.dart`) memakai fungsi ini, menghapus implementasi
duplikat/tidak konsisten yang lama.

## UI/UX

### Layar baru: `MonitoringBalitaScreen`

Lokasi: `lib/features/kader/screens/monitoring/monitoring_balita_screen.dart`.

Struktur (mengikuti pola visual layar kader lain — header gradient, card putih dengan border, dsb.):

1. Header gradient dengan tombol back + judul "Monitoring Balita".
2. Baris ringkasan (2 stat kecil): "Total Balita Dipantau" dan "Perlu Perhatian" (angka warning/error
   jika > 0).
3. Filter chip: `Semua` / `Perlu Perhatian` / `Normal` (pola sama dengan `_FilterBar` di
   `daftar_balita_screen.dart`).
4. Search bar nama balita (pola sama dengan `_ListHeader` di `daftar_balita_screen.dart`, opsional
   ditoggle lewat ikon search).
5. List card per balita (`_MonitoringCard`):
   - Avatar + nama + usia (pola sama dengan card di Daftar Balita).
   - Badge status gizi terakhir (pakai `growthStatusColor`/`growthStatusIcon`, atau "Belum ada data" abu-abu
     jika `pertumbuhanTerakhir == null`).
   - Badge imunisasi: `"{n} Terlambat"` (warna warning/error) jika `jumlahImunisasiTerlambat > 0`,
     selain itu `"Sesuai Jadwal"` (warna success).
   - Badge `"Belum Diperiksa Bulan Ini"` (warna warning) jika `belumDiperiksaBulanIni == true`.
   - Tap kartu → `context.read<BalitaKaderProvider>().pilihBalita(item.balita)` lalu
     `Navigator.pushNamed(context, AppRoutes.detailBalita)` (reuse layar yang sudah ada, tidak duplikasi).
6. Loading: `LoadingWidget`. Kosong: `EmptyStateWidget` (pesan berbeda untuk filter "Semua" vs
   "Perlu Perhatian" vs hasil pencarian kosong). Pull-to-refresh via `RefreshIndicator` memanggil
   `muatData()`.

### Beranda Kader

Di `beranda_kader_tab.dart`, `GridView.count` stat card ditambah satu kartu baru:

- Label: "Perlu Perhatian", value: `context.watch<MonitoringBalitaProvider>().jumlahPerluPerhatian`,
  caption: "Balita butuh tindak lanjut", icon: `Icons.health_and_safety_rounded` (atau serupa), warna:
  `AppColors.warning`, `onTap` → `Navigator.pushNamed(context, AppRoutes.monitoringBalita)`.
- Grid `crossAxisCount: 2` otomatis menjadi 3 baris (5 item) — tidak perlu ubah layout grid lain.
- `MonitoringBalitaProvider.muatData()` dipanggil bersamaan di `initState`/`onRefresh` beranda,
  sejalan dengan provider lain yang sudah di-refresh di situ (`DashboardKaderProvider`,
  `BalitaKaderProvider`, `JadwalPosyanduProvider`).

### Routing

Tambah di `lib/routes/app_routes.dart`:
```
static const String monitoringBalita = '/kader/monitoring';
```
Didaftarkan di route generator (`lib/routes/`) mengikuti pola registrasi route kader lain — provider
`MonitoringBalitaProvider` diambil dari `context.read` (sudah didaftarkan global di `app.dart`), tidak
perlu dibungkus `ChangeNotifierProvider` baru di route seperti pola beberapa layar lain yang memakai
provider lokal.

## Error Handling

- `MonitoringBalitaProvider.muatData()`: try/catch, simpan pesan error ke `error`, tetap set
  `isLoading = false` di `finally` (pola sama dengan `DashboardKaderProvider.muatDashboard()`).
- Kegagalan refresh manual (`RefreshIndicator`) menampilkan `CustomSnackbar.gagal` dengan pesan dari
  `provider.error` (pola sama dengan layar riwayat pertumbuhan).

## Testing

- Tidak ada test suite UI otomatis di project ini (hanya `test/growth_status_helper_test.dart` dan
  default `test/widget_test.dart`). Tambah unit test baru mengikuti pola yang sama:
  `test/monitoring_balita_provider_test.dart` atau cukup test murni logika penggabungan (tanpa Supabase)
  jika logika threshold/pengurutan diekstrak ke fungsi murni yang bisa dites tanpa mock network.
- Verifikasi manual (wajib sebelum dianggap selesai): jalankan aplikasi sebagai kader, dari beranda tap
  kartu "Perlu Perhatian" → layar Monitoring Balita tampil, filter & search berjalan, tap salah satu
  kartu balita → masuk ke Detail Balita yang benar dengan data yang konsisten.

## Ringkasan Perubahan File

- Baru: `lib/data/models/monitoring_balita_item.dart`
- Baru: `lib/features/kader/providers/monitoring_balita_provider.dart`
- Baru: `lib/features/kader/screens/monitoring/monitoring_balita_screen.dart`
- Baru: `lib/core/widgets/growth_status_badge.dart`
- Ubah: `lib/data/repositories/pertumbuhan_repository.dart` (tambah `getSemuaTerakhir()`)
- Ubah: `lib/app.dart` (daftarkan `MonitoringBalitaProvider`)
- Ubah: `lib/routes/app_routes.dart` + route generator (tambah `monitoringBalita`)
- Ubah: `lib/features/kader/screens/beranda/beranda_kader_tab.dart` (kartu baru + refresh provider)
- Ubah: `lib/features/kader/screens/pertumbuhan/riwayat_pertumbuhan_kader_screen.dart` (pakai
  `growth_status_badge.dart`, hapus `_statusColor`/`_statusIcon` lama)
- Ubah: `lib/features/kader/screens/balita/detail_balita_screen.dart` (pakai `growth_status_badge.dart`,
  hapus `_statusGiziColor` lama)
