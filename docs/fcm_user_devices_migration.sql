-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip/incremental lama.

-- Tabel untuk menyimpan FCM device token per user
create table if not exists user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null default 'android', -- 'android' | 'ios'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, fcm_token)
);

-- Index untuk query berdasarkan user_id
create index if not exists idx_user_devices_user_id on user_devices(user_id);

-- RLS: user hanya bisa akses device miliknya sendiri
alter table user_devices enable row level security;

create policy "User bisa insert device sendiri"
  on user_devices for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "User bisa update device sendiri"
  on user_devices for update
  to authenticated
  using (auth.uid() = user_id);

create policy "User bisa delete device sendiri"
  on user_devices for delete
  to authenticated
  using (auth.uid() = user_id);

create policy "User bisa lihat device sendiri"
  on user_devices for select
  to authenticated
  using (auth.uid() = user_id);
