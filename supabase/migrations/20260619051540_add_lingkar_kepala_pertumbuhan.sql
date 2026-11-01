-- Tambah kolom lingkar_kepala ke tabel pertumbuhan.
-- Sebelumnya lingkar kepala yang diinput saat imunisasi hanya tersimpan
-- di tabel imunisasi dan tidak ikut tercatat sebagai data pertumbuhan.
alter table pertumbuhan
  add column if not exists lingkar_kepala numeric;
