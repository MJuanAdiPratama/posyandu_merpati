-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip seed lama.

-- ============================================================
-- SEED DATA - Posyandu Merpati
-- Jalankan di Supabase SQL Editor (dashboard.supabase.com)
-- Urutan: auth.users → profiles → master_imunisasi →
--         balita → imunisasi → pertumbuhan →
--         jadwal_imunisasi → jadwal_posyandu → kategori edukasi → edukasi → notifications
-- ============================================================

-- ============================================================
-- 0. CLEANUP DATA LAMA (aman dijalankan berkali-kali)
-- Hapus urutan terbalik untuk menghindari FK violation
-- ============================================================

-- Tabel aplikasi (cast uuid ke text agar bisa pakai LIKE)
DELETE FROM notifications    WHERE id::text LIKE '80000000%';
DELETE FROM edukasi          WHERE id::text LIKE 'e0000000%';
DELETE FROM edukasi_kategori WHERE id::text LIKE '90000000%';
DELETE FROM jadwal_posyandu  WHERE id::text LIKE '70000000%';
DELETE FROM jadwal_imunisasi WHERE id::text LIKE '60000000%';
DELETE FROM pertumbuhan      WHERE id::text LIKE '50000000%';
DELETE FROM imunisasi        WHERE id::text LIKE 'd0000000%';
DELETE FROM balita           WHERE id::text LIKE 'b0000000%';
DELETE FROM master_imunisasi WHERE id::text LIKE 'c0000000%';
DELETE FROM profiles         WHERE id::text LIKE 'a0000000%';

-- Auth (hapus identities dulu sebelum users)
DELETE FROM auth.identities
  WHERE user_id IN (
    'a0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000003'
  );
DELETE FROM auth.users
  WHERE id IN (
    'a0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000003'
  );


-- ============================================================
-- PASTIKAN EXTENSION PGCRYPTO AKTIF
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================
-- 1. AUTH USERS
-- Akun login untuk testing:
--   Kader  : kader@posyandu.com    / kader123
--   Ortu 1 : rina@posyandu.com     / ortu123
--   Ortu 2 : hendra@posyandu.com   / ortu123
-- ============================================================

INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES
  -- Kader
  (
    'a0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'kader@posyandu.com',
    crypt('kader123', gen_salt('bf')),
    now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    false, now(), now(), '', '', '', ''
  ),
  -- Orang Tua 1
  (
    'a0000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'rina@posyandu.com',
    crypt('ortu123', gen_salt('bf')),
    now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    false, now(), now(), '', '', '', ''
  ),
  -- Orang Tua 2
  (
    'a0000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'hendra@posyandu.com',
    crypt('ortu123', gen_salt('bf')),
    now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    false, now(), now(), '', '', '', ''
  );

-- Identity records (diperlukan agar login email berfungsi)
INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
) VALUES
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000001',
    'kader@posyandu.com',
    jsonb_build_object('sub', 'a0000000-0000-0000-0000-000000000001', 'email', 'kader@posyandu.com'),
    'email', now(), now(), now()
  ),
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000002',
    'rina@posyandu.com',
    jsonb_build_object('sub', 'a0000000-0000-0000-0000-000000000002', 'email', 'rina@posyandu.com'),
    'email', now(), now(), now()
  ),
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000003',
    'hendra@posyandu.com',
    jsonb_build_object('sub', 'a0000000-0000-0000-0000-000000000003', 'email', 'hendra@posyandu.com'),
    'email', now(), now(), now()
  );


-- ============================================================
-- 2. PROFILES
-- ============================================================

