-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip/incremental lama.

-- ============================================================
-- MIGRATION: Tambah tabel kategori edukasi
-- Jalankan di Supabase SQL Editor jika database sudah pernah dibuat
-- ============================================================

create table if not exists edukasi_kategori (
  id uuid primary key default gen_random_uuid(),
  nama text not null unique,
  deskripsi text,
  created_at timestamp with time zone default now()
);

alter table edukasi
  add column if not exists kategori_id uuid
  references edukasi_kategori(id) on delete set null;

alter table edukasi_kategori enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'edukasi_kategori'
      and policyname = 'Semua baca kategori edukasi'
  ) then
    create policy "Semua baca kategori edukasi" on edukasi_kategori
      for select to authenticated using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'edukasi_kategori'
      and policyname = 'Kader kelola kategori edukasi'
  ) then
    create policy "Kader kelola kategori edukasi" on edukasi_kategori
      for all to authenticated
      using (get_user_role() = 'kader')
      with check (get_user_role() = 'kader');
  end if;
end $$;

insert into edukasi_kategori (nama, deskripsi) values
  ('Imunisasi', 'Panduan jadwal, manfaat, dan tindak lanjut imunisasi.'),
  ('Gizi', 'Edukasi makanan, ASI, MPASI, dan pencegahan gizi buruk.'),
  ('Tumbuh Kembang', 'Informasi perkembangan motorik, bahasa, dan sosial balita.'),
  ('Kesehatan', 'Tips menjaga kesehatan harian dan mengenali tanda bahaya.'),
  ('Pengasuhan', 'Panduan pola asuh dan kebiasaan sehat keluarga.')
on conflict (nama) do update set
  deskripsi = excluded.deskripsi;

update edukasi e
set kategori_id = k.id
from edukasi_kategori k
where e.kategori_id is null
  and lower(e.kategori) = lower(k.nama);
