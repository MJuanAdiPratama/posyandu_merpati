# Development Plan

## Tahap 1: Project Setup
- Setup Flutter project
- Tambahkan dependencies
- Setup Supabase dengan `docs/database_setup.sql`
- Setup Hive
- Setup Local Notifications
- Setup routing

## Tahap 2: Auth
- Buat login
- Buat register
- Buat profile setelah register
- Redirect berdasarkan role

## Tahap 3: Balita
- Model balita
- Repository balita
- Provider balita
- CRUD balita untuk kader
- Registrasi balita untuk orang tua
- Verifikasi balita oleh kader

## Tahap 4: Imunisasi dan Pertumbuhan
- Model jenis imunisasi
- Model imunisasi
- Model pertumbuhan
- Input hasil imunisasi
- Simpan data pertumbuhan
- Riwayat imunisasi
- Grafik pertumbuhan
- Buat age_calculator.dart
- Buat growth_status_helper.dart
- Umur balita dihitung otomatis dari tanggal lahir dan tanggal pemeriksaan
- Saat input imunisasi, usia bulan dihitung otomatis
- Saat input pertumbuhan, status gizi dihitung otomatis
- Dashboard menampilkan grafik pertumbuhan dan status gizi
- Status gizi menggunakan berat badan, tinggi badan, usia bulan, dan jenis kelamin
- Untuk versi awal gunakan helper lokal
- Tambahkan TODO untuk integrasi WHO/Z-score

## Tahap 5: Notifikasi
- Model notifications
- Repository notifications
- Realtime subscription
- Simpan ke Hive
- Tampilkan local notification
- Halaman daftar notifikasi

## Tahap 6: Jadwal dan Agenda
- Jadwal imunisasi
- Jadwal posyandu
- Agenda orang tua
- Reminder local notification

## Tahap 7: Edukasi
- CRUD edukasi untuk kader
- List dan detail edukasi untuk orang tua

## Tahap 8: Laporan
- Export PDF
- Export Excel/CSV
- Filter laporan berdasarkan tanggal

## Tahap 9: Finishing
- Rapikan UI
- Validasi form
- Testing role
- Testing notifikasi
- Testing laporan
