-- ============================================================
-- DATABASE DROP ALL - Posyandu Merpati
-- PERINGATAN: SQL ini destruktif.
--
-- Pakai file ini kalau ingin mengosongkan database dan menghapus
-- semua tabel aplikasi Posyandu Merpati dari Supabase.
--
-- Catatan:
-- - DROP TABLE sudah otomatis menghapus semua isi tabel.
-- - Supabase tidak mengizinkan delete langsung dari tabel storage.objects
--   dan storage.buckets. Hapus file/bucket lewat Dashboard Storage atau
--   Storage API kalau memang perlu.
-- - Bagian TRUNCATE disediakan kalau hanya ingin hapus data tanpa
--   menghapus struktur tabel.
-- - Jalankan salah satu bagian saja sesuai kebutuhan.
-- ============================================================


-- ============================================================
-- OPSI A: HAPUS SEMUA ISI TABEL SAJA
-- Struktur tabel, RLS, policy, trigger, dan function tetap ada.
-- ============================================================

/*
begin;

truncate table
  public.user_devices,
  public.notifications,
  public.edukasi,
  public.edukasi_kategori,
  public.jadwal_posyandu,
  public.jadwal_imunisasi,
  public.pertumbuhan,
  public.imunisasi,
  public.jenis_imunisasi,
  public.balita,
  public.profiles
restart identity cascade;

-- Supabase Storage tidak boleh dihapus langsung lewat SQL.
-- Hapus isi bucket `edukasi-images` lewat Dashboard Storage atau Storage API.

delete from auth.identities
where user_id in (
  select id
  from auth.users
  where email in (
    'kader@posyandu.com',
    'rina@posyandu.com',
    'hendra@posyandu.com'
  )
);

delete from auth.users
where email in (
  'kader@posyandu.com',
  'rina@posyandu.com',
  'hendra@posyandu.com'
);

commit;
*/


-- ============================================================
-- OPSI B: HAPUS SEMUA ISI TABEL DAN HAPUS TABEL
-- Ini yang biasanya dipakai sebelum setup ulang dari nol.
-- ============================================================

begin;

-- Supabase Storage tidak boleh dihapus langsung lewat SQL.
-- Hapus isi bucket `edukasi-images` lewat Dashboard Storage atau Storage API.

-- Bersihkan akun testing dari seed data.
delete from auth.identities
where user_id in (
  select id
  from auth.users
  where email in (
    'kader@posyandu.com',
    'rina@posyandu.com',
    'hendra@posyandu.com'
  )
);

delete from auth.users
where email in (
  'kader@posyandu.com',
  'rina@posyandu.com',
  'hendra@posyandu.com'
);

-- Drop tabel aplikasi. Urutan dibuat dari tabel anak ke induk.
drop table if exists public.user_devices cascade;
drop table if exists public.notifications cascade;
drop table if exists public.edukasi cascade;
drop table if exists public.edukasi_kategori cascade;
drop table if exists public.jadwal_posyandu cascade;
drop table if exists public.jadwal_imunisasi cascade;
drop table if exists public.pertumbuhan cascade;
drop table if exists public.imunisasi cascade;
drop table if exists public.jenis_imunisasi cascade;
drop table if exists public.balita cascade;
drop table if exists public.profiles cascade;

-- Drop helper function aplikasi.
drop function if exists public.get_user_role() cascade;
drop function if exists public.set_updated_at() cascade;

commit;