INSERT INTO profiles (id, nama, email, no_hp, alamat, role) VALUES
  (
    'a0000000-0000-0000-0000-000000000001',
    'Bidan Sari Dewi',
    'kader@posyandu.com',
    '081234567890',
    'Jl. Mawar No. 5, RT 02 RW 03, Kelurahan Merpati',
    'kader'
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    'Rina Wati',
    'rina@posyandu.com',
    '082345678901',
    'Jl. Melati No. 12, RT 01 RW 02, Kelurahan Merpati',
    'orang_tua'
  ),
  (
    'a0000000-0000-0000-0000-000000000003',
    'Hendra Kusuma',
    'hendra@posyandu.com',
    '083456789012',
    'Jl. Anggrek No. 7, RT 03 RW 01, Kelurahan Merpati',
    'orang_tua'
  );


-- ============================================================
-- 3. MASTER IMUNISASI (Jadwal Imunisasi Nasional Indonesia)
-- ============================================================

INSERT INTO master_imunisasi (id, nama_imunisasi, usia_bulan, deskripsi) VALUES
  (
    'c0000000-0000-0000-0000-000000000001',
    'HB0',
    0,
    'Hepatitis B dosis pertama, diberikan segera setelah lahir (0-24 jam)'
  ),
  (
    'c0000000-0000-0000-0000-000000000002',
    'BCG',
    1,
    'Bacillus Calmette-Guérin, mencegah tuberkulosis (TBC) berat'
  ),
  (
    'c0000000-0000-0000-0000-000000000003',
    'Polio 1',
    1,
    'Poliomielitis dosis pertama (OPV), mencegah kelumpuhan akibat polio'
  ),
  (
    'c0000000-0000-0000-0000-000000000004',
    'DPT-HB-Hib 1',
    2,
    'Difteri, Pertusis, Tetanus, Hepatitis B, Haemophilus influenzae tipe b - dosis 1'
  ),
  (
    'c0000000-0000-0000-0000-000000000005',
    'Polio 2',
    2,
    'Poliomielitis dosis kedua (OPV)'
  ),
  (
    'c0000000-0000-0000-0000-000000000006',
    'DPT-HB-Hib 2',
    3,
    'Difteri, Pertusis, Tetanus, Hepatitis B, Haemophilus influenzae tipe b - dosis 2'
  ),
  (
    'c0000000-0000-0000-0000-000000000007',
    'Polio 3',
    3,
    'Poliomielitis dosis ketiga (OPV)'
  ),
  (
    'c0000000-0000-0000-0000-000000000008',
    'DPT-HB-Hib 3',
    4,
    'Difteri, Pertusis, Tetanus, Hepatitis B, Haemophilus influenzae tipe b - dosis 3'
  ),
  (
    'c0000000-0000-0000-0000-000000000009',
    'Polio 4 (IPV)',
    4,
    'Poliomielitis dosis keempat (IPV - Inactivated Polio Vaccine)'
  ),
  (
    'c0000000-0000-0000-0000-000000000010',
    'Campak/MR',
    9,
    'Measles-Rubella, mencegah campak dan rubella (campak Jerman)'
  ),
  (
    'c0000000-0000-0000-0000-000000000011',
    'DPT-HB-Hib Booster',
    18,
    'Booster DPT-HB-Hib pada usia 18 bulan'
  ),
  (
    'c0000000-0000-0000-0000-000000000012',
    'Campak/MR Booster',
    18,
    'Booster Campak-Rubella pada usia 18 bulan'
  );


-- ============================================================
-- 4. BALITA
-- Tanggal lahir disesuaikan agar usia sekarang (Mei 2026):
--   Arjuna  : lahir Sep 2025 → ±8 bulan
--   Siti    : lahir Mar 2025 → ±14 bulan
--   Budi    : lahir May 2024 → ±24 bulan (pending verifikasi)
--   Naila   : lahir Jan 2026 → ±4 bulan
-- ============================================================

