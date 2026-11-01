# Feature Specification

## A. Fitur Kader/Admin

### 1. Login Kader
Kader dapat login menggunakan email dan password.

### 2. Dashboard Kader
Dashboard menampilkan:
- total balita
- total imunisasi bulan ini
- jumlah balita pending verifikasi
- jadwal posyandu terdekat
- notifikasi terbaru

### 3. Manajemen Data Balita
Kader dapat:
- menambah data balita
- melihat daftar balita
- mencari balita berdasarkan nama atau NIK
- mengedit data balita
- menghapus data balita
- melihat detail balita

Data balita:
- NIK
- nama
- tempat lahir
- tanggal lahir
- jenis kelamin
- nama orang tua
- kontak orang tua
- alamat
- status verifikasi

### 4. Verifikasi Data Balita
Data balita yang didaftarkan orang tua memiliki status pending.
Kader dapat menyetujui atau menolak data tersebut.

### 5. Input Hasil Imunisasi
Saat kader menginput hasil imunisasi, sistem harus menghitung umur balita secara otomatis dalam bulan berdasarkan tanggal lahir balita dan tanggal imunisasi.

Data umur bulan tidak diinput manual oleh kader.

Jika berat badan dan tinggi badan diisi, sistem juga membuat atau memperbarui data pertumbuhan balita.

Kader dapat mencatat:
- balita
- jenis imunisasi
- berat badan
- tinggi badan
- catatan
- tanggal imunisasi
- jadwal berikutnya
- petugas

Setelah data imunisasi disimpan, sistem membuat data notifikasi untuk orang tua.

### 6. Master Imunisasi
Kader dapat mengelola jenis imunisasi:
- HB0
- BCG
- Polio 1
- DPT-HB-Hib 1
- Polio 2
- Campak/MR

### 7. Jadwal Posyandu
Kader dapat membuat agenda kegiatan Posyandu Merpati:
- judul kegiatan
- deskripsi
- tanggal
- jam mulai
- jam selesai
- lokasi

### 8. Laporan
Kader dapat membuat laporan:
- laporan data balita
- laporan imunisasi
- laporan pertumbuhan
- laporan jadwal imunisasi

Format:
- PDF
- Excel/CSV

### 9. Edukasi
Kader dapat menambah, mengedit, dan menghapus artikel edukasi.

### 10. Profil Kader
Kader dapat melihat dan mengubah data profil.

### 11. Notifikasi
Kader menerima:
- notifikasi pendaftaran balita baru yang menunggu verifikasi
- reminder jadwal imunisasi dan agenda posyandu
- notifikasi balita dengan data belum lengkap (tempat lahir, kontak, atau alamat orang tua kosong)
- pengingat rekap dan ekspor laporan bulanan, dikirim di awal bulan

---

## B. Fitur Orang Tua/User

### 1. Register dan Login
Orang tua dapat membuat akun dan login.

### 2. Registrasi Balita
Orang tua dapat mendaftarkan balita.
Status awal data balita adalah pending.

### 3. Dashboard Pertumbuhan
Dashboard pertumbuhan menampilkan grafik berat badan dan tinggi badan balita berdasarkan usia dalam bulan.

Umur balita dihitung otomatis dari tanggal lahir.

Setiap data pertumbuhan harus menampilkan status gizi berdasarkan:
- berat badan
- tinggi badan
- usia dalam bulan
- jenis kelamin

Status gizi ditampilkan pada:
- detail data pertumbuhan
- grafik pertumbuhan
- ringkasan dashboard

Status gizi minimal:
- Normal
- Gizi Kurang
- Gizi Buruk
- Risiko Gizi Lebih
- Gizi Lebih
- Obesitas
- Risiko Stunting
- Stunting

### 4. Riwayat Imunisasi
Orang tua dapat melihat riwayat imunisasi balita.

### 5. Agenda Imunisasi
Aplikasi menampilkan agenda imunisasi berdasarkan umur balita.

Contoh:
- 0 bulan: HB0
- 1 bulan: BCG dan Polio 1
- 2 bulan: DPT-HB-Hib 1 dan Polio 2
- 9 bulan: Campak/MR

### 6. Notifikasi
Orang tua menerima:
- notifikasi hasil imunisasi
- reminder jadwal imunisasi
- pengumuman posyandu
- notifikasi status verifikasi balita

### 7. Edukasi
Orang tua dapat membaca artikel edukasi.

### 8. Profil Orang Tua
Orang tua dapat melihat dan mengubah data profil.

### 9. Status Gizi Otomatis

Sistem menghitung status gizi balita secara otomatis berdasarkan berat badan, tinggi badan, usia bulan, dan jenis kelamin.

Perhitungan dilakukan saat:
- data pertumbuhan ditambahkan
- hasil imunisasi disimpan
- dashboard pertumbuhan ditampilkan

Untuk versi awal, sistem menggunakan helper lokal. Untuk pengembangan lanjutan, perhitungan dapat menggunakan standar WHO/Z-score.