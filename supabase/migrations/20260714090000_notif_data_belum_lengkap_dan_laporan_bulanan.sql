-- Notifikasi kader "Data Belum Lengkap" dan "Laporan Bulanan" di halaman
-- Pengaturan Notifikasi sebelumnya cuma toggle UI (tersimpan di
-- SharedPreferences lokal), tidak ada yang benar-benar mengirim
-- notifikasinya. Migration ini menambahkan mekanismenya lewat pg_cron,
-- mengikuti pola yang sama dengan reminder H-1 di
-- 20260622133512_notif_kader_imunisasi.sql.

alter table balita
  add column if not exists notif_data_belum_lengkap_terkirim boolean not null default false;

-- Balita yang sudah diverifikasi tapi field tempat_lahir/kontak_ortu/alamat
-- masih kosong dianggap datanya belum lengkap. Dikirim sekali per balita
-- (pakai kolom klaim, sama seperti reminder_terkirim) supaya kader tidak
-- dispam notifikasi yang sama tiap hari.
create or replace function public.kirim_notifikasi_data_belum_lengkap()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  with claimed as (
    update balita
    set notif_data_belum_lengkap_terkirim = true
    where status_verifikasi = 'disetujui'
      and notif_data_belum_lengkap_terkirim = false
      and (tempat_lahir is null or kontak_ortu is null or alamat is null)
    returning id, nama
  )
  insert into notifications (user_id, balita_id, title, message, type)
  select
    p.id,
    c.id,
    'Data Belum Lengkap',
    'Data ' || coalesce(c.nama, 'balita') || ' belum lengkap, mohon dilengkapi.',
    'reminder'
  from claimed c
  cross join profiles p
  where p.role = 'kader';
end;
$$;

-- Pengingat rekap/ekspor laporan bulanan untuk kader, dikirim sekali di
-- awal bulan. Pengecekan exists dipakai (bukan kolom klaim) karena ini
-- kejadian bulanan sistem, bukan per-baris seperti reminder lainnya.
create or replace function public.kirim_notifikasi_laporan_bulanan()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from notifications
    where type = 'reminder'
      and title = 'Pengingat Laporan Bulanan'
      and created_at >= date_trunc('month', now())
  ) then
    return;
  end if;

  insert into notifications (user_id, title, message, type)
  select
    p.id,
    'Pengingat Laporan Bulanan',
    'Jangan lupa membuat dan mengekspor rekap laporan bulan lalu.',
    'reminder'
  from profiles p
  where p.role = 'kader';
end;
$$;

-- Sertakan pengecekan data belum lengkap di reminder harian yang sudah ada.
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
  perform public.kirim_notifikasi_data_belum_lengkap();
end;
$$;

-- Jadwal terpisah untuk laporan bulanan: tanggal 1 tiap bulan jam 01:00 UTC
-- (08:00 WIB), sama jamnya dengan reminder harian.
select cron.schedule(
  'kirim-notifikasi-laporan-bulanan',
  '0 1 1 * *',
  $$ select public.kirim_notifikasi_laporan_bulanan(); $$
);
