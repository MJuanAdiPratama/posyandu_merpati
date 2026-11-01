-- Backfill status_gizi untuk balita usia 0 bulan yang salah tersimpan
-- sebagai 'Tidak diketahui' akibat bug di GrowthStatusHelper.hitungStatusGizi
-- (guard usia <= 0 menolak usia 0 bulan, padahal usia 0 bulan = bayi baru
-- lahir dan valid). Hanya menyentuh baris yang masih bernilai
-- 'Tidak diketahui' di usia 0 bulan; logika mengikuti GrowthStatusHelper
-- versi terbaru (lib/core/utils/growth_status_helper.dart).
update pertumbuhan p
set status_gizi = case
  when (p.tinggi_badan / case when b.jenis_kelamin = 'Laki-laki' then 49.9 else 49.1 end) < 0.85
    then 'Stunting'
  when (p.tinggi_badan / case when b.jenis_kelamin = 'Laki-laki' then 49.9 else 49.1 end) < 0.90
    then 'Risiko Stunting'
  when (p.berat_badan / case when b.jenis_kelamin = 'Laki-laki' then 3.3 else 3.2 end) < 0.60
    then 'Gizi Buruk'
  when (p.berat_badan / case when b.jenis_kelamin = 'Laki-laki' then 3.3 else 3.2 end) < 0.75
    then 'Gizi Kurang'
  when (p.berat_badan / case when b.jenis_kelamin = 'Laki-laki' then 3.3 else 3.2 end) > 1.35
    then 'Obesitas'
  when (p.berat_badan / case when b.jenis_kelamin = 'Laki-laki' then 3.3 else 3.2 end) > 1.20
    then 'Gizi Lebih'
  when (p.berat_badan / case when b.jenis_kelamin = 'Laki-laki' then 3.3 else 3.2 end) > 1.10
    then 'Risiko Gizi Lebih'
  else 'Normal'
end
from balita b
where p.balita_id = b.id
  and p.usia_bulan = 0
  and p.status_gizi = 'Tidak diketahui';
