-- Reminder H-1 otomatis via pg_cron, supaya reminder tetap terkirim walau
-- tidak ada kader/orang tua yang membuka aplikasi. Pakai kolom
-- reminder_terkirim yang sama dengan klaim atomik di sisi Flutter, jadi
-- tidak akan terkirim dobel meskipun kedua jalur ini berjalan.

create extension if not exists pg_cron;

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
  where b.parent_id is not null;
end;
$$;

create or replace function public.kirim_reminder_posyandu_h1()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_jadwal record;
begin
  for v_jadwal in
    update jadwal_posyandu
    set reminder_terkirim = true
    where tanggal = current_date + 1
      and reminder_terkirim = false
    returning judul, lokasi
  loop
    insert into notifications (user_id, title, message, type)
    select
      p.id,
      'Pengingat Posyandu Besok',
      v_jadwal.judul || ' dijadwalkan besok' ||
        case when v_jadwal.lokasi is not null
          then ' di ' || v_jadwal.lokasi else '' end || '.',
      'reminder'
    from profiles p
    where p.role in ('orang_tua', 'kader');
  end loop;
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
end;
$$;

-- Jalan tiap hari jam 01:00 UTC (08:00 WIB)
select cron.schedule(
  'kirim-reminder-h1',
  '0 1 * * *',
  $$ select public.kirim_reminder_h1(); $$
);
