-- =====================================================================
-- e-SKPB — Schema database Supabase
-- Disusun dari desain Figma "E-SKPB (Copy)", page HI-fi
-- (layar 00 Login s.d. 19, 06A–06C Ubah Pengajuan, layar tambahan 20–46)
--
-- Cara pakai: buka Supabase Dashboard → SQL Editor → tempel seluruh file
-- ini → Run. Setelah itu jalankan seed.sql untuk data contoh.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ENUM
-- ---------------------------------------------------------------------
create type public.hari_kuliah   as enum ('senin','selasa','rabu','kamis','jumat','sabtu');
create type public.status_antrean as enum ('menunggu','dipanggil','selesai','dibatalkan');
create type public.hasil_validasi as enum ('lolos','gagal');
create type public.alasan_gagal   as enum ('prasyarat','batas_sks','bentrok_jadwal','kuota_penuh');

-- ---------------------------------------------------------------------
-- 2. DATA MASTER (dibaca semua mahasiswa, diisi admin / seed)
-- ---------------------------------------------------------------------

-- Program studi (layar 07 Profil, 18 Edit Profil, 41 Pilih Departemen)
create table public.program_studi (
  id         bigint generated always as identity primary key,
  nama       text not null unique,          -- "Sistem Informasi"
  departemen text                           -- "Departemen Sistem Informasi"
);

-- Semester aktif (layar 01: "SEMESTER GENAP 2025/2026")
create table public.semester (
  id       bigint generated always as identity primary key,
  nama     text not null unique,            -- "Genap 2025/2026"
  is_aktif boolean not null default false
);
-- hanya boleh ada 1 semester aktif
create unique index semester_satu_aktif on public.semester (is_aktif) where is_aktif;

-- Kelompok MK Bersama (layar 02/08: Basic Science, Wawasan Kebangsaan, ...)
create table public.kelompok_mk (
  id   bigint generated always as identity primary key,
  nama text not null unique
);

-- Mata kuliah (Kalkulus 2, Pancasila, ...)
create table public.mata_kuliah (
  id          bigint generated always as identity primary key,
  kode        text not null unique,
  nama        text not null,
  sks         smallint not null check (sks between 1 and 6),
  kelompok_id bigint references public.kelompok_mk(id) on delete set null
);

-- Prasyarat (layar 03: "Prasyarat: Kalkulus 1")
create table public.prasyarat (
  mk_id           bigint not null references public.mata_kuliah(id) on delete cascade,
  prasyarat_mk_id bigint not null references public.mata_kuliah(id) on delete cascade,
  primary key (mk_id, prasyarat_mk_id),
  check (mk_id <> prasyarat_mk_id)
);

-- Kelas yang dibuka per semester (layar 02 Kuota, 03 Detail Kelas)
create table public.kelas (
  id          bigint generated always as identity primary key,
  mk_id       bigint not null references public.mata_kuliah(id) on delete cascade,
  semester_id bigint not null references public.semester(id) on delete cascade,
  nomor       smallint not null,              -- "Kelas 18"
  hari        public.hari_kuliah not null,    -- "Selasa"
  jam_mulai   time not null,                  -- 10.00
  jam_selesai time not null,                  -- 11.40
  gedung      text,                           -- "Tower 1"
  ruangan     text,                           -- "TW1-503"
  dosen       text,                           -- "Tim Dosen SKPB"
  kuota       smallint not null check (kuota > 0),
  terisi      smallint not null default 0 check (terisi >= 0),   -- sudah masuk KRS
  dipesan     smallint not null default 0 check (dipesan >= 0),  -- sedang di antrean aktif (otomatis)
  unique (mk_id, semester_id, nomor),
  check (jam_selesai > jam_mulai),
  -- kursi tidak bisa dipesan melebihi kuota
  constraint kelas_tidak_overbooking check (terisi + dipesan <= kuota)
);
create index kelas_semester_idx on public.kelas (semester_id);

-- Topik bantuan (layar 17 Bantuan e-SKPB, 43, 44)
create table public.topik_bantuan (
  id        bigint generated always as identity primary key,
  judul     text not null,                  -- "Kuota kelas"
  deskripsi text,                           -- "Cara membaca dan mencari kuota"
  isi       text,
  urutan    smallint not null default 0
);

