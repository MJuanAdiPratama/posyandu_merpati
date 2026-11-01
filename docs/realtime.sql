-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip/incremental lama.

-- ============================================================
-- Supabase Realtime Setup - Posyandu Merpati
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Aktifkan Realtime untuk tabel yang dibutuhkan
-- Jika publication belum ada, buat dulu:
do $$
begin
  if not exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) then
    create publication supabase_realtime;
  end if;
end
$$;

-- SET TABLE menggantikan daftar tabel sekaligus (aman dijalankan ulang)
alter publication supabase_realtime
  set table
    profiles,
    balita,
    master_imunisasi,
    imunisasi,
    pertumbuhan,
    jadwal_imunisasi,
    jadwal_posyandu,
    notifications,
    edukasi_kategori,
    edukasi;

-- ============================================================
-- 2. Row Level Security (RLS)
-- Supabase Realtime mematuhi RLS — pastikan RLS aktif
-- agar data hanya terkirim ke user yang berhak.
-- ============================================================

alter table balita           enable row level security;
alter table imunisasi        enable row level security;
alter table pertumbuhan      enable row level security;
alter table jadwal_imunisasi enable row level security;
alter table jadwal_posyandu  enable row level security;
alter table notifications    enable row level security;
alter table profiles         enable row level security;
alter table master_imunisasi enable row level security;
alter table edukasi          enable row level security;
alter table edukasi_kategori enable row level security;

-- ============================================================
-- 3. Helper function — cek role tanpa rekursi
-- security definer = fungsi berjalan sebagai owner (postgres),
-- bypass RLS, sehingga tidak memicu policy profiles lagi.
-- ============================================================

create or replace function public.get_my_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from profiles where id = auth.uid()
$$;

-- ============================================================
-- 4. RLS Policies
-- ============================================================

-- ── profiles ──────────────────────────────────────────────
-- Gunakan satu policy SELECT yang menggabungkan kedua kondisi
-- (milik sendiri ATAU kader) agar tidak ada rekursi.
create policy "profiles: select"
  on profiles for select
  using (
    auth.uid() = id
    or public.get_my_role() = 'kader'
  );

create policy "profiles: insert sendiri"
  on profiles for insert
  with check (auth.uid() = id);

create policy "profiles: update sendiri"
  on profiles for update
  using (auth.uid() = id);

-- ── balita ────────────────────────────────────────────────
create policy "balita: select"
  on balita for select
  using (
    parent_id = auth.uid()
    or public.get_my_role() = 'kader'
  );

create policy "balita: insert"
  on balita for insert
  with check (
    parent_id = auth.uid()
    or public.get_my_role() = 'kader'
  );

create policy "balita: update"
  on balita for update
  using (public.get_my_role() = 'kader');

create policy "balita: delete"
  on balita for delete
  using (public.get_my_role() = 'kader');

-- ── imunisasi ─────────────────────────────────────────────
create policy "imunisasi: select"
  on imunisasi for select
  using (
    public.get_my_role() = 'kader'
    or exists (
      select 1 from balita b
      where b.id = imunisasi.balita_id and b.parent_id = auth.uid()
    )
  );

create policy "imunisasi: kader kelola"
  on imunisasi for all
  using (public.get_my_role() = 'kader')
  with check (public.get_my_role() = 'kader');

-- ── pertumbuhan ───────────────────────────────────────────
create policy "pertumbuhan: select"
  on pertumbuhan for select
  using (
    public.get_my_role() = 'kader'
    or exists (
      select 1 from balita b
      where b.id = pertumbuhan.balita_id and b.parent_id = auth.uid()
    )
  );

create policy "pertumbuhan: kader kelola"
  on pertumbuhan for all
  using (public.get_my_role() = 'kader')
  with check (public.get_my_role() = 'kader');

-- ── jadwal_imunisasi ──────────────────────────────────────
create policy "jadwal_imunisasi: select"
  on jadwal_imunisasi for select
  using (
    public.get_my_role() = 'kader'
    or exists (
      select 1 from balita b
      where b.id = jadwal_imunisasi.balita_id and b.parent_id = auth.uid()
    )
  );

create policy "jadwal_imunisasi: kader kelola"
  on jadwal_imunisasi for all
  using (public.get_my_role() = 'kader')
  with check (public.get_my_role() = 'kader');

-- ── jadwal_posyandu ───────────────────────────────────────
create policy "jadwal_posyandu: semua user baca"
  on jadwal_posyandu for select
  using (auth.uid() is not null);

create policy "jadwal_posyandu: kader kelola"
  on jadwal_posyandu for all
  using (public.get_my_role() = 'kader')
  with check (public.get_my_role() = 'kader');

-- ── notifications ─────────────────────────────────────────
create policy "notifications: select"
  on notifications for select
  using (user_id = auth.uid());

create policy "notifications: update"
  on notifications for update
  using (user_id = auth.uid());

create policy "notifications: insert"
  on notifications for insert
  with check (
    user_id = auth.uid()
    or public.get_my_role() = 'kader'
  );

-- ── master_imunisasi ──────────────────────────────────────
create policy "master_imunisasi: semua user baca"
  on master_imunisasi for select
  using (auth.uid() is not null);

create policy "master_imunisasi: kader kelola"
  on master_imunisasi for all
  using (public.get_my_role() = 'kader')
  with check (public.get_my_role() = 'kader');

-- ── edukasi ───────────────────────────────────────────────
create policy "edukasi: semua user baca"
  on edukasi for select
  using (auth.uid() is not null);

create policy "edukasi: kader kelola"
  on edukasi for all
  using (public.get_my_role() = 'kader')
  with check (public.get_my_role() = 'kader');

-- ── edukasi_kategori ──────────────────────────────────────
create policy "edukasi_kategori: semua user baca"
  on edukasi_kategori for select
  using (auth.uid() is not null);

create policy "edukasi_kategori: kader kelola"
  on edukasi_kategori for all
  using (public.get_my_role() = 'kader')
  with check (public.get_my_role() = 'kader');

-- ============================================================
-- 4. Verifikasi
-- Jalankan query ini untuk cek tabel yang sudah aktif Realtime:
-- ============================================================
-- select schemaname, tablename
-- from pg_publication_tables
-- where pubname = 'supabase_realtime'
-- order by tablename;
