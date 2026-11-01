-- Catatan:
-- Untuk setup database baru, pakai docs/database_setup.sql.
-- File ini adalah arsip/incremental lama.

-- ============================================================
-- SUPABASE STORAGE - Posyandu Merpati
-- Jalankan di Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Buat bucket edukasi-images (public read)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'edukasi-images',
  'edukasi-images',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy: siapa saja bisa READ/melihat gambar (public)
CREATE POLICY "Public read edukasi images"
ON storage.objects FOR SELECT
USING (bucket_id = 'edukasi-images');

-- 3. Policy: hanya kader (authenticated) yang bisa UPLOAD
CREATE POLICY "Kader dapat upload edukasi images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'edukasi-images'
  AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'kader'
);

-- 4. Policy: hanya kader yang bisa UPDATE gambar miliknya
CREATE POLICY "Kader dapat update edukasi images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'edukasi-images'
  AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'kader'
);

-- 5. Policy: hanya kader yang bisa DELETE gambar
CREATE POLICY "Kader dapat hapus edukasi images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'edukasi-images'
  AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'kader'
);