-- ---------------------------------------------------------------------
-- 3. DATA MAHASISWA
-- ---------------------------------------------------------------------

-- Profil, 1:1 dengan auth.users (layar 00 Login, 07 Profil, 18 Edit Profil)
create table public.profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  nrp              text unique,                       -- "5026241129"
  nama             text not null default '',
  email            text not null,                     -- email ITS, terkunci
  no_telp          text,
  program_studi_id bigint references public.program_studi(id) on delete set null,
  status_akademik  text not null default 'Aktif',
  ip_semester      numeric(3,2) check (ip_semester between 0 and 4),
  batas_sks        smallint not null default 24,      -- "18 dari maksimum 24 SKS"
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Mata kuliah yang sudah lulus → untuk cek prasyarat
create table public.mk_lulus (
  profile_id uuid   not null references public.profiles(id) on delete cascade,
  mk_id      bigint not null references public.mata_kuliah(id) on delete cascade,
  nilai      text,
  primary key (profile_id, mk_id)
);

-- KRS aktif → untuk hitung SKS diambil & cek bentrok jadwal
-- (layar 01: "18 SKS diambil", "Kelas berikutnya")
create table public.krs (
  id         bigint generated always as identity primary key,
  profile_id uuid   not null references public.profiles(id) on delete cascade,
  kelas_id   bigint not null references public.kelas(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, kelas_id)
);
create index krs_profile_idx on public.krs (profile_id);

-- Hasil validasi kelayakan (layar 04, 05, 09, 10, 36, 45, 46)
create table public.validasi (
  id               bigint generated always as identity primary key,
  profile_id       uuid   not null references public.profiles(id) on delete cascade,
  kelas_id         bigint not null references public.kelas(id) on delete cascade,
  hasil            public.hasil_validasi not null,
  prasyarat_ok     boolean not null,
  sks_ok           boolean not null,
  jadwal_ok        boolean not null,
  kuota_ok         boolean not null,
  alasan_gagal     public.alasan_gagal,               -- null kalau lolos
  bentrok_kelas_id bigint references public.kelas(id) on delete set null,
  sks_setelah      smallint,                          -- total SKS kalau kelas ini diambil
  keterangan       text,                              -- "Kalkulus 2 bertabrakan dengan Pancasila — Kelas 7."
  created_at       timestamptz not null default now()
);
create index validasi_profile_idx on public.validasi (profile_id, created_at desc);

-- Antrean digital (layar 06, 12, 13, 14, 19, 38, 06C)
create table public.antrean (
  id             bigint generated always as identity primary key,
  profile_id     uuid   not null references public.profiles(id) on delete cascade,
  kelas_id       bigint not null references public.kelas(id),
  semester_id    bigint not null references public.semester(id),
  validasi_id    bigint references public.validasi(id) on delete set null,
  urutan         int    not null,                     -- 40
  nomor          text   not null,                     -- "A-040"
  status         public.status_antrean not null default 'menunggu',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  dipanggil_at   timestamptz,
  selesai_at     timestamptz,
  dibatalkan_at  timestamptz,
  unique (semester_id, urutan)
);
-- 1 mahasiswa hanya boleh punya 1 antrean aktif
create unique index antrean_satu_aktif on public.antrean (profile_id)
  where status in ('menunggu','dipanggil');
create index antrean_profile_idx on public.antrean (profile_id, created_at desc);

-- Riwayat ubah pengajuan (layar 06A, 06B, 06C)
create table public.perubahan_pengajuan (
  id            bigint generated always as identity primary key,
  antrean_id    bigint not null references public.antrean(id) on delete cascade,
  kelas_lama_id bigint not null references public.kelas(id),
  kelas_baru_id bigint not null references public.kelas(id),
  validasi_id   bigint references public.validasi(id) on delete set null,
  created_at    timestamptz not null default now()
);

