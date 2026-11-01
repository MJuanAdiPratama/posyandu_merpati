-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip/incremental lama.

-- Migration: tambah kolom is_active ke tabel profiles
alter table profiles
  add column if not exists is_active boolean not null default true;

-- Update RLS: kader aktif saja yang bisa akses fitur kader
-- (opsional, bisa di-skip jika pengecekan cukup di Flutter)
