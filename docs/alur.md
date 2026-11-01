# Alur Aplikasi Posyandu Merpati

Dokumen ini menjelaskan alur lengkap penggunaan aplikasi berdasarkan role.

---

## 1. Autentikasi

### Kader
1. Buka aplikasi → layar Login
2. Masukkan email dan password kader
3. Sistem cek role dari tabel `profiles`
4. Redirect ke **Dashboard Kader**

### Orang Tua
1. Buka aplikasi → layar Login
2. Jika belum punya akun → tap **Daftar**
   - Isi email, password, nama
   - Sistem kirim konfirmasi email via Supabase Auth
   - Setelah konfirmasi → buat profil di tabel `profiles` dengan role `orang_tua`
3. Login → redirect ke **Dashboard Orang Tua**

---

## 2. Alur Kader

### 2.1 Manajemen Balita

```
Dashboard Kader
  └─ Daftar Balita
       ├─ Tambah Balita (kader input manual)
       ├─ Verifikasi Balita (status: pending → disetujui/ditolak)
       └─ Detail Balita
            ├─ Edit / Hapus
            ├─ Generate Jadwal Imunisasi
            ├─ Jadwal Imunisasi  ← lihat & eksekusi jadwal
            └─ Input Imunisasi   ← input langsung tanpa jadwal
```

**Catatan verifikasi:**
- Balita yang didaftarkan orang tua memiliki status `pending`
- Balita yang ditambah kader langsung memiliki status `disetujui`
- Hanya balita berstatus `disetujui` yang bisa diinput imunisasinya

---

### 2.2 Alur Jadwal Imunisasi

```
Detail Balita
  └─ Generate Jadwal Imunisasi
       │  Sistem hitung tanggal jadwal dari:
       │  tanggal_lahir + usia_bulan per jenis imunisasi
       │
       └─ Simpan → tabel jadwal_imunisasi (status: terjadwal/terlambat)

Detail Balita
  └─ Jadwal Imunisasi
       └─ Daftar Jadwal (Terjadwal / Terlambat / Selesai)
            └─ Tap [Input] pada jadwal aktif
                 └─ Input Imunisasi Screen
                      │  (balita & jenis imunisasi sudah ter-pre-fill)
                      └─ Simpan
                           ├─ tabel imunisasi       ← record imunisasi baru
                           ├─ jadwal_imunisasi      ← status → 'selesai'
                           ├─ tabel pertumbuhan     ← jika BB & TB diisi
                           ├─ jadwal_imunisasi      ← record baru jika jadwal berikutnya diisi
                           └─ tabel notifications   ← notifikasi ke orang tua
```

**Status jadwal imunisasi:**

| Status | Keterangan |
|--------|-----------|
| `terjadwal` | Tanggal jadwal belum lewat |
| `terlambat` | Tanggal jadwal sudah lewat, belum dilaksanakan |
| `selesai` | Imunisasi sudah dicatat oleh kader |

---

### 2.3 Input Imunisasi (Tanpa Jadwal)

Kader juga bisa input imunisasi langsung tanpa melalui jadwal:

```
Dashboard Kader → tab Input Imunisasi
  atau
Detail Balita → tombol [Input Imunisasi]
  └─ Pilih balita (dari dropdown)
  └─ Pilih jenis imunisasi
  └─ Isi BB, TB, catatan, petugas
  └─ Pilih tanggal imunisasi
  └─ (opsional) Pilih jadwal berikutnya + jenis imunisasi berikutnya
  └─ Simpan
       ├─ tabel imunisasi
       ├─ tabel pertumbuhan (jika BB & TB diisi)
       ├─ jadwal_imunisasi baru (jika jadwal berikutnya diisi)
       └─ notifikasi ke orang tua
```

---

### 2.4 Perhitungan Otomatis Saat Input Imunisasi

- **Usia balita** dihitung otomatis: `tanggal_imunisasi - tanggal_lahir` dalam bulan
- **Status gizi** dihitung via `GrowthStatusHelper`:
  - Berat badan terhadap usia → `statusBeratBadan`
  - Tinggi badan terhadap usia → `statusTinggiBadan`
  - Berat badan terhadap tinggi badan → `statusGizi`

---

