-- Hapus fitur status publikasi/draft pada artikel edukasi.
-- Semua artikel edukasi yang ada langsung dianggap publik, tidak ada lagi
-- pembedaan draft vs dipublikasikan.
alter table edukasi drop column if exists status;
