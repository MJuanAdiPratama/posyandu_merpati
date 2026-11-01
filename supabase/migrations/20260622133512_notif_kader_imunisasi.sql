-- Kader tidak punya relasi langsung ke balita tertentu, jadi notifikasi
-- imunisasi untuk kader di-broadcast ke semua profil dengan role 'kader'.

-- Kolom klaim atomik untuk notifikasi "jadwal imunisasi hari ini" ke kader,
-- supaya tidak terkirim dobel walau cron jalan lebih dari sekali per hari.
alter table jadwal_imunisasi
  add column if not exists reminder_hari_ini_terkirim boolean not null default false;

-- Reminder H-1 imunisasi: sekarang juga insert ke semua kader, selain orang tua.
create or replace function public.kirim_reminder_imunisasi_h1()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  with claimed as (
    update jadwal_imunisasi
    set reminder_terkirim = true
    where tanggal_jadwal = current_date + 1
      and status = 'terjadwal'
      and reminder_terkirim = false
    returning id, balita_id, jenis_imunisasi_id
  )
  insert into notifications (user_id, balita_id, title, message, type)
  select
    b.parent_id,
    c.balita_id,
    'Pengingat Imunisasi Besok',
    coalesce(b.nama, 'Balita') || ' dijadwalkan imunisasi ' ||
      coalesce(ji.nama_imunisasi, '') || ' besok.',
    'reminder'
  from claimed c
  join balita b on b.id = c.balita_id
  left join jenis_imunisasi ji on ji.id = c.jenis_imunisasi_id
  where b.parent_id is not null

  union all

  select
    p.id,
    c.balita_id,
    'Pengingat Imunisasi Besok',
    coalesce(b.nama, 'Balita') || ' dijadwalkan imunisasi ' ||
      coalesce(ji.nama_imunisasi, '') || ' besok.',
    'reminder'
  from claimed c
  join balita b on b.id = c.balita_id
  left join jenis_imunisasi ji on ji.id = c.jenis_imunisasi_id
  cross join profiles p
  where p.role = 'kader';
end;
$$;

-- Notifikasi harian untuk kader: ringkasan jumlah balita yang dijadwalkan
-- imunisasi hari ini (sebelumnya hanya tampil sebagai local notification
-- saat dashboard kader dibuka, sekarang juga tersimpan di tabel notifications).
create or replace function public.kirim_notifikasi_jadwal_imunisasi_hari_ini()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_jumlah int;
begin
  with claimed as (
    update jadwal_imunisasi
    set reminder_hari_ini_terkirim = true
    where tanggal_jadwal = current_date
      and status = 'terjadwal'
      and reminder_hari_ini_terkirim = false
    returning id
  )
  select count(*) into v_jumlah from claimed;

  if v_jumlah > 0 then
    insert into notifications (user_id, title, message, type)
    select
      p.id,
      'Jadwal Imunisasi Hari Ini',
      v_jumlah || ' balita memiliki jadwal imunisasi hari ini.',
      'reminder'
    from profiles p
    where p.role = 'kader';
  end if;
end;
$$;

create or replace function public.kirim_reminder_h1()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.kirim_reminder_imunisasi_h1();
  perform public.kirim_reminder_posyandu_h1();
  perform public.kirim_notifikasi_jadwal_imunisasi_hari_ini();
end;
$$;
