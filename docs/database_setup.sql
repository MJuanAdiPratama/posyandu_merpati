-- ============================================================
-- DATABASE SETUP - Posyandu Merpati
-- Jalankan file ini di Supabase SQL Editor untuk setup database baru.
--
-- Isi file:
-- 1. Extension
-- 2. Tabel aplikasi
-- 3. Index
-- 4. Helper function
-- 5. Row Level Security policies
-- 6. Storage bucket dan policies
-- 7. Supabase Realtime publication
-- 8. Seed data development
--
-- Catatan:
-- - File ini memakai nama tabel `jenis_imunisasi`.
-- ============================================================

-- ============================================================
-- 1. EXTENSION
-- ============================================================

create extension if not exists pgcrypto;


-- ============================================================
-- 2. TABEL APLIKASI
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nama text not null,
  email text not null,
  no_hp text,
  alamat text,
  role text not null check (role in ('kader', 'orang_tua')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.balita (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.profiles(id) on delete set null,
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.jenis_imunisasi (
  id uuid primary key default gen_random_uuid(),
  nama_imunisasi text not null,
  usia_bulan int not null,
  deskripsi text,
  created_at timestamptz not null default now()
);

create table if not exists public.imunisasi (
  id uuid primary key default gen_random_uuid(),
  balita_id uuid not null references public.balita(id) on delete cascade,
  jenis_imunisasi_id uuid references public.jenis_imunisasi(id) on delete set null,
  tanggal_imunisasi date not null,
  berat_badan numeric,
  tinggi_badan numeric,
  catatan text,
  petugas_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.pertumbuhan (
  id uuid primary key default gen_random_uuid(),
  balita_id uuid not null references public.balita(id) on delete cascade,
  tanggal_pemeriksaan date not null,
  usia_bulan int not null,
  berat_badan numeric not null,
  tinggi_badan numeric not null,
  lingkar_kepala numeric,
  status_gizi text,
  status_tinggi_badan text,
  status_berat_badan text,
  status_pertumbuhan text,
  catatan text,
  created_at timestamptz not null default now()
);

create table if not exists public.jadwal_imunisasi (
  id uuid primary key default gen_random_uuid(),
  balita_id uuid not null references public.balita(id) on delete cascade,
  jenis_imunisasi_id uuid references public.jenis_imunisasi(id) on delete set null,
  tanggal_jadwal date not null,
  status text not null default 'terjadwal'
    check (status in ('terjadwal', 'selesai', 'terlambat', 'dibatalkan')),
  reminder_terkirim boolean not null default false,
  reminder_hari_ini_terkirim boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.jadwal_posyandu (
  id uuid primary key default gen_random_uuid(),
  judul text not null,
  deskripsi text,
  tanggal date not null,
  jam_mulai time,
  jam_selesai time,
  lokasi text,
  created_by uuid references public.profiles(id) on delete set null,
  reminder_terkirim boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  balita_id uuid references public.balita(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null
    check (type in ('hasil_imunisasi', 'pertumbuhan', 'reminder', 'pengumuman', 'verifikasi')),
  scheduled_at timestamptz,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.edukasi_kategori (
  id uuid primary key default gen_random_uuid(),
  nama text not null unique,
  deskripsi text,
  created_at timestamptz not null default now()
);

create table if not exists public.edukasi (
  id uuid primary key default gen_random_uuid(),
  judul text not null,
  isi text not null,
  kategori_id uuid references public.edukasi_kategori(id) on delete set null,
  kategori text,
  gambar_url text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null default 'android' check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);


-- ============================================================
-- 3. INDEX
-- ============================================================

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_is_active on public.profiles(is_active);
create index if not exists idx_balita_parent_id on public.balita(parent_id);
create index if not exists idx_balita_status_verifikasi on public.balita(status_verifikasi);
create index if not exists idx_imunisasi_balita_id on public.imunisasi(balita_id);
create index if not exists idx_imunisasi_jenis_imunisasi_id on public.imunisasi(jenis_imunisasi_id);
create index if not exists idx_pertumbuhan_balita_id on public.pertumbuhan(balita_id);
create index if not exists idx_jadwal_imunisasi_balita_id on public.jadwal_imunisasi(balita_id);
create index if not exists idx_jadwal_imunisasi_jenis_id on public.jadwal_imunisasi(jenis_imunisasi_id);
create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_is_read on public.notifications(is_read);
create index if not exists idx_edukasi_kategori_id on public.edukasi(kategori_id);
create index if not exists idx_user_devices_user_id on public.user_devices(user_id);


-- ============================================================
-- 4. HELPER FUNCTION
-- ============================================================

create or replace function public.get_user_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid()
    and is_active = true
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_balita_updated_at on public.balita;
create trigger set_balita_updated_at
  before update on public.balita
  for each row execute function public.set_updated_at();

drop trigger if exists set_user_devices_updated_at on public.user_devices;
create trigger set_user_devices_updated_at
  before update on public.user_devices
  for each row execute function public.set_updated_at();


-- ============================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.balita enable row level security;
alter table public.jenis_imunisasi enable row level security;
alter table public.imunisasi enable row level security;
alter table public.pertumbuhan enable row level security;
alter table public.jadwal_imunisasi enable row level security;
alter table public.jadwal_posyandu enable row level security;
alter table public.notifications enable row level security;
alter table public.edukasi_kategori enable row level security;
alter table public.edukasi enable row level security;
alter table public.user_devices enable row level security;

drop policy if exists "profiles: insert sendiri" on public.profiles;
create policy "profiles: insert sendiri"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "profiles: select sendiri atau kader" on public.profiles;
create policy "profiles: select sendiri atau kader"
  on public.profiles for select
  to authenticated
  using (id = auth.uid() or public.get_user_role() = 'kader');

drop policy if exists "profiles: update sendiri" on public.profiles;
create policy "profiles: update sendiri"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "profiles: kader update" on public.profiles;
create policy "profiles: kader update"
  on public.profiles for update
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "balita: select" on public.balita;
create policy "balita: select"
  on public.balita for select
  to authenticated
  using (parent_id = auth.uid() or public.get_user_role() = 'kader');

drop policy if exists "balita: insert" on public.balita;
create policy "balita: insert"
  on public.balita for insert
  to authenticated
  with check (parent_id = auth.uid() or public.get_user_role() = 'kader');

drop policy if exists "balita: kader update" on public.balita;
create policy "balita: kader update"
  on public.balita for update
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "balita: kader delete" on public.balita;
create policy "balita: kader delete"
  on public.balita for delete
  to authenticated
  using (public.get_user_role() = 'kader');

drop policy if exists "jenis_imunisasi: semua user baca" on public.jenis_imunisasi;
create policy "jenis_imunisasi: semua user baca"
  on public.jenis_imunisasi for select
  to authenticated
  using (true);

drop policy if exists "jenis_imunisasi: kader kelola" on public.jenis_imunisasi;
create policy "jenis_imunisasi: kader kelola"
  on public.jenis_imunisasi for all
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "imunisasi: select" on public.imunisasi;
create policy "imunisasi: select"
  on public.imunisasi for select
  to authenticated
  using (
    public.get_user_role() = 'kader'
    or exists (
      select 1
      from public.balita b
      where b.id = imunisasi.balita_id
        and b.parent_id = auth.uid()
    )
  );

drop policy if exists "imunisasi: kader kelola" on public.imunisasi;
create policy "imunisasi: kader kelola"
  on public.imunisasi for all
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "pertumbuhan: select" on public.pertumbuhan;
create policy "pertumbuhan: select"
  on public.pertumbuhan for select
  to authenticated
  using (
    public.get_user_role() = 'kader'
    or exists (
      select 1
      from public.balita b
      where b.id = pertumbuhan.balita_id
        and b.parent_id = auth.uid()
    )
  );

drop policy if exists "pertumbuhan: kader kelola" on public.pertumbuhan;
create policy "pertumbuhan: kader kelola"
  on public.pertumbuhan for all
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "jadwal_imunisasi: select" on public.jadwal_imunisasi;
create policy "jadwal_imunisasi: select"
  on public.jadwal_imunisasi for select
  to authenticated
  using (
    public.get_user_role() = 'kader'
    or exists (
      select 1
      from public.balita b
      where b.id = jadwal_imunisasi.balita_id
        and b.parent_id = auth.uid()
    )
  );

drop policy if exists "jadwal_imunisasi: kader kelola" on public.jadwal_imunisasi;
create policy "jadwal_imunisasi: kader kelola"
  on public.jadwal_imunisasi for all
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "jadwal_posyandu: semua user baca" on public.jadwal_posyandu;
create policy "jadwal_posyandu: semua user baca"
  on public.jadwal_posyandu for select
  to authenticated
  using (true);

drop policy if exists "jadwal_posyandu: kader kelola" on public.jadwal_posyandu;
create policy "jadwal_posyandu: kader kelola"
  on public.jadwal_posyandu for all
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "notifications: select sendiri" on public.notifications;
create policy "notifications: select sendiri"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "notifications: update sendiri" on public.notifications;
create policy "notifications: update sendiri"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "notifications: insert" on public.notifications;
create policy "notifications: insert"
  on public.notifications for insert
  to authenticated
  with check (user_id = auth.uid() or public.get_user_role() = 'kader');

drop policy if exists "edukasi_kategori: semua user baca" on public.edukasi_kategori;
create policy "edukasi_kategori: semua user baca"
  on public.edukasi_kategori for select
  to authenticated
  using (true);

drop policy if exists "edukasi_kategori: kader kelola" on public.edukasi_kategori;
create policy "edukasi_kategori: kader kelola"
  on public.edukasi_kategori for all
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "edukasi: semua user baca" on public.edukasi;
create policy "edukasi: semua user baca"
  on public.edukasi for select
  to authenticated
  using (true);

drop policy if exists "edukasi: kader kelola" on public.edukasi;
create policy "edukasi: kader kelola"
  on public.edukasi for all
  to authenticated
  using (public.get_user_role() = 'kader')
  with check (public.get_user_role() = 'kader');

drop policy if exists "user_devices: insert sendiri" on public.user_devices;
create policy "user_devices: insert sendiri"
  on public.user_devices for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "user_devices: select sendiri" on public.user_devices;
create policy "user_devices: select sendiri"
  on public.user_devices for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user_devices: update sendiri" on public.user_devices;
create policy "user_devices: update sendiri"
  on public.user_devices for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "user_devices: delete sendiri" on public.user_devices;
create policy "user_devices: delete sendiri"
  on public.user_devices for delete
  to authenticated
  using (user_id = auth.uid());


-- ============================================================
-- 6. STORAGE
-- ============================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'edukasi-images',
  'edukasi-images',
  true,
  5242880,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "edukasi_images: public read" on storage.objects;
create policy "edukasi_images: public read"
  on storage.objects for select
  using (bucket_id = 'edukasi-images');

drop policy if exists "edukasi_images: kader upload" on storage.objects;
create policy "edukasi_images: kader upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'edukasi-images'
    and public.get_user_role() = 'kader'
  );

drop policy if exists "edukasi_images: kader update" on storage.objects;
create policy "edukasi_images: kader update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'edukasi-images'
    and public.get_user_role() = 'kader'
  )
  with check (
    bucket_id = 'edukasi-images'
    and public.get_user_role() = 'kader'
  );

drop policy if exists "edukasi_images: kader delete" on storage.objects;
create policy "edukasi_images: kader delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'edukasi-images'
    and public.get_user_role() = 'kader'
  );


-- ============================================================
-- 7. REALTIME
-- ============================================================

do $$
begin
  if not exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) then
    create publication supabase_realtime;
  end if;
end
$$;

alter publication supabase_realtime
  set table
    public.profiles,
    public.balita,
    public.jenis_imunisasi,
    public.imunisasi,
    public.pertumbuhan,
    public.jadwal_imunisasi,
    public.jadwal_posyandu,
    public.notifications,
    public.edukasi_kategori,
    public.edukasi;


-- ============================================================
-- 8. SEED DATA DEVELOPMENT
-- ============================================================

-- Akun login testing:
-- Kader  : kader@posyandu.com  / kader123
-- Ortu 1 : rina@posyandu.com   / ortu123
-- Ortu 2 : hendra@posyandu.com / ortu123

delete from public.notifications where id::text like '80000000%';
delete from public.edukasi where id::text like 'e0000000%';
delete from public.edukasi_kategori where id::text like '90000000%';
delete from public.jadwal_posyandu where id::text like '70000000%';
delete from public.jadwal_imunisasi where id::text like '60000000%';
delete from public.pertumbuhan where id::text like '50000000%';
delete from public.imunisasi where id::text like 'd0000000%';
delete from public.balita where id::text like 'b0000000%';
delete from public.jenis_imunisasi where id::text like 'c0000000%';
delete from public.profiles where id::text like 'a0000000%';

delete from auth.identities
where user_id in (
  'a0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000002',
  'a0000000-0000-0000-0000-000000000003'
);

delete from auth.users
where id in (
  'a0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000002',
  'a0000000-0000-0000-0000-000000000003'
);

insert into auth.users (
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
) values
  (
    'a0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'kader@posyandu.com',
    crypt('kader123', gen_salt('bf')),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    false,
    now(),
    now(),
    '',
    '',
    '',
    ''
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'rina@posyandu.com',
    crypt('ortu123', gen_salt('bf')),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    false,
    now(),
    now(),
    '',
    '',
    '',
    ''
  ),
  (
    'a0000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'hendra@posyandu.com',
    crypt('ortu123', gen_salt('bf')),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    false,
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

insert into auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
) values
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000001',
    'kader@posyandu.com',
    jsonb_build_object('sub', 'a0000000-0000-0000-0000-000000000001', 'email', 'kader@posyandu.com'),
    'email',
    now(),
    now(),
    now()
  ),
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000002',
    'rina@posyandu.com',
    jsonb_build_object('sub', 'a0000000-0000-0000-0000-000000000002', 'email', 'rina@posyandu.com'),
    'email',
    now(),
    now(),
    now()
  ),
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000003',
    'hendra@posyandu.com',
    jsonb_build_object('sub', 'a0000000-0000-0000-0000-000000000003', 'email', 'hendra@posyandu.com'),
    'email',
    now(),
    now(),
    now()
  );