-- Notifikasi (layar 13 Notifikasi Giliran, feedback "Pengajuan berhasil diperbarui")
create table public.notifikasi (
  id         bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  antrean_id bigint references public.antrean(id) on delete cascade,
  tipe       text not null,                 -- 'giliran_dekat' | 'estimasi_berubah' | 'pengajuan_diubah' | ...
  judul      text not null,
  isi        text,
  dibaca     boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifikasi_profile_idx on public.notifikasi (profile_id, created_at desc);

-- Pengaturan notifikasi (layar 16, 42)
create table public.pengaturan_notifikasi (
  profile_id         uuid primary key references public.profiles(id) on delete cascade,
  giliran_dekat      boolean not null default true,
  perubahan_estimasi boolean not null default true,
  ringkasan_mingguan boolean not null default false,
  suara              boolean not null default true,
  updated_at         timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4. TRIGGER
-- ---------------------------------------------------------------------

-- updated_at otomatis
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_updated_at  before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger antrean_updated_at   before update on public.antrean
  for each row execute function public.set_updated_at();
create trigger pengaturan_updated_at before update on public.pengaturan_notifikasi
  for each row execute function public.set_updated_at();

-- Saat user baru daftar/login pertama kali → buat profil + pengaturan default.
-- NRP diambil dari email ITS kalau bagian depannya angka (5026241129@student.its.ac.id).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_lokal text := split_part(new.email, '@', 1);
begin
  insert into public.profiles (id, email, nama, nrp)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'nama', new.raw_user_meta_data->>'full_name', ''),
    case when v_lokal ~ '^[0-9]+$' then v_lokal end
  );
  insert into public.pengaturan_notifikasi (profile_id) values (new.id);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Sinkron kursi kelas setiap antrean berubah:
--   * dipesan = jumlah antrean aktif (menunggu/dipanggil) di kelas itu
--   * saat antrean jadi 'selesai' (dilayani petugas) → terisi +1 & masuk KRS
create or replace function public.antrean_sync_kelas()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_selesai boolean := tg_op = 'UPDATE' and new.status = 'selesai'
                       and old.status is distinct from 'selesai';
begin
  if tg_op in ('UPDATE','DELETE') then
    update public.kelas k
       set dipesan = (select count(*) from public.antrean a
                      where a.kelas_id = k.id and a.status in ('menunggu','dipanggil')),
           terisi  = k.terisi + case when v_selesai and k.id = old.kelas_id
                                     and old.kelas_id = new.kelas_id then 1 else 0 end
     where k.id = old.kelas_id;
  end if;
  if tg_op = 'INSERT' or (tg_op = 'UPDATE' and new.kelas_id <> old.kelas_id) then
    update public.kelas k
       set dipesan = (select count(*) from public.antrean a
                      where a.kelas_id = k.id and a.status in ('menunggu','dipanggil'))
     where k.id = new.kelas_id;
  end if;
  if v_selesai then
    insert into public.krs (profile_id, kelas_id) values (new.profile_id, new.kelas_id)
      on conflict do nothing;
  end if;
  return null;
end $$;

create trigger antrean_sync_kelas
  after insert or update of status, kelas_id or delete on public.antrean
  for each row execute function public.antrean_sync_kelas();

-- isi timestamp otomatis saat status berubah
create or replace function public.antrean_set_waktu()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.status is distinct from old.status then
    case new.status
      when 'dipanggil'  then new.dipanggil_at  := coalesce(new.dipanggil_at, now());
      when 'selesai'    then new.selesai_at    := coalesce(new.selesai_at, now());
      when 'dibatalkan' then new.dibatalkan_at := coalesce(new.dibatalkan_at, now());
      else null;
    end case;
  end if;
  return new;
end $$;

create trigger antrean_set_waktu
  before update of status on public.antrean
  for each row execute function public.antrean_set_waktu();

-- ---------------------------------------------------------------------
-- 5. VIEW (security_invoker = RLS tetap berlaku)
-- ---------------------------------------------------------------------

-- Daftar kelas siap tampil (layar 02 Kuota, 03 Detail, 08 Filter, 22)
create view public.v_kelas with (security_invoker = true) as
select
  k.id, k.semester_id, k.nomor, k.hari, k.jam_mulai, k.jam_selesai,
  k.gedung, k.ruangan, k.dosen, k.kuota, k.terisi, k.dipesan,
  (k.kuota - k.terisi - k.dipesan)         as sisa_kursi,
  case
    when k.kuota - k.terisi - k.dipesan <= 0 then 'penuh'
    when k.kuota - k.terisi - k.dipesan <= 3 then 'hampir_penuh'
    else 'tersedia'
  end                                      as status_kuota,
  case
    when k.jam_mulai < '11:00' then 'pagi'
    when k.jam_mulai < '15:00' then 'siang'
    else 'sore'
  end                                      as waktu,
  m.id   as mk_id, m.kode, m.nama as nama_mk, m.sks,
  g.id   as kelompok_id, g.nama as kelompok,
  (select string_agg(p2.nama, ', ')
     from public.prasyarat p
     join public.mata_kuliah p2 on p2.id = p.prasyarat_mk_id
    where p.mk_id = m.id)                  as prasyarat
