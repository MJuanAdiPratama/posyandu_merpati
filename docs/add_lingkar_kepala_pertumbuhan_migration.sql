-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah migration incremental untuk database yang sudah ada.

-- Migration: tambah kolom lingkar_kepala ke tabel pertumbuhan
-- Sebelumnya lingkar kepala yang diinput saat imunisasi hanya tersimpan
-- di tabel imunisasi dan tidak ikut tercatat sebagai data pertumbuhan.
alter table public.pertumbuhan add column if not exists lingkar_kepala numeric;
