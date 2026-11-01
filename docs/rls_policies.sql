-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip/incremental lama.
-- ============================================================
-- RLS POLICIES - Posyandu Merpati
-- Jalankan di Supabase SQL Editor (dashboard.supabase.com)
-- Jalankan SETELAH database_schema.sql
-- ============================================================
-- ============================================================
-- HELPER FUNCTION: cek role user yang sedang login
-- ============================================================
CREATE OR REPLACE FUNCTION get_user_role() RETURNS TEXT AS $$
SELECT role
FROM profiles
WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;
-- ============================================================
-- ENABLE RLS pada semua tabel
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE balita ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_imunisasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE imunisasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE pertumbuhan ENABLE ROW LEVEL SECURITY;
ALTER TABLE jadwal_imunisasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE jadwal_posyandu ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE edukasi_kategori ENABLE ROW LEVEL SECURITY;
ALTER TABLE edukasi ENABLE ROW LEVEL SECURITY;
-- ============================================================
-- PROFILES
-- ============================================================
CREATE POLICY "User buat profil sendiri" ON profiles FOR
INSERT TO authenticated WITH CHECK (id = auth.uid());
CREATE POLICY "User baca profil sendiri" ON profiles FOR
SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "Kader baca semua profil" ON profiles FOR
SELECT TO authenticated USING (get_user_role() = 'kader');
CREATE POLICY "User update profil sendiri" ON profiles FOR
UPDATE TO authenticated USING (id = auth.uid());
-- ============================================================
-- BALITA
-- ============================================================
-- Kader dapat akses semua balita
CREATE POLICY "Kader akses semua balita" ON balita FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');
-- Orang tua baca balita miliknya
CREATE POLICY "Ortu baca balita sendiri" ON balita FOR
SELECT TO authenticated USING (parent_id = auth.uid());
-- Orang tua daftar balita baru
-- Cukup cek parent_id = auth.uid() tanpa cek role karena get_user_role()
-- bisa return NULL saat RLS dievaluasi jika profile belum terbaca
CREATE POLICY "Ortu daftar balita baru" ON balita FOR
INSERT TO authenticated WITH CHECK (parent_id = auth.uid());
-- ============================================================
-- MASTER IMUNISASI
-- ============================================================
CREATE POLICY "Semua baca master imunisasi" ON master_imunisasi FOR
SELECT TO authenticated USING (true);
CREATE POLICY "Kader kelola master imunisasi" ON master_imunisasi FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');
-- ============================================================
-- IMUNISASI
-- ============================================================
CREATE POLICY "Kader akses semua imunisasi" ON imunisasi FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');
CREATE POLICY "Ortu baca imunisasi balita sendiri" ON imunisasi FOR
SELECT TO authenticated USING (
    EXISTS (
      SELECT 1
      FROM balita
      WHERE balita.id = imunisasi.balita_id
        AND balita.parent_id = auth.uid()
    )
  );
-- ============================================================
-- PERTUMBUHAN
-- ============================================================
CREATE POLICY "Kader akses semua pertumbuhan" ON pertumbuhan FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');
CREATE POLICY "Ortu baca pertumbuhan balita sendiri" ON pertumbuhan FOR
SELECT TO authenticated USING (
    EXISTS (
      SELECT 1
      FROM balita
      WHERE balita.id = pertumbuhan.balita_id
        AND balita.parent_id = auth.uid()
    )
  );
-- ============================================================
-- JADWAL IMUNISASI
-- ============================================================
CREATE POLICY "Kader akses jadwal imunisasi" ON jadwal_imunisasi FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');
CREATE POLICY "Ortu baca jadwal imunisasi balita sendiri" ON jadwal_imunisasi FOR
SELECT TO authenticated USING (
    EXISTS (
      SELECT 1
      FROM balita
      WHERE balita.id = jadwal_imunisasi.balita_id
        AND balita.parent_id = auth.uid()
    )
  );
-- ============================================================
-- JADWAL POSYANDU
-- ============================================================
-- Semua user yang login bisa baca jadwal posyandu
CREATE POLICY "Semua baca jadwal posyandu" ON jadwal_posyandu FOR
SELECT TO authenticated USING (true);
-- Hanya kader yang bisa tambah/edit/hapus
CREATE POLICY "Kader kelola jadwal posyandu" ON jadwal_posyandu FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');
-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE POLICY "User baca notifikasi sendiri" ON notifications FOR
SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "User tandai notifikasi dibaca" ON notifications FOR
UPDATE TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Kader kirim notifikasi" ON notifications FOR
INSERT TO authenticated WITH CHECK (get_user_role() = 'kader');
-- Izinkan orang_tua insert notifikasi (untuk kirim ke kader saat daftar balita)
CREATE POLICY "Ortu kirim notifikasi" ON notifications FOR
INSERT TO authenticated WITH CHECK (get_user_role() = 'orang_tua');
CREATE POLICY "notifications: delete sendiri" ON notifications FOR DELETE TO authenticated USING (auth.uid() = user_id);
-- ============================================================
-- EDUKASI
-- ============================================================
-- Semua user yang login bisa baca kategori edukasi
CREATE POLICY "Semua baca kategori edukasi" ON edukasi_kategori FOR
SELECT TO authenticated USING (true);
-- Hanya kader yang bisa tambah/edit/hapus kategori edukasi
CREATE POLICY "Kader kelola kategori edukasi" ON edukasi_kategori FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');
-- Semua user yang login bisa baca edukasi
CREATE POLICY "Semua baca edukasi" ON edukasi FOR
SELECT TO authenticated USING (true);
-- Hanya kader yang bisa tambah/edit/hapus
CREATE POLICY "Kader kelola edukasi" ON edukasi FOR ALL TO authenticated USING (get_user_role() = 'kader') WITH CHECK (get_user_role() = 'kader');