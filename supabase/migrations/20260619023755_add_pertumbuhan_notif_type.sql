-- Tambah 'pertumbuhan' ke daftar type yang valid di tabel notifications.
-- Sebelumnya notifikasi hasil pemeriksaan pertumbuhan ikut memakai type
-- 'hasil_imunisasi' sehingga tampil dengan ikon/warna imunisasi di aplikasi.
alter table notifications
  drop constraint if exists notifications_type_check;

alter table notifications
  add constraint notifications_type_check
  check (type in ('hasil_imunisasi', 'pertumbuhan', 'reminder', 'pengumuman', 'verifikasi'));
