-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip/incremental lama.

-- Migration: tambah kolom reminder_terkirim untuk fitur reminder H-1
-- (jadwal imunisasi & jadwal posyandu). Dipakai sebagai klaim atomik
-- agar reminder tidak terkirim dobel saat beberapa device buka app bersamaan.
alter table jadwal_imunisasi
  add column if not exists reminder_terkirim boolean not null default false;

alter table jadwal_posyandu
  add column if not exists reminder_terkirim boolean not null default false;
