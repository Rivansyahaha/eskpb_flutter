-- =====================================================================
-- e-SKPB — Data contoh (sesuai isi layar di Figma)
-- Jalankan SETELAH file migration. Aman dijalankan di database kosong.
-- =====================================================================

insert into public.semester (nama, is_aktif) values ('Genap 2025/2026', true);

insert into public.program_studi (nama, departemen) values
  ('Sistem Informasi',   'Departemen Sistem Informasi'),
  ('Teknik Informatika', 'Departemen Teknik Informatika'),
  ('Teknologi Informasi','Departemen Teknologi Informasi'),
  ('Teknik Elektro',     'Departemen Teknik Elektro'),
  ('Teknik Mesin',       'Departemen Teknik Mesin');

insert into public.kelompok_mk (nama) values
  ('Basic Science'), ('Wawasan Kebangsaan'), ('Bahasa & Literasi'), ('Komputasi');

insert into public.mata_kuliah (kode, nama, sks, kelompok_id) values
  ('SM1101', 'Kalkulus 1',         3, (select id from public.kelompok_mk where nama = 'Basic Science')),
  ('SM1201', 'Kalkulus 2',         3, (select id from public.kelompok_mk where nama = 'Basic Science')),
  ('SF1101', 'Fisika Dasar',       3, (select id from public.kelompok_mk where nama = 'Basic Science')),
  ('UG1901', 'Pancasila',          2, (select id from public.kelompok_mk where nama = 'Wawasan Kebangsaan')),
  ('UG1902', 'Bahasa Indonesia',   2, (select id from public.kelompok_mk where nama = 'Bahasa & Literasi')),
  ('KI1201', 'Algoritma',          3, (select id from public.kelompok_mk where nama = 'Komputasi')),
  ('KI1301', 'Basis Data',         3, (select id from public.kelompok_mk where nama = 'Komputasi')),
  ('KI1302', 'Jaringan Komputer',  3, (select id from public.kelompok_mk where nama = 'Komputasi')),
  ('KI1303', 'Sistem Operasi',     3, (select id from public.kelompok_mk where nama = 'Komputasi'));

-- Kalkulus 2 butuh Kalkulus 1; Basis Data butuh Algoritma
insert into public.prasyarat (mk_id, prasyarat_mk_id) values
  ((select id from public.mata_kuliah where kode = 'SM1201'), (select id from public.mata_kuliah where kode = 'SM1101')),
  ((select id from public.mata_kuliah where kode = 'KI1301'), (select id from public.mata_kuliah where kode = 'KI1201'));

-- Kelas (sisa kursi = kuota - terisi)
insert into public.kelas (mk_id, semester_id, nomor, hari, jam_mulai, jam_selesai, gedung, ruangan, dosen, kuota, terisi)
select m.id, s.id, v.nomor, v.hari::public.hari_kuliah, v.mulai::time, v.selesai::time,
       v.gedung, v.ruang, v.dosen, v.kuota, v.terisi
from (values
  ('SM1201', 18, 'selasa', '10:00', '11:40', 'Tower 1', 'TW1-503', 'Tim Dosen SKPB', 40, 38), -- hampir penuh, sisa 2
  ('SM1201', 24, 'kamis',  '13:00', '14:40', 'Tower 1', 'TW1-401', 'Tim Dosen SKPB', 40, 30), -- alternatif, sisa 10
  ('SM1201', 31, 'jumat',  '09:00', '10:40', 'Tower 2', 'TW2-302', 'Tim Dosen SKPB', 40, 35), -- alternatif, sisa 5
  ('UG1901',  7, 'selasa', '10:00', '11:40', 'Tower 2', 'TW2-201', 'Tim Dosen MKU',  40, 40), -- sumber bentrok
  ('UG1901', 24, 'kamis',  '13:00', '14:40', 'Tower 2', 'TW2-205', 'Tim Dosen MKU',  40, 30), -- sisa 10
  ('UG1902', 31, 'jumat',  '09:00', '10:40', 'Tower 2', 'TW2-110', 'Tim Dosen MKU',  40, 40), -- penuh
  ('SF1101', 12, 'rabu',   '13:00', '14:40', 'Tower 1', 'TW1-305', 'Tim Dosen SKPB', 40, 20),
  ('KI1201',  1, 'senin',  '07:00', '09:30', 'Gedung Informatika', 'IF-101', 'Tim Dosen IF', 40, 25),
  ('KI1301',  2, 'senin',  '13:00', '15:30', 'Gedung Informatika', 'IF-103', 'Tim Dosen IF', 40, 36),
  ('KI1301',  3, 'rabu',   '07:00', '09:30', 'Gedung Informatika', 'IF-104', 'Tim Dosen IF', 40, 15),
  ('KI1302',  1, 'kamis',  '07:00', '09:30', 'Gedung Informatika', 'IF-105', 'Tim Dosen IF', 40, 22),
  ('KI1303',  1, 'jumat',  '13:00', '15:30', 'Gedung Informatika', 'IF-106', 'Tim Dosen IF', 40, 40)  -- penuh
) as v(kode, nomor, hari, mulai, selesai, gedung, ruang, dosen, kuota, terisi)
join public.mata_kuliah m on m.kode = v.kode
cross join (select id from public.semester where is_aktif) s;

insert into public.topik_bantuan (judul, deskripsi, urutan) values
  ('Kuota kelas',        'Cara membaca dan mencari kuota',  1),
  ('Validasi kelayakan', 'Memahami hasil pemeriksaan',      2),
  ('Antrean digital',    'Mengelola nomor antrean',         3),
  ('Kendala akun',       'Akses dan sinkronisasi data',     4);

-- ---------------------------------------------------------------------
-- DATA DEMO UNTUK 1 AKUN (opsional)
-- 1) Daftar/login dulu di aplikasi (atau Authentication → Add user di dashboard)
-- 2) Ganti email di bawah, hapus tanda komentar, lalu Run.
-- ---------------------------------------------------------------------
-- do $$
-- declare v_uid uuid := (select id from auth.users where email = 'GANTI@student.its.ac.id');
-- begin
--   update public.profiles set nama = 'Firnas Fadaukas Ahmad', ip_semester = 4.00,
--     program_studi_id = (select id from public.program_studi where nama = 'Sistem Informasi')
--   where id = v_uid;
--   -- sudah lulus Kalkulus 1 dan Algoritma → lolos prasyarat Kalkulus 2 & Basis Data
--   insert into public.mk_lulus (profile_id, mk_id, nilai)
--   select v_uid, id, 'A' from public.mata_kuliah where kode in ('SM1101','KI1201');
--   -- KRS aktif: Pancasila Kelas 7 (Selasa 10.00) → Kalkulus 2 Kelas 18 akan BENTROK
--   insert into public.krs (profile_id, kelas_id)
--   select v_uid, k.id from public.kelas k join public.mata_kuliah m on m.id = k.mk_id
--   where (m.kode, k.nomor) in (('UG1901', 7));
-- end $$;