from public.kelas k
join public.mata_kuliah m on m.id = k.mk_id
left join public.kelompok_mk g on g.id = m.kelompok_id;

-- Riwayat layanan gabungan antrean + validasi (layar 15, 39, 40)
create view public.v_riwayat_layanan with (security_invoker = true) as
select
  'antrean'::text  as jenis,
  a.id, a.profile_id, a.created_at,
  m.nama || ' — Kelas ' || k.nomor as judul,
  'Antrean ' || a.nomor            as subjudul,
  a.status::text                   as status
from public.antrean a
join public.kelas k on k.id = a.kelas_id
join public.mata_kuliah m on m.id = k.mk_id
union all
select
  'validasi', v.id, v.profile_id, v.created_at,
  'Validasi ' || m.nama || ' — Kelas ' || k.nomor,
  'Kelayakan akademik',
  v.hasil::text
from public.validasi v
join public.kelas k on k.id = v.kelas_id
join public.mata_kuliah m on m.id = k.mk_id;

-- ---------------------------------------------------------------------
-- 6. FUNCTION / RPC — dipanggil dari Flutter via supabase.rpc(...)
-- ---------------------------------------------------------------------

-- Menit rata-rata per antrean (17 antrean ≈ 25 menit)
create or replace function public.menit_per_antrean()
returns numeric language sql immutable as $$ select 1.5 $$;

-- 6a. Validasi kelayakan (layar 04 → 09 → 05 / 10 / 36 / 45 / 46)
--     Flutter: supabase.rpc('validasi_kelas', params: {'p_kelas_id': 18})
create or replace function public.validasi_kelas(p_kelas_id bigint, p_abaikan_kelas_id bigint default null)
returns public.validasi
language plpgsql security definer set search_path = '' as $$
declare
  v_uid       uuid := auth.uid();
  v_kelas     public.kelas;
  v_mk        public.mata_kuliah;
  v_batas     smallint;
  v_sks_now   int;
  v_prasyarat boolean;
  v_sks       boolean;
  v_jadwal    boolean;
  v_kuota     boolean;
  v_bentrok   public.kelas;
  v_bentrok_mk text;
  v_alasan    public.alasan_gagal;
  v_ket       text;
  v_row       public.validasi;