INSERT INTO balita (
  id, parent_id, nik, nama, tempat_lahir,
  tanggal_lahir, jenis_kelamin, nama_ortu,
  kontak_ortu, alamat, status_verifikasi
) VALUES
  -- Arjuna (anak Rina, 8 bulan, laki-laki)
  (
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000002',
    '3201010910250001',
    'Arjuna Pratama',
    'Jakarta',
    '2025-09-10',
    'Laki-laki',
    'Rina Wati',
    '082345678901',
    'Jl. Melati No. 12, RT 01 RW 02',
    'disetujui'
  ),
  -- Siti Aisyah (anak Rina, 14 bulan, perempuan)
  (
    'b0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000002',
    '3201012003250001',
    'Siti Aisyah',
    'Bandung',
    '2025-03-20',
    'Perempuan',
    'Rina Wati',
    '082345678901',
    'Jl. Melati No. 12, RT 01 RW 02',
    'disetujui'
  ),
  -- Budi Santoso (anak Hendra, 24 bulan, laki-laki)
  (
    'b0000000-0000-0000-0000-000000000003',
    'a0000000-0000-0000-0000-000000000003',
    '3201011505240001',
    'Budi Santoso',
    'Bogor',
    '2024-05-15',
    'Laki-laki',
    'Hendra Kusuma',
    '083456789012',
    'Jl. Anggrek No. 7, RT 03 RW 01',
    'disetujui'
  ),
  -- Naila Zahira (anak Hendra, 4 bulan, perempuan, pending)
  (
    'b0000000-0000-0000-0000-000000000004',
    'a0000000-0000-0000-0000-000000000003',
    '3201012001260001',
    'Naila Zahira',
    'Depok',
    '2026-01-20',
    'Perempuan',
    'Hendra Kusuma',
    '083456789012',
    'Jl. Anggrek No. 7, RT 03 RW 01',
    'pending'
  );


-- ============================================================
-- 5. IMUNISASI (Riwayat imunisasi yang sudah dilakukan)
-- ============================================================

INSERT INTO imunisasi (
  id, balita_id, master_imunisasi_id,
  tanggal_imunisasi, berat_badan, tinggi_badan,
  catatan, petugas_id
) VALUES
  -- Arjuna: HB0 (lahir Sep 2025)
  (
    'd0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    '2025-09-10', 3.2, 50.0,
    'Bayi lahir normal, kondisi sehat',
    'a0000000-0000-0000-0000-000000000001'
  ),
  -- Arjuna: BCG + Polio 1 (1 bulan)
  (
    'd0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000002',
    '2025-10-12', 4.5, 54.0,
    'Reaksi BCG normal, bekas suntik di lengan kiri',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'd0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000003',
    '2025-10-12', 4.5, 54.0,
    'OPV diteteskan 2 tetes per oral',
    'a0000000-0000-0000-0000-000000000001'
  ),
  -- Arjuna: DPT+Polio 1 (2 bulan)
  (
    'd0000000-0000-0000-0000-000000000004',
    'b0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000004',
    '2025-11-15', 5.5, 57.0,
    'Demam ringan 1 hari pasca imunisasi, sudah membaik',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'd0000000-0000-0000-0000-000000000005',
    'b0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000005',
    '2025-11-15', 5.5, 57.0,
    NULL,
    'a0000000-0000-0000-0000-000000000001'
  ),
  -- Arjuna: DPT 2+Polio 2 (3 bulan)
  (
    'd0000000-0000-0000-0000-000000000006',
    'b0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000006',
    '2025-12-18', 6.2, 60.0,
    'Kondisi baik, tidak ada efek samping berarti',
    'a0000000-0000-0000-0000-000000000001'
  ),
  -- Siti Aisyah: HB0 (Mar 2025)
  (
    'd0000000-0000-0000-0000-000000000007',
    'b0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    '2025-03-20', 3.1, 49.0,
    'Bayi lahir sehat',
    'a0000000-0000-0000-0000-000000000001'
  ),
  -- Siti Aisyah: BCG+Polio 1 (1 bulan)
  (
    'd0000000-0000-0000-0000-000000000008',
    'b0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000002',
    '2025-04-22', 4.2, 53.0,
    NULL,
    'a0000000-0000-0000-0000-000000000001'
  ),
  -- Siti Aisyah: DPT 1+2+3, Polio 1+2+3, Campak (lengkap)
  (
    'd0000000-0000-0000-0000-000000000009',
    'b0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000004',
    '2025-05-22', 5.0, 56.0,
    NULL, '2025-06-22',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'd0000000-0000-0000-0000-000000000010',
    'b0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000006',
    '2025-06-25', 5.8, 59.0,
    NULL, '2025-07-25',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'd0000000-0000-0000-0000-000000000011',
    'b0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000008',
    '2025-07-24', 6.5, 62.0,
    NULL, '2025-12-20',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'd0000000-0000-0000-0000-000000000012',
    'b0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000010',
    '2025-12-22', 8.2, 70.0,
    'Campak/MR 9 bulan, tidak ada reaksi',
    '2026-09-22',
    'a0000000-0000-0000-0000-000000000001'
  ),
  -- Budi Santoso: beberapa imunisasi awal
  (
    'd0000000-0000-0000-0000-000000000013',
    'b0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000001',
    '2024-05-15', 3.3, 50.5,
    NULL, '2024-06-15',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'd0000000-0000-0000-0000-000000000014',
    'b0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000010',
    '2025-02-17', 9.0, 72.0,
    'Campak/MR 9 bulan',
    '2026-11-17',
    'a0000000-0000-0000-0000-000000000001'
  );


