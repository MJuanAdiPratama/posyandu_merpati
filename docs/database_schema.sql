-- Catatan:
-- Untuk setup database baru, pakai file lengkap:
-- docs/database_setup.sql
--
-- File ini hanya berisi schema inti.
-- Lihat juga supabase/migrations/20260714090000_notif_data_belum_lengkap_dan_laporan_bulanan.sql
-- untuk notifikasi kader "Data Belum Lengkap" dan "Laporan Bulanan".

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nama text not null,
  email text not null,
  no_hp text,
  alamat text,
  role text not null check (role in ('kader', 'orang_tua')),
  created_at timestamp with time zone default now()
);

create table balita (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references profiles(id) on delete set null,
  nik text not null,
  nama text not null,
  tempat_lahir text,
  tanggal_lahir date not null,
  jenis_kelamin text not null check (jenis_kelamin in ('Laki-laki', 'Perempuan')),
  nama_ortu text not null,
  kontak_ortu text,
  alamat text,
  status_verifikasi text not null default 'pending'
    check (status_verifikasi in ('pending', 'disetujui', 'ditolak')),
  notif_data_belum_lengkap_terkirim boolean not null default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create table jenis_imunisasi (
  id uuid primary key default gen_random_uuid(),
  nama_imunisasi text not null,
  usia_bulan int not null,
  deskripsi text,
  kandungan text,
  created_at timestamp with time zone default now()
);

create table imunisasi (
  id uuid primary key default gen_random_uuid(),
  balita_id uuid not null references balita(id) on delete cascade,
  jenis_imunisasi_id uuid references jenis_imunisasi(id) on delete set null,
  tanggal_imunisasi date not null,
  berat_badan numeric,
  tinggi_badan numeric,
  catatan text,
  petugas_id uuid references profiles(id) on delete set null,
  created_at timestamp with time zone default now()
);

create table pertumbuhan (
  id uuid primary key default gen_random_uuid(),
  balita_id uuid not null references balita(id) on delete cascade,
  tanggal_pemeriksaan date not null,
  usia_bulan int not null,
  berat_badan numeric not null,
  tinggi_badan numeric not null,
  status_gizi text,
  status_tinggi_badan text,
  status_berat_badan text,
  status_pertumbuhan text,
  catatan text,
  created_at timestamp with time zone default now()
);

create table jadwal_imunisasi (
  id uuid primary key default gen_random_uuid(),
  balita_id uuid not null references balita(id) on delete cascade,
  jenis_imunisasi_id uuid references jenis_imunisasi(id) on delete set null,
  tanggal_jadwal date not null,
  status text not null default 'terjadwal'
    check (status in ('terjadwal', 'selesai', 'terlambat', 'dibatalkan')),
  reminder_terkirim boolean not null default false,
  created_at timestamp with time zone default now()
);

create table jadwal_posyandu (
  id uuid primary key default gen_random_uuid(),
  judul text not null,
  deskripsi text,
  tanggal date not null,
  jam_mulai time,
  jam_selesai time,
  lokasi text,
  created_by uuid references profiles(id) on delete set null,
  reminder_terkirim boolean not null default false,
  created_at timestamp with time zone default now()
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  balita_id uuid references balita(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null
    check (type in ('hasil_imunisasi', 'pertumbuhan', 'reminder', 'pengumuman', 'verifikasi')),
  scheduled_at timestamp with time zone,
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

create table edukasi_kategori (
  id uuid primary key default gen_random_uuid(),
  nama text not null unique,
  deskripsi text,
  created_at timestamp with time zone default now()
);

create table edukasi (
  id uuid primary key default gen_random_uuid(),
  judul text not null,
  isi text not null,
  ringkasan text,
  kategori_id uuid references edukasi_kategori(id) on delete set null,
  kategori text,
  gambar_url text,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamp with time zone default now()
);