begin
  if v_uid is null then raise exception 'Belum login'; end if;

  select * into v_kelas from public.kelas where id = p_kelas_id;
  if not found then raise exception 'Kelas tidak ditemukan'; end if;
  select * into v_mk from public.mata_kuliah where id = v_kelas.mk_id;
  select batas_sks into v_batas from public.profiles where id = v_uid;

  -- Prasyarat: semua MK prasyarat sudah lulus
  v_prasyarat := not exists (
    select 1 from public.prasyarat p
    where p.mk_id = v_mk.id
      and not exists (select 1 from public.mk_lulus l
                      where l.profile_id = v_uid and l.mk_id = p.prasyarat_mk_id));

  -- Batas SKS: SKS di KRS semester ini + SKS kelas baru ≤ batas
  select coalesce(sum(m.sks), 0) into v_sks_now
  from public.krs r
  join public.kelas k on k.id = r.kelas_id
  join public.mata_kuliah m on m.id = k.mk_id
  where r.profile_id = v_uid and k.semester_id = v_kelas.semester_id;
  v_sks := v_sks_now + v_mk.sks <= v_batas;

  -- Bentrok jadwal dengan KRS aktif (hari sama & jam beririsan)
  select k.* into v_bentrok
  from public.krs r
  join public.kelas k on k.id = r.kelas_id
  where r.profile_id = v_uid
    and k.semester_id = v_kelas.semester_id
    and k.id <> v_kelas.id
    and k.id is distinct from p_abaikan_kelas_id
    and k.hari = v_kelas.hari
    and k.jam_mulai < v_kelas.jam_selesai
    and v_kelas.jam_mulai < k.jam_selesai
  limit 1;
  v_jadwal := v_bentrok.id is null;

  -- Kuota (kursi yang sedang dipesan antrean lain ikut dihitung)
  v_kuota := v_kelas.terisi + v_kelas.dipesan < v_kelas.kuota;

  if not v_prasyarat then
    v_alasan := 'prasyarat';
    v_ket := 'Prasyarat ' || v_mk.nama || ' belum terpenuhi.';
  elsif not v_sks then
    v_alasan := 'batas_sks';
    v_ket := 'Total SKS menjadi ' || (v_sks_now + v_mk.sks) || ', melebihi batas ' || v_batas || ' SKS.';
  elsif not v_jadwal then
    v_alasan := 'bentrok_jadwal';
    select nama into v_bentrok_mk from public.mata_kuliah where id = v_bentrok.mk_id;
    v_ket := v_mk.nama || ' bertabrakan dengan ' || v_bentrok_mk || ' — Kelas ' || v_bentrok.nomor || '.';
  elsif not v_kuota then
    v_alasan := 'kuota_penuh';
    v_ket := 'Kuota kelas sudah penuh.';
  end if;

  insert into public.validasi (profile_id, kelas_id, hasil, prasyarat_ok, sks_ok, jadwal_ok,
                               kuota_ok, alasan_gagal, bentrok_kelas_id, sks_setelah, keterangan)
  values (v_uid, p_kelas_id,
          case when v_alasan is null then 'lolos' else 'gagal' end::public.hasil_validasi,
          v_prasyarat, v_sks, v_jadwal, v_kuota, v_alasan, v_bentrok.id,
          v_sks_now + v_mk.sks, v_ket)
  returning * into v_row;

  return v_row;
end $$;

-- 6b. Ambil nomor antrean (layar 12 → 06)
--     Syarat: ada validasi LOLOS untuk kelas itu dalam 1 jam terakhir.
create or replace function public.ambil_antrean(p_kelas_id bigint)
returns public.antrean
language plpgsql security definer set search_path = '' as $$
declare
  v_uid      uuid := auth.uid();
  v_semester bigint;
  v_validasi bigint;
  v_urutan   int;
  v_row      public.antrean;
begin
  if v_uid is null then raise exception 'Belum login'; end if;

  select semester_id into v_semester from public.kelas where id = p_kelas_id;
  if not found then raise exception 'Kelas tidak ditemukan'; end if;

  select id into v_validasi from public.validasi
  where profile_id = v_uid and kelas_id = p_kelas_id and hasil = 'lolos'
    and created_at > now() - interval '1 hour'
  order by created_at desc limit 1;
  if v_validasi is null then
    raise exception 'Lakukan validasi kelayakan terlebih dahulu';
  end if;

  if exists (select 1 from public.antrean where profile_id = v_uid
             and status in ('menunggu','dipanggil')) then
    raise exception 'Kamu masih punya antrean aktif';
  end if;

  -- kursi masih ada? (kunci baris kelas supaya tidak rebutan)
  if not exists (select 1 from public.kelas where id = p_kelas_id
                 and terisi + dipesan < kuota for update) then
    raise exception 'Kuota kelas sudah penuh';
  end if;

  -- kunci per semester supaya dua orang tidak dapat nomor yang sama
  perform pg_advisory_xact_lock(hashtext('antrean'), v_semester::int);
  select coalesce(max(urutan), 0) + 1 into v_urutan
  from public.antrean where semester_id = v_semester;

  insert into public.antrean (profile_id, kelas_id, semester_id, validasi_id, urutan, nomor)
  values (v_uid, p_kelas_id, v_semester, v_validasi, v_urutan,
          'A-' || lpad(v_urutan::text, 3, '0'))
  returning * into v_row;

  return v_row;
end $$;

