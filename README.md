# DRAMA KITA Online MVP — Android PWA + Supabase

## Apa yang ditambahkan
- Registrasi/login kreator dengan Supabase Auth.
- Upload video dan poster ke Storage private.
- Metadata episode di database.
- Upload otomatis berstatus `pending`.
- Feed hanya menampilkan episode `approved`.
- Studio kreator menampilkan status kiriman.
- Tombol laporan konten.
- Signed URL video untuk episode yang disetujui.
- Kebijakan RLS dan storage policy awal.

## Prasyarat dan biaya
MVP ini memakai Supabase sebagai contoh backend. Paket gratis dapat berubah dan memiliki kuota/batas pemakaian; periksa halaman pricing dan limits Supabase sebelum mengaktifkan proyek. Penyimpanan video dan bandwidth adalah komponen yang paling cepat menghabiskan kuota. Modal Rp0 hanya realistis untuk prototipe/uji coba kecil dalam batas gratis; tidak ada jaminan layanan tetap gratis ketika pengguna dan tontonan bertambah. Hosting frontend statis dapat memakai GitHub Pages gratis.

## Setup Supabase
1. Buat proyek Supabase baru.
2. Buka SQL Editor dan jalankan seluruh isi `supabase/schema.sql`.
3. Di Storage, buat bucket bernama `drama-media` dan pastikan **Private** (bukan public).
4. Atur batas file dan MIME types di Storage: `video/mp4`, `video/webm`, `image/jpeg`, `image/png`, `image/webp`. Batas 50 MB di frontend hanya pemeriksaan awal; server-side bucket limit tetap wajib diatur.
5. Project Settings → API: salin Project URL dan anon/publishable key.
6. Buka `index.html`, ganti `PASTE_SUPABASE_PROJECT_URL` dan `PASTE_SUPABASE_ANON_OR_PUBLISHABLE_KEY`. Jangan pernah memasukkan `service_role` key ke frontend.
7. Untuk akun admin: daftar akun lewat aplikasi, cari UUID akun pada Authentication > Users, lalu jalankan SQL `update public.profiles set role='admin' where id='UUID';`.
8. Admin memoderasi melalui Table Editor: ubah `episodes.status` dari `pending` menjadi `approved` atau `rejected`; isi `moderation_note` bila ditolak. Tinjau tabel `reports` secara berkala.
9. Upload folder ini ke GitHub Pages (atau hosting statis HTTPS gratis). Buka URL GitHub Pages di Chrome Android → menu → Install app / Tambahkan ke layar utama.

## Cara tes di Android
1. Buka URL HTTPS aplikasi.
2. Daftar dengan email, selesaikan konfirmasi email bila diminta, lalu masuk.
3. Upload video pendek MP4/WebM dan centang pernyataan hak/izin.
4. Pastikan kiriman terlihat di Studio sebagai `PENDING`, dan belum tampil di feed publik.
5. Di Supabase Table Editor, ubah status episode ke `approved`.
6. Refresh feed; episode harus muncul dan dapat diputar.
7. Tes tombol laporan dengan akun lain.

## Keamanan dan batasan yang belum selesai
- Ini starter MVP, belum diaudit keamanan atau diuji beban. Jalankan uji sebelum produksi.
- Kebijakan profil mengizinkan pembacaan nama profil publik; jangan simpan email/nomor telepon di tabel profil.
- Moderasi awal dilakukan manual dari dashboard, belum ada panel admin di aplikasi.
- Belum ada komentar, like, follow, rekomendasi, transcode/resolusi adaptif, pembayaran, atau penghapusan akun mandiri.
- Kebijakan upload membatasi folder berdasarkan UID. Pertimbangkan kuota per kreator, rate limit, verifikasi email, captcha, pemeriksaan malware, dan batas durasi/ukuran di backend sebelum peluncuran.
- Signed URL berlaku 1 jam; feed membuat signed URL poster saat dimuat.
- Pastikan ada izin tertulis dari pemegang hak video, musik, gambar, dan persetujuan orang yang tampil. Sediakan proses takedown dan kontak pengaduan hak cipta.
- Supabase anon key memang digunakan di frontend bersama RLS; service role key tidak boleh dibagikan.