### 2.5 Jadwal Posyandu

```
Dashboard Kader → Jadwal Posyandu
  ├─ Lihat daftar jadwal
  ├─ Tambah jadwal (judul, deskripsi, tanggal, jam, lokasi)
  └─ Edit / Hapus jadwal
```

Semua user yang login dapat membaca jadwal posyandu.

---

### 2.6 Laporan

```
Dashboard Kader → Laporan
  ├─ Pilih jenis laporan (balita / imunisasi / pertumbuhan / jadwal imunisasi)
  ├─ Pilih format (PDF / Excel)
  └─ Export / Share
```

---

### 2.7 Edukasi (Kader)

```
Dashboard Kader → Kelola Edukasi
  ├─ Pilih / buat kategori
  ├─ Tambah artikel (judul, isi, gambar, kategori)
  └─ Edit / Hapus artikel
```

---

## 3. Alur Orang Tua

### 3.1 Registrasi Balita

```
Dashboard Orang Tua → Daftar Balita
  └─ Tambah Balita
       └─ Isi data (NIK, nama, tempat & tanggal lahir, jenis kelamin, dll.)
       └─ Simpan → status: 'pending'
            └─ Tunggu verifikasi kader
                 ├─ Disetujui → status: 'disetujui'
                 └─ Ditolak  → status: 'ditolak'
```

---

### 3.2 Dashboard Pertumbuhan

```
Dashboard Orang Tua → Pertumbuhan
  └─ Pilih balita
  └─ Grafik berat badan & tinggi badan per usia bulan
  └─ Status gizi tiap pemeriksaan
       ├─ Normal
       ├─ Gizi Kurang / Buruk
       ├─ Risiko Gizi Lebih / Gizi Lebih / Obesitas
       └─ Risiko Stunting / Stunting
```

---

### 3.3 Riwayat & Agenda Imunisasi

```
Dashboard Orang Tua
  ├─ Riwayat Imunisasi → daftar imunisasi yang sudah dilakukan
  └─ Agenda Imunisasi  → jadwal imunisasi mendatang berdasarkan usia balita
```

---

### 3.4 Notifikasi

Orang tua menerima notifikasi dari:

| Trigger | Isi Notifikasi |
|---------|---------------|
| Kader simpan imunisasi | Hasil imunisasi balita telah dicatat |
| Kader verifikasi balita | Status verifikasi disetujui / ditolak |
| Jadwal posyandu baru | Pengumuman kegiatan posyandu |

Alur notifikasi:
```
Kader aksi (simpan imunisasi / verifikasi / buat jadwal)
  └─ Insert ke tabel notifications (user_id = parent_id)
       └─ Supabase Realtime subscribe di sisi orang tua
            └─ Simpan ke Hive
            └─ Tampilkan Flutter Local Notification
            └─ Update badge notifikasi di aplikasi
```

---

## 4. Alur Data Lintas Fitur

```
Balita (tabel balita)
  │
  ├─ Jadwal Imunisasi (tabel jadwal_imunisasi)
  │    └─ referensi jenis_imunisasi (tabel jenis_imunisasi)
  │
  ├─ Imunisasi (tabel imunisasi)
  │    └─ referensi jenis_imunisasi
  │    └─ trigger → tabel pertumbuhan (jika BB & TB diisi)
  │    └─ trigger → tabel notifications
  │
  └─ Pertumbuhan (tabel pertumbuhan)
       └─ status gizi dihitung via GrowthStatusHelper (lokal)
```

---

## 5. Role & Akses (RLS)

| Tabel | Kader | Orang Tua |
|-------|-------|-----------|
| profiles | Baca semua | Baca & edit milik sendiri |
| balita | Semua akses | Baca & tambah milik sendiri |
| imunisasi | Semua akses | Baca balita milik sendiri |
| pertumbuhan | Semua akses | Baca balita milik sendiri |
| jadwal_imunisasi | Semua akses | Baca balita milik sendiri |
| jadwal_posyandu | Tambah/edit/hapus | Baca saja |
| notifications | Kirim ke siapapun | Baca & update milik sendiri |
| edukasi | Tambah/edit/hapus | Baca saja |
| jenis_imunisasi | Tambah/edit/hapus | Baca saja |
