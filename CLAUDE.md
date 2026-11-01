# AGENTS.md

## Project

Nama aplikasi: Posyandu Merpati

Aplikasi Android berbasis Flutter untuk manajemen posyandu, monitoring kesehatan balita, input imunisasi, grafik pertumbuhan, laporan, dan notifikasi real-time.

## Stack

Gunakan:
- Flutter
- Dart
- Supabase
- Supabase Auth
- Supabase PostgreSQL
- Supabase Realtime
- Provider
- Firebase FCM
- Flutter Local Notifications
- fl_chart
- pdf
- printing
- excel


## Role Pengguna

Aplikasi memiliki dua role:

1. kader
2. orang_tua

Jika role adalah kader, arahkan ke dashboard kader.
Jika role adalah orang_tua, arahkan ke dashboard orang tua.

## Struktur Folder

Gunakan struktur berikut:

lib/
- main.dart
- app.dart
- core/
- data/
- features/
- routes/

core/ berisi constants, services, utils, dan widgets umum.
data/ berisi models dan repositories.
features/ berisi fitur berdasarkan role dan modul.
routes/ berisi routing aplikasi.

## Aturan Coding

1. Jangan akses Supabase langsung dari screen.
2. Semua akses database harus lewat repository.
3. Semua state halaman dikelola lewat Provider.
4. Semua model wajib punya fromJson dan toJson.
5. Gunakan Bahasa Indonesia untuk label UI.
6. Gunakan validasi form.
7. Gunakan loading state saat fetch data.
8. Gunakan empty state jika data kosong.
9. Gunakan snackbar untuk pesan sukses atau gagal.
10. Jangan membuat fitur di luar spesifikasi tanpa diminta.
11. Commit perubahan sesudah task selesai dan pesan commit sesuai dengan perubahan.

## Notifikasi

Notifikasi menggunakan:
- tabel notifications di Supabase
- Supabase Realtime
- Hive
- Flutter Local Notifications

Alur:
1. Data notifikasi dibuat di tabel notifications.
2. Aplikasi subscribe ke tabel notifications berdasarkan user_id.
3. Jika ada data baru, simpan ke Hive.
4. Tampilkan local notification.
5. Update daftar notifikasi di aplikasi.



## Database

Gunakan schema dari file:

docs/database_schema.sql

## Fitur

Gunakan spesifikasi fitur dari file:

docs/feature_spec.md

## Aturan Perhitungan Umur dan Status Gizi

Aplikasi harus menghitung umur balita secara otomatis dari tanggal lahir.

Umur balita dihitung dalam satuan bulan berdasarkan:
- tanggal_lahir balita
- tanggal pemeriksaan atau tanggal imunisasi

Jangan meminta user menginput usia balita secara manual kecuali sebagai fallback.

## Status Gizi dan Pertumbuhan

Status gizi pada grafik pertumbuhan harus dihitung berdasarkan:
- berat badan
- tinggi badan
- usia dalam bulan
- jenis kelamin

Data yang digunakan:
- tanggal_lahir dari tabel balita
- jenis_kelamin dari tabel balita
- berat_badan dari tabel pertumbuhan atau imunisasi
- tinggi_badan dari tabel pertumbuhan atau imunisasi
- tanggal_pemeriksaan atau tanggal_imunisasi

Status gizi minimal ditampilkan dalam bentuk:
- Normal
- Gizi Kurang
- Gizi Buruk
- Risiko Gizi Lebih
- Gizi Lebih
- Obesitas
- Risiko Stunting
- Stunting

Untuk versi awal aplikasi, status gizi boleh menggunakan helper lokal di Flutter.
Jika standar WHO belum tersedia lengkap, gunakan kategori sederhana berbasis helper dan beri komentar TODO untuk integrasi standar WHO/Z-score.

File helper yang harus dibuat:
- lib/core/utils/age_calculator.dart
- lib/core/utils/growth_status_helper.dart

Jangan menghitung status gizi langsung di screen.
Perhitungan harus dilakukan melalui helper atau service.