-- 6c. Status antrean aktif milikku (layar 01 kartu Antrean Aktif, 06, 06C, 38)
--     Mengembalikan: nomor, posisi sekarang (23/40), sisa (17), persen (58), estimasi (25 menit)
create or replace function public.status_antrean_saya()
returns table (
  antrean_id      bigint,
  nomor           text,
  status          public.status_antrean,
  urutan          int,
  sedang_dilayani int,
  sisa_sebelum    int,
  persen          int,
  estimasi_menit  int,
  kelas_id        bigint,
  nama_mk         text,
  nomor_kelas     smallint,
  sks             smallint
)
language sql stable security definer set search_path = '' as $$
  with saya as (
    select a.* from public.antrean a
    where a.profile_id = auth.uid() and a.status in ('menunggu','dipanggil')
    order by a.created_at desc limit 1
  ), dilayani as (
    select coalesce(max(a.urutan), 0) as n
    from public.antrean a, saya s
    where a.semester_id = s.semester_id and a.status in ('dipanggil','selesai')
  ), sisa as (
    -- antrean yang masih menunggu antara nomor yang dilayani dan nomorku
    -- (yang dibatalkan tidak dihitung). Contoh Figma: dilayani 23, aku 40 → 17
    select count(*)::int as n
    from public.antrean a, saya s, dilayani d
    where a.semester_id = s.semester_id and a.status = 'menunggu'
      and a.urutan > d.n and a.urutan <= s.urutan
  )
  select s.id, s.nomor, s.status, s.urutan,
         d.n,
         r.n,
         round(100.0 * d.n / s.urutan)::int,
         floor(r.n * public.menit_per_antrean())::int,
         k.id, m.nama, k.nomor, m.sks
  from saya s
  cross join dilayani d
  cross join sisa r
  join public.kelas k on k.id = s.kelas_id
  join public.mata_kuliah m on m.id = k.mk_id;
$$;

-- 6d. Batalkan antrean (layar 14 → 19)
create or replace function public.batalkan_antrean(p_antrean_id bigint)
returns public.antrean
language plpgsql security definer set search_path = '' as $$
declare v_row public.antrean;
begin
  update public.antrean
     set status = 'dibatalkan', dibatalkan_at = now()
   where id = p_antrean_id and profile_id = auth.uid()
     and status in ('menunggu','dipanggil')
  returning * into v_row;
  if v_row.id is null then raise exception 'Antrean tidak ditemukan atau sudah tidak aktif'; end if;
  return v_row;
end $$;

-- 6e. Ubah pengajuan / ganti kelas tanpa kehilangan nomor antrean (layar 06A → 06B → 06C)
--     06B: panggil validasi_kelas(kelas_baru, kelas_lama) untuk menampilkan ringkasan.
--     Tombol "Simpan Perubahan": panggil fungsi ini. Nomor antrean (A-040) tetap.
create or replace function public.ubah_pengajuan(p_antrean_id bigint, p_kelas_baru_id bigint)
returns public.antrean
language plpgsql security definer set search_path = '' as $$
declare
  v_uid  uuid := auth.uid();
  v_ant  public.antrean;
  v_val  public.validasi;
  v_nama text;
begin
  select * into v_ant from public.antrean
  where id = p_antrean_id and profile_id = v_uid and status = 'menunggu'
  for update;
  if not found then raise exception 'Antrean tidak ditemukan atau tidak bisa diubah'; end if;
  if v_ant.kelas_id = p_kelas_baru_id then raise exception 'Kelas pengganti sama dengan kelas saat ini'; end if;
  if (select semester_id from public.kelas where id = p_kelas_baru_id) <> v_ant.semester_id then
    raise exception 'Kelas pengganti harus di semester yang sama';
  end if;

  v_val := public.validasi_kelas(p_kelas_baru_id, v_ant.kelas_id);
  if v_val.hasil <> 'lolos' then
    raise exception 'Kelas pengganti tidak lolos validasi: %', v_val.keterangan;
  end if;

  insert into public.perubahan_pengajuan (antrean_id, kelas_lama_id, kelas_baru_id, validasi_id)
  values (v_ant.id, v_ant.kelas_id, p_kelas_baru_id, v_val.id);

  update public.antrean set kelas_id = p_kelas_baru_id, validasi_id = v_val.id
  where id = v_ant.id returning * into v_ant;

  select m.nama || ' – Kelas ' || k.nomor into v_nama
  from public.kelas k join public.mata_kuliah m on m.id = k.mk_id where k.id = p_kelas_baru_id;

  insert into public.notifikasi (profile_id, antrean_id, tipe, judul, isi)
  values (v_uid, v_ant.id, 'pengajuan_diubah', 'Pengajuan berhasil diperbarui',
          'Pengajuan antrean ' || v_ant.nomor || ' diganti ke ' || v_nama || '.');

  return v_ant;
