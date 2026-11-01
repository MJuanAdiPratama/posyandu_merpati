-- Tambah kolom reminder_terkirim untuk klaim atomik saat mengirim reminder H-1,
-- supaya reminder tidak terkirim dobel saat beberapa device buka app bersamaan.
alter table jadwal_imunisasi
  add column if not exists reminder_terkirim boolean not null default false;

alter table jadwal_posyandu
  add column if not exists reminder_terkirim boolean not null default false;
