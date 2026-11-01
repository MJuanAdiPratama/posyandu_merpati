-- Izinkan orang_tua insert notifikasi (untuk kirim ke kader saat daftar balita)
CREATE POLICY "Ortu kirim notifikasi" ON notifications
  FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'orang_tua');