end $$;

-- Hak akses fungsi: hanya user yang sudah login
revoke execute on function public.validasi_kelas(bigint, bigint)   from public, anon;
revoke execute on function public.ambil_antrean(bigint)            from public, anon;
revoke execute on function public.status_antrean_saya()            from public, anon;
revoke execute on function public.batalkan_antrean(bigint)         from public, anon;
revoke execute on function public.ubah_pengajuan(bigint, bigint)   from public, anon;
revoke execute on function public.handle_new_user()                from public, anon, authenticated;
revoke execute on function public.antrean_sync_kelas()             from public, anon, authenticated;
grant  execute on function public.validasi_kelas(bigint, bigint)   to authenticated;
grant  execute on function public.ambil_antrean(bigint)            to authenticated;
grant  execute on function public.status_antrean_saya()            to authenticated;
grant  execute on function public.batalkan_antrean(bigint)         to authenticated;
grant  execute on function public.ubah_pengajuan(bigint, bigint)   to authenticated;

-- ---------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table public.program_studi         enable row level security;
alter table public.semester              enable row level security;
alter table public.kelompok_mk           enable row level security;
alter table public.mata_kuliah           enable row level security;
alter table public.prasyarat             enable row level security;
alter table public.kelas                 enable row level security;
alter table public.topik_bantuan         enable row level security;
alter table public.profiles              enable row level security;
alter table public.mk_lulus              enable row level security;
alter table public.krs                   enable row level security;
alter table public.validasi              enable row level security;
alter table public.antrean               enable row level security;
alter table public.perubahan_pengajuan   enable row level security;
alter table public.notifikasi            enable row level security;
alter table public.pengaturan_notifikasi enable row level security;

-- Data master: boleh dibaca semua user login
create policy "baca master" on public.program_studi for select to authenticated using (true);
create policy "baca master" on public.semester      for select to authenticated using (true);
create policy "baca master" on public.kelompok_mk   for select to authenticated using (true);
create policy "baca master" on public.mata_kuliah   for select to authenticated using (true);
create policy "baca master" on public.prasyarat     for select to authenticated using (true);
create policy "baca master" on public.kelas         for select to authenticated using (true);
create policy "baca master" on public.topik_bantuan for select to authenticated using (true);

-- Profil: lihat & ubah milik sendiri
create policy "profil sendiri" on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "ubah profil sendiri" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
-- Hanya kolom ini yang boleh diubah dari aplikasi (email & NRP terkunci, layar 18)
revoke update on public.profiles from authenticated;
grant  update (nama, no_telp, program_studi_id) on public.profiles to authenticated;

-- Data akademik pribadi: hanya baca milik sendiri (diisi admin / seed)
create policy "lulus sendiri"   on public.mk_lulus for select to authenticated using (profile_id = (select auth.uid()));
create policy "krs sendiri"     on public.krs      for select to authenticated using (profile_id = (select auth.uid()));
create policy "validasi sendiri" on public.validasi for select to authenticated using (profile_id = (select auth.uid()));
create policy "antrean sendiri" on public.antrean  for select to authenticated using (profile_id = (select auth.uid()));
-- (insert/update validasi & antrean HANYA lewat fungsi RPC di atas)

create policy "perubahan sendiri" on public.perubahan_pengajuan for select to authenticated
  using (exists (select 1 from public.antrean a
                 where a.id = antrean_id and a.profile_id = (select auth.uid())));

create policy "notif sendiri"       on public.notifikasi for select to authenticated
  using (profile_id = (select auth.uid()));
create policy "tandai notif dibaca" on public.notifikasi for update to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));
revoke update on public.notifikasi from authenticated;
grant  update (dibaca) on public.notifikasi to authenticated;

create policy "pengaturan sendiri" on public.pengaturan_notifikasi for select to authenticated
  using (profile_id = (select auth.uid()));
create policy "ubah pengaturan sendiri" on public.pengaturan_notifikasi for update to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- 8. REALTIME ("Data real-time" di layar 02, "Perbarui Status" di layar 06)
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.kelas, public.antrean, public.notifikasi;
  end if;
end $$;