-- ============================================================
-- 6. PERTUMBUHAN
-- ============================================================

INSERT INTO pertumbuhan (
  id, balita_id, tanggal_pemeriksaan,
  usia_bulan, berat_badan, tinggi_badan,
  status_gizi, status_tinggi_badan, status_berat_badan,
  status_pertumbuhan, catatan
) VALUES
  -- Arjuna pertumbuhan bulanan
  ('50000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '2025-09-10', 0,  3.2, 50.0, 'Normal', 'Normal', 'Normal', 'Normal', 'Lahir normal'),
  ('50000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', '2025-10-12', 1,  4.5, 54.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', '2025-11-15', 2,  5.5, 57.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', '2025-12-18', 3,  6.2, 60.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000001', '2026-01-20', 4,  6.8, 62.5, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000001', '2026-02-18', 5,  7.3, 64.5, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000001', '2026-03-20', 6,  7.9, 66.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000008', 'b0000000-0000-0000-0000-000000000001', '2026-04-18', 7,  8.3, 67.5, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000009', 'b0000000-0000-0000-0000-000000000001', '2026-05-15', 8,  8.7, 69.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),

  -- Siti Aisyah pertumbuhan
  ('50000000-0000-0000-0000-000000000010', 'b0000000-0000-0000-0000-000000000002', '2025-03-20', 0,  3.1, 49.0, 'Normal', 'Normal', 'Normal', 'Normal', 'Lahir normal'),
  ('50000000-0000-0000-0000-000000000011', 'b0000000-0000-0000-0000-000000000002', '2025-04-22', 1,  4.2, 53.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000012', 'b0000000-0000-0000-0000-000000000002', '2025-05-22', 2,  5.0, 56.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000013', 'b0000000-0000-0000-0000-000000000002', '2025-07-24', 4,  6.3, 61.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000014', 'b0000000-0000-0000-0000-000000000002', '2025-09-25', 6,  7.1, 65.5, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000015', 'b0000000-0000-0000-0000-000000000002', '2025-12-22', 9,  8.2, 70.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000016', 'b0000000-0000-0000-0000-000000000002', '2026-03-22', 12, 9.1, 74.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000017', 'b0000000-0000-0000-0000-000000000002', '2026-05-20', 14, 9.5, 76.0, 'Normal', 'Normal', 'Normal', 'Normal', NULL),

  -- Budi Santoso pertumbuhan
  ('50000000-0000-0000-0000-000000000018', 'b0000000-0000-0000-0000-000000000003', '2024-05-15',  0,  3.3, 50.5, 'Normal',     'Normal', 'Normal', 'Normal', 'Lahir normal'),
  ('50000000-0000-0000-0000-000000000019', 'b0000000-0000-0000-0000-000000000003', '2024-08-20',  3,  6.0, 60.5, 'Normal',     'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000020', 'b0000000-0000-0000-0000-000000000003', '2024-11-18',  6,  7.5, 67.0, 'Normal',     'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000021', 'b0000000-0000-0000-0000-000000000003', '2025-02-17',  9,  8.8, 72.0, 'Normal',     'Normal', 'Normal', 'Normal', NULL),
  ('50000000-0000-0000-0000-000000000022', 'b0000000-0000-0000-0000-000000000003', '2025-05-22', 12,  9.4, 75.5, 'Gizi Kurang','Pendek', 'Kurang', 'Risiko Stunting', 'Perlu pemantauan lebih lanjut'),
  ('50000000-0000-0000-0000-000000000023', 'b0000000-0000-0000-0000-000000000003', '2025-08-18', 15, 10.1, 78.0, 'Gizi Kurang','Normal', 'Kurang', 'Normal', 'Ada perbaikan setelah konseling gizi'),
  ('50000000-0000-0000-0000-000000000024', 'b0000000-0000-0000-0000-000000000003', '2026-05-18', 24, 11.8, 87.0, 'Normal',     'Normal', 'Normal', 'Normal', 'Pertumbuhan membaik setelah program PMT');


-- ============================================================
-- 7. JADWAL IMUNISASI
-- ============================================================

INSERT INTO jadwal_imunisasi (
  id, balita_id, master_imunisasi_id, tanggal_jadwal, status
) VALUES
  -- Arjuna: DPT 2 sudah selesai, DPT 3 masih terjadwal
  ('60000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000006', '2025-12-18', 'selesai'),
  ('60000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000008', '2026-01-18', 'selesai'),
  ('60000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000010', '2026-06-10', 'terjadwal'),
  -- Siti Aisyah: Campak booster terjadwal
  ('60000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000011', '2026-09-20', 'terjadwal'),
  ('60000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000012', '2026-09-20', 'terjadwal'),
  -- Budi Santoso: DPT booster terjadwal
  ('60000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000011', '2026-11-17', 'terjadwal'),
  ('60000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000012', '2026-11-17', 'terjadwal');


-- ============================================================
-- 8. JADWAL POSYANDU
-- ============================================================

INSERT INTO jadwal_posyandu (
  id, judul, deskripsi, tanggal,
  jam_mulai, jam_selesai, lokasi, created_by
) VALUES
  (
    '70000000-0000-0000-0000-000000000001',
    'Posyandu Rutin Mei 2026',
    'Kegiatan posyandu bulanan meliputi penimbangan, pengukuran tinggi badan, imunisasi, dan konsultasi gizi.',
    '2026-05-28',
    '08:00', '11:00',
    'Balai RW 03, Jl. Kenanga No. 1',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    'Posyandu Rutin Juni 2026',
    'Kegiatan posyandu bulanan + sosialisasi program PMT (Pemberian Makanan Tambahan).',
    '2026-06-25',
    '08:00', '11:30',
    'Balai RW 03, Jl. Kenanga No. 1',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    'Imunisasi Campak/MR Massal',
    'Kegiatan imunisasi campak dan rubella untuk balita usia 9-59 bulan di wilayah Kelurahan Merpati.',
    '2026-06-10',
    '07:30', '12:00',
    'Puskesmas Kelurahan Merpati',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    '70000000-0000-0000-0000-000000000004',
    'Posyandu Rutin Juli 2026',
    'Kegiatan posyandu bulanan rutin.',
    '2026-07-23',
    '08:00', '11:00',
    'Balai RW 03, Jl. Kenanga No. 1',
    'a0000000-0000-0000-0000-000000000001'
  );


-- ============================================================
-- 9. KATEGORI EDUKASI
-- ============================================================

INSERT INTO edukasi_kategori (id, nama, deskripsi) VALUES
  (
    '90000000-0000-0000-0000-000000000001',
    'Imunisasi',
    'Panduan jadwal, manfaat, dan tindak lanjut imunisasi.'
  ),
  (
    '90000000-0000-0000-0000-000000000002',
    'Gizi',
    'Edukasi makanan, ASI, MPASI, dan pencegahan gizi buruk.'
  ),
  (
    '90000000-0000-0000-0000-000000000003',
    'Tumbuh Kembang',
    'Informasi perkembangan motorik, bahasa, dan sosial balita.'
  ),
  (
    '90000000-0000-0000-0000-000000000004',
    'Kesehatan',
    'Tips menjaga kesehatan harian dan mengenali tanda bahaya.'
  ),
  (
    '90000000-0000-0000-0000-000000000005',
    'Pengasuhan',
    'Panduan pola asuh dan kebiasaan sehat keluarga.'
  );


-- ============================================================
-- 10. EDUKASI
-- ============================================================

INSERT INTO edukasi (id, judul, isi, kategori_id, kategori, created_by) VALUES
  (
    'e0000000-0000-0000-0000-000000000001',
    'Pentingnya Imunisasi untuk Balita',
    'Imunisasi adalah salah satu cara paling efektif untuk melindungi anak dari penyakit berbahaya. Vaksin bekerja dengan merangsang sistem kekebalan tubuh agar mengenali dan melawan kuman penyakit tertentu tanpa harus jatuh sakit terlebih dahulu.

Manfaat imunisasi antara lain:
1. Melindungi anak dari penyakit berbahaya seperti campak, polio, difteri, dan TBC
2. Mencegah penularan penyakit ke anggota keluarga lain
3. Membantu membentuk kekebalan kelompok (herd immunity)
4. Mengurangi risiko komplikasi dan kecacatan akibat penyakit

Jadwal imunisasi lengkap menurut program nasional:
- Lahir: HB0
- 1 bulan: BCG dan Polio 1
- 2 bulan: DPT-HB-Hib 1 dan Polio 2
- 3 bulan: DPT-HB-Hib 2 dan Polio 3
- 4 bulan: DPT-HB-Hib 3 dan Polio 4 (IPV)
- 9 bulan: Campak/MR
- 18 bulan: DPT-HB-Hib Booster dan Campak/MR Booster

Pastikan anak mendapatkan imunisasi tepat waktu. Jika terlambat, segera konsultasikan ke bidan atau dokter terdekat.',
    '90000000-0000-0000-0000-000000000001',
    'Imunisasi',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'e0000000-0000-0000-0000-000000000002',
    'Mengenal Stunting dan Cara Mencegahnya',
    'Stunting adalah kondisi gagal tumbuh pada anak akibat kekurangan gizi kronis dan infeksi berulang. Anak stunting memiliki tinggi badan yang lebih pendek dari standar usianya.

Tanda-tanda stunting:
- Tinggi badan anak di bawah standar WHO untuk usianya
- Perkembangan fisik dan kognitif yang terlambat
- Mudah sakit karena daya tahan tubuh lemah

Cara mencegah stunting:
1. ASI Eksklusif selama 6 bulan pertama
2. Memberikan MPASI bergizi seimbang mulai usia 6 bulan
3. Memantau pertumbuhan anak secara rutin di posyandu
4. Menjaga kebersihan lingkungan dan sanitasi
5. Lengkapi imunisasi anak sesuai jadwal
6. Konsumsi tablet tambah darah selama kehamilan

Jika mendapati tanda-tanda stunting, segera konsultasikan ke tenaga kesehatan. Penanganan dini sangat penting untuk tumbuh kembang optimal anak.',
    '90000000-0000-0000-0000-000000000002',
    'Gizi',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'e0000000-0000-0000-0000-000000000003',
    'MPASI: Makanan Pendamping ASI yang Tepat',
    'MPASI (Makanan Pendamping ASI) diberikan kepada bayi mulai usia 6 bulan, saat ASI saja sudah tidak mencukupi kebutuhan gizi bayi yang semakin bertumbuh.

Prinsip pemberian MPASI:
1. Tepat waktu: mulai usia 6 bulan
2. Adekuat: mengandung zat gizi yang cukup
3. Aman: bebas kuman dan tidak mengandung bahan berbahaya
4. Diberikan dengan cara yang benar (responsive feeding)

Jenis makanan per tahap usia:
- 6-8 bulan: bubur halus, pure sayuran dan buah
- 9-11 bulan: makanan cincang halus, finger food lunak
- 12 bulan ke atas: makanan keluarga yang dicincang

Bahan makanan bergizi untuk MPASI:
- Sumber karbohidrat: nasi, kentang, ubi, jagung
- Sumber protein: daging, ikan, telur, tahu, tempe
- Sumber lemak: minyak kelapa, alpukat
- Sayuran dan buah beragam

Hindari memberikan garam, gula berlebih, madu (untuk bayi < 1 tahun), dan makanan yang berisiko tersedak.',
    '90000000-0000-0000-0000-000000000002',
    'Gizi',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'e0000000-0000-0000-0000-000000000004',
    'Tumbuh Kembang Anak 0-2 Tahun',
    'Dua tahun pertama kehidupan anak dikenal sebagai "1000 Hari Pertama Kehidupan" — masa paling kritis dalam tumbuh kembang. Stimulasi yang tepat di masa ini sangat berpengaruh pada perkembangan otak dan fisik anak.

Milestone perkembangan normal:
- 0-3 bulan: tersenyum sosial, mengikuti gerakan dengan mata
- 4-6 bulan: tertawa keras, mengangkat kepala, berguling
- 7-9 bulan: duduk tanpa bantuan, mulai merangkak
- 10-12 bulan: berdiri berpegangan, mengucapkan "mama/papa"
- 13-18 bulan: berjalan, menumpuk 2 balok, 10-20 kata
- 19-24 bulan: berlari, menyusun kalimat 2 kata, naik tangga

Cara stimulasi yang tepat:
- Bicara dan bernyanyi untuk bayi setiap hari
- Berikan mainan yang aman sesuai usia
- Bacakan buku bergambar sejak bayi
- Berikan kesempatan bayi bergerak bebas

Konsultasikan ke dokter atau bidan jika anak belum mencapai milestone sesuai usianya.',
    '90000000-0000-0000-0000-000000000003',
    'Tumbuh Kembang',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'e0000000-0000-0000-0000-000000000005',
    'Cara Mengatasi Demam pada Bayi dan Balita',
    'Demam adalah suhu tubuh di atas 38°C dan merupakan respons normal tubuh terhadap infeksi. Demam setelah imunisasi juga wajar terjadi.

Cara mengukur suhu tubuh:
- Gunakan termometer digital di ketiak, mulut, atau anus
- Suhu normal: 36.5°C - 37.5°C
- Demam ringan: 37.5°C - 38°C
- Demam: > 38°C
- Demam tinggi: > 39°C

Penanganan demam di rumah:
1. Kompres dengan air hangat (bukan air dingin) di dahi, ketiak, dan lipatan paha
2. Berikan banyak cairan (ASI/air putih/jus)
3. Pakaikan pakaian tipis dan nyaman
4. Berikan obat penurun panas (parasetamol) sesuai dosis berat badan

Segera bawa ke dokter jika:
- Demam > 40°C
- Bayi < 3 bulan dengan demam > 38°C
- Demam lebih dari 3 hari
- Disertai kejang, ruam merah, sulit bernapas, atau tidak mau makan/minum',
    '90000000-0000-0000-0000-000000000004',
    'Kesehatan',
    'a0000000-0000-0000-0000-000000000001'
  );


-- ============================================================
-- 11. NOTIFICATIONS
-- ============================================================

INSERT INTO notifications (
  id, user_id, balita_id, title, message, type, is_read
) VALUES
  -- Notifikasi untuk Rina (ortu Arjuna & Siti)
  (
    '80000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'Hasil Imunisasi Arjuna',
    'Imunisasi DPT-HB-Hib 2 dan Polio 3 untuk Arjuna Pratama telah dicatat pada 18 Desember 2025. Kondisi baik.',
    'hasil_imunisasi',
    true
  ),
  (
    '80000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'Jadwal Imunisasi Mendatang',
    'Arjuna Pratama dijadwalkan imunisasi Campak/MR pada 10 Juni 2026. Pastikan hadir tepat waktu.',
    'reminder',
    false
  ),
  (
    '80000000-0000-0000-0000-000000000003',
    'a0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000002',
    'Hasil Imunisasi Siti Aisyah',
    'Imunisasi Campak/MR untuk Siti Aisyah telah dicatat pada 22 Desember 2025. Tidak ada reaksi berarti.',
    'hasil_imunisasi',
    true
  ),
  (
    '80000000-0000-0000-0000f-000000000004',
    'a0000000-0000-0000-0000-000000000002',
    NULL,
    'Jadwal Posyandu Mei 2026',
    'Posyandu rutin bulan Mei 2026 akan diadakan pada Rabu, 28 Mei 2026 pukul 08.00-11.00 di Balai RW 03. Harap membawa buku KIA.',
    'pengumuman',
    false
  ),
  -- Notifikasi untuk Hendra
  (
    '80000000-0000-0000-0000-000000000005',
    'a0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000003',
    'Pemantauan Gizi Budi',
    'Berdasarkan data pertumbuhan terakhir, kondisi gizi Budi Santoso sudah membaik. Teruskan program PMT dan pola makan bergizi.',
    'hasil_imunisasi',
    true
  ),
  (
    '80000000-0000-0000-0000-000000000006',
    'a0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000004',
    'Registrasi Balita Menunggu Verifikasi',
    'Data balita Naila Zahira yang Anda daftarkan sedang menunggu verifikasi oleh kader. Proses verifikasi biasanya 1-2 hari kerja.',
    'verifikasi',
    false
  ),
  (
    '80000000-0000-0000-0000-000000000007',
    'a0000000-0000-0000-0000-000000000003',
    NULL,
    'Pengumuman Imunisasi Massal',
    'Akan diadakan imunisasi Campak/MR massal pada 10 Juni 2026 di Puskesmas Kelurahan Merpati. Bawa buku KIA dan kartu imunisasi.',
    'pengumuman',
    false
  );


-- ============================================================
-- VERIFIKASI DATA
-- Jalankan query ini untuk memastikan data berhasil masuk
-- ============================================================
/*
SELECT 'profiles'        AS tabel, COUNT(*) AS jumlah FROM profiles
UNION ALL
SELECT 'balita',          COUNT(*) FROM balita
UNION ALL
SELECT 'master_imunisasi',COUNT(*) FROM master_imunisasi
UNION ALL
SELECT 'imunisasi',       COUNT(*) FROM imunisasi
UNION ALL
SELECT 'pertumbuhan',     COUNT(*) FROM pertumbuhan
UNION ALL
SELECT 'jadwal_imunisasi',COUNT(*) FROM jadwal_imunisasi
UNION ALL
SELECT 'jadwal_posyandu', COUNT(*) FROM jadwal_posyandu
UNION ALL
SELECT 'edukasi',         COUNT(*) FROM edukasi
UNION ALL
SELECT 'notifications',   COUNT(*) FROM notifications;
*/