insert into public.profiles (id, nama, email, no_hp, alamat, role, is_active) values
  (
    'a0000000-0000-0000-0000-000000000001',
    'Bidan Sari Dewi',
    'kader@posyandu.com',
    '081234567890',
    'Jl. Mawar No. 5, RT 02 RW 03, Kelurahan Merpati',
    'kader',
    true
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    'Rina Wati',
    'rina@posyandu.com',
    '082345678901',
    'Jl. Melati No. 12, RT 01 RW 02, Kelurahan Merpati',
    'orang_tua',
    true
  ),
  (
    'a0000000-0000-0000-0000-000000000003',
    'Hendra Kusuma',
    'hendra@posyandu.com',
    '083456789012',
    'Jl. Anggrek No. 7, RT 03 RW 01, Kelurahan Merpati',
    'orang_tua',
    true
  );

insert into public.jenis_imunisasi (id, nama_imunisasi, usia_bulan, deskripsi) values
  ('c0000000-0000-0000-0000-000000000001', 'HB0', 0, 'Hepatitis B dosis pertama, diberikan segera setelah lahir.'),
  ('c0000000-0000-0000-0000-000000000002', 'BCG', 1, 'Mencegah tuberkulosis berat.'),
  ('c0000000-0000-0000-0000-000000000003', 'Polio 1', 1, 'Polio oral dosis pertama.'),
  ('c0000000-0000-0000-0000-000000000004', 'DPT-HB-Hib 1', 2, 'Difteri, pertusis, tetanus, hepatitis B, dan Hib dosis 1.'),
  ('c0000000-0000-0000-0000-000000000005', 'Polio 2', 2, 'Polio oral dosis kedua.'),
  ('c0000000-0000-0000-0000-000000000006', 'DPT-HB-Hib 2', 3, 'Difteri, pertusis, tetanus, hepatitis B, dan Hib dosis 2.'),
  ('c0000000-0000-0000-0000-000000000007', 'Polio 3', 3, 'Polio oral dosis ketiga.'),
  ('c0000000-0000-0000-0000-000000000008', 'DPT-HB-Hib 3', 4, 'Difteri, pertusis, tetanus, hepatitis B, dan Hib dosis 3.'),
  ('c0000000-0000-0000-0000-000000000009', 'Polio 4 (IPV)', 4, 'Polio dosis keempat dengan IPV.'),
  ('c0000000-0000-0000-0000-000000000010', 'Campak/MR', 9, 'Mencegah campak dan rubella.'),
  ('c0000000-0000-0000-0000-000000000011', 'DPT-HB-Hib Booster', 18, 'Booster DPT-HB-Hib pada usia 18 bulan.'),
  ('c0000000-0000-0000-0000-000000000012', 'Campak/MR Booster', 18, 'Booster Campak/MR pada usia 18 bulan.');

