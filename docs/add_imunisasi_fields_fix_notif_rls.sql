-- Migration: Tambah kolom suhu_badan & lingkar_kepala + fix RLS notifikasi
-- Jalankan di Supabase SQL Editor (dashboard.supabase.com)

-- ============================================================
-- 1. Tambah kolom suhu_badan dan lingkar_kepala ke tabel imunisasi
-- ============================================================
ALTER TABLE imunisasi ADD COLUMN IF NOT EXISTS suhu_badan NUMERIC;
ALTER TABLE imunisasi ADD COLUMN IF NOT EXISTS lingkar_kepala NUMERIC;


-- ============================================================
-- 2. Izinkan orang_tua membaca profil kader
--    (dibutuhkan agar getIdSemuaKader() berhasil saat ortu daftar balita)
-- ============================================================
DROP POLICY IF EXISTS "Ortu baca profil kader" ON profiles;
CREATE POLICY "Ortu baca profil kader" ON profiles
  FOR SELECT TO authenticated
  USING (role = 'kader' AND get_user_role() = 'orang_tua');


-- ============================================================
-- 3. Izinkan orang_tua insert notifikasi ke kader
--    (dibutuhkan agar buatNotifikasiMassal() berhasil saat ortu daftar balita)
-- ============================================================
DROP POLICY IF EXISTS "Ortu kirim notifikasi" ON notifications;
CREATE POLICY "Ortu kirim notifikasi" ON notifications
  FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'orang_tua');