insert into public.balita (
  id,
  parent_id,
  nik,
  nama,
  tempat_lahir,
  tanggal_lahir,
  jenis_kelamin,
  nama_ortu,
  kontak_ortu,
  alamat,
  status_verifikasi
) values
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

insert into public.imunisasi (
  id,
  balita_id,
  jenis_imunisasi_id,
  tanggal_imunisasi,
  berat_badan,
  tinggi_badan,
  catatan,
  petugas_id
) values
  ('d0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', '2025-09-10', 3.2, 50.0, 'Bayi lahir normal, kondisi sehat.', 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', '2025-10-12', 4.5, 54.0, 'Reaksi BCG normal.', 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', '2025-10-12', 4.5, 54.0, 'OPV diteteskan 2 tetes per oral.', 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', '2025-03-20', 3.1, 49.0, 'Bayi lahir sehat.', 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000010', '2025-12-22', 8.2, 70.0, 'Campak/MR 9 bulan, tidak ada reaksi.', 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', '2024-05-15', 3.3, 50.5, 'Bayi lahir sehat.', 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000010', '2025-02-17', 9.0, 72.0, 'Campak/MR 9 bulan.', 'a0000000-0000-0000-0000-000000000001');

insert into public.pertumbuhan (
  id,
  balita_id,
  tanggal_pemeriksaan,
  usia_bulan,
  berat_badan,
  tinggi_badan,
  status_gizi,
  status_tinggi_badan,
  status_berat_badan,
  status_pertumbuhan,
  catatan
) values
  ('50000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '2025-09-10', 0, 3.2, 50.0, 'Normal', 'Normal', 'Normal', 'Normal', 'Lahir normal.'),
  ('50000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', '2026-05-15', 8, 8.7, 69.0, 'Normal', 'Normal', 'Normal', 'Normal', null),
  ('50000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000002', '2025-03-20', 0, 3.1, 49.0, 'Normal', 'Normal', 'Normal', 'Normal', 'Lahir normal.'),
  ('50000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000002', '2026-05-20', 14, 9.5, 76.0, 'Normal', 'Normal', 'Normal', 'Normal', null),
  ('50000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000003', '2024-05-15', 0, 3.3, 50.5, 'Normal', 'Normal', 'Normal', 'Normal', 'Lahir normal.'),
  ('50000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000003', '2026-05-18', 24, 11.8, 87.0, 'Normal', 'Normal', 'Normal', 'Normal', 'Pertumbuhan membaik setelah program PMT.');

insert into public.jadwal_imunisasi (
  id,
  balita_id,
  jenis_imunisasi_id,
  tanggal_jadwal,
  status
) values
  ('60000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000008', '2026-01-18', 'selesai'),
  ('60000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000010', '2026-06-10', 'terjadwal'),
  ('60000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000011', '2026-09-20', 'terjadwal'),
  ('60000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000012', '2026-09-20', 'terjadwal'),
  ('60000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000011', '2026-11-17', 'terjadwal'),
  ('60000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000012', '2026-11-17', 'terjadwal');

insert into public.jadwal_posyandu (
  id,
  judul,
  deskripsi,
  tanggal,
  jam_mulai,
  jam_selesai,
  lokasi,
  created_by
) values
  ('70000000-0000-0000-0000-000000000001', 'Posyandu Rutin Juni 2026', 'Penimbangan, pengukuran tinggi badan, imunisasi, dan konsultasi gizi.', '2026-06-25', '08:00', '11:30', 'Balai RW 03, Jl. Kenanga No. 1', 'a0000000-0000-0000-0000-000000000001'),
  ('70000000-0000-0000-0000-000000000002', 'Imunisasi Campak/MR Massal', 'Kegiatan imunisasi Campak/MR untuk balita usia 9-59 bulan.', '2026-06-10', '07:30', '12:00', 'Puskesmas Kelurahan Merpati', 'a0000000-0000-0000-0000-000000000001'),
  ('70000000-0000-0000-0000-000000000003', 'Posyandu Rutin Juli 2026', 'Kegiatan posyandu bulanan rutin.', '2026-07-23', '08:00', '11:00', 'Balai RW 03, Jl. Kenanga No. 1', 'a0000000-0000-0000-0000-000000000001');

insert into public.edukasi_kategori (id, nama, deskripsi) values
  ('90000000-0000-0000-0000-000000000001', 'Imunisasi', 'Panduan jadwal, manfaat, dan tindak lanjut imunisasi.'),
  ('90000000-0000-0000-0000-000000000002', 'Gizi', 'Edukasi makanan, ASI, MPASI, dan pencegahan gizi buruk.'),
  ('90000000-0000-0000-0000-000000000003', 'Tumbuh Kembang', 'Informasi perkembangan motorik, bahasa, dan sosial balita.'),
  ('90000000-0000-0000-0000-000000000004', 'Kesehatan', 'Tips menjaga kesehatan harian dan mengenali tanda bahaya.'),
  ('90000000-0000-0000-0000-000000000005', 'Pengasuhan', 'Panduan pola asuh dan kebiasaan sehat keluarga.');

insert into public.edukasi (id, judul, isi, kategori_id, kategori, created_by) values
  (
    'e0000000-0000-0000-0000-000000000001',
    'Pentingnya Imunisasi untuk Balita',
    'Imunisasi membantu melindungi anak dari penyakit berbahaya seperti campak, polio, difteri, dan TBC. Pastikan anak mendapat imunisasi sesuai jadwal nasional. Jika terlambat, segera konsultasikan ke bidan atau dokter.',
    '90000000-0000-0000-0000-000000000001',
    'Imunisasi',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'e0000000-0000-0000-0000-000000000002',
    'Mengenal Stunting dan Cara Mencegahnya',
    'Stunting adalah kondisi gagal tumbuh akibat kekurangan gizi kronis dan infeksi berulang. Pencegahan dilakukan dengan ASI eksklusif, MPASI bergizi, imunisasi lengkap, dan pemantauan rutin di posyandu.',
    '90000000-0000-0000-0000-000000000002',
    'Gizi',
    'a0000000-0000-0000-0000-000000000001'
  ),
  (
    'e0000000-0000-0000-0000-000000000003',
    'Tumbuh Kembang Anak 0-2 Tahun',
    'Dua tahun pertama adalah masa penting tumbuh kembang. Ajak anak bicara, bernyanyi, bermain aman sesuai usia, dan pantau perkembangan motorik, bahasa, serta sosialnya.',
    '90000000-0000-0000-0000-000000000003',
    'Tumbuh Kembang',
    'a0000000-0000-0000-0000-000000000001'
  );

insert into public.notifications (
  id,
  user_id,
  balita_id,
  title,
  message,
  type,
  is_read
) values
  (
    '80000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'Jadwal Imunisasi Mendatang',
    'Arjuna Pratama dijadwalkan imunisasi Campak/MR pada 10 Juni 2026. Pastikan hadir tepat waktu.',
    'reminder',
    false
  ),
  (
    '80000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000002',
    'Hasil Imunisasi Siti Aisyah',
    'Imunisasi Campak/MR untuk Siti Aisyah telah dicatat pada 22 Desember 2025.',
    'hasil_imunisasi',
    true
  ),
  (
    '80000000-0000-0000-0000-000000000003',
    'a0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000004',
    'Registrasi Balita Menunggu Verifikasi',
    'Data balita Naila Zahira sedang menunggu verifikasi oleh kader.',
    'verifikasi',
    false
  ),
  (
    '80000000-0000-0000-0000-000000000004',
    'a0000000-0000-0000-0000-000000000003',
    null,
    'Pengumuman Imunisasi Massal',
    'Imunisasi Campak/MR massal akan diadakan pada 10 Juni 2026 di Puskesmas Kelurahan Merpati.',
    'pengumuman',
    false
  );


-- ============================================================
-- VERIFIKASI
-- ============================================================

-- select 'profiles' as tabel, count(*) as jumlah from public.profiles
-- union all select 'balita', count(*) from public.balita
-- union all select 'jenis_imunisasi', count(*) from public.jenis_imunisasi
-- union all select 'imunisasi', count(*) from public.imunisasi
-- union all select 'pertumbuhan', count(*) from public.pertumbuhan
-- union all select 'jadwal_imunisasi', count(*) from public.jadwal_imunisasi
-- union all select 'jadwal_posyandu', count(*) from public.jadwal_posyandu
-- union all select 'edukasi_kategori', count(*) from public.edukasi_kategori
-- union all select 'edukasi', count(*) from public.edukasi
-- union all select 'notifications', count(*) from public.notifications;
