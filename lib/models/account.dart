// Model kecil untuk layar Akun, Antrean, dan Bantuan.

class ProgramStudi {
  const ProgramStudi({required this.id, required this.nama, this.departemen});

  final int id;
  final String nama;
  final String? departemen;

  factory ProgramStudi.fromJson(Map<String, dynamic> j) => ProgramStudi(
        id: (j['id'] as num).toInt(),
        nama: j['nama'] as String,
        departemen: j['departemen'] as String?,
      );
}

class NotifSettings {
  const NotifSettings({
    required this.giliranDekat,
    required this.perubahanEstimasi,
    required this.ringkasanMingguan,
    required this.suara,
  });

  final bool giliranDekat;
  final bool perubahanEstimasi;
  final bool ringkasanMingguan;
  final bool suara;

  factory NotifSettings.fromJson(Map<String, dynamic> j) => NotifSettings(
        giliranDekat: j['giliran_dekat'] as bool,
        perubahanEstimasi: j['perubahan_estimasi'] as bool,
        ringkasanMingguan: j['ringkasan_mingguan'] as bool,
        suara: j['suara'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'giliran_dekat': giliranDekat,
        'perubahan_estimasi': perubahanEstimasi,
        'ringkasan_mingguan': ringkasanMingguan,
        'suara': suara,
      };
}

enum RiwayatKategori { berhasil, berjalan, dibatalkan, gagal }

/// Satu baris view `v_riwayat_layanan`.
class RiwayatItem {
  const RiwayatItem({
    required this.jenis,
    required this.id,
    required this.createdAt,
    required this.judul,
    required this.subjudul,
    required this.kategori,
  });

  final String jenis; // antrean | validasi
  final int id;
  final DateTime createdAt;
  final String judul;
  final String subjudul;
  final RiwayatKategori kategori;

  factory RiwayatItem.fromJson(Map<String, dynamic> j) => RiwayatItem(
        jenis: j['jenis'] as String,
        id: (j['id'] as num).toInt(),
        createdAt: DateTime.parse(j['created_at'] as String),
        judul: j['judul'] as String,
        subjudul: (j['subjudul'] as String?) ?? '',
        kategori: switch (j['status'] as String) {
          'selesai' || 'lolos' => RiwayatKategori.berhasil,
          'dibatalkan' => RiwayatKategori.dibatalkan,
          'gagal' => RiwayatKategori.gagal,
          _ => RiwayatKategori.berjalan, // menunggu, dipanggil
        },
      );
}

class TopikBantuan {
  const TopikBantuan({
    required this.id,
    required this.judul,
    this.deskripsi,
    this.isi,
  });

  final int id;
  final String judul;
  final String? deskripsi;
  final String? isi;

  factory TopikBantuan.fromJson(Map<String, dynamic> j) => TopikBantuan(
        id: (j['id'] as num).toInt(),
        judul: j['judul'] as String,
        deskripsi: j['deskripsi'] as String?,
        isi: j['isi'] as String?,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.judul,
    this.isi,
    this.antreanId,
  });

  final int id;
  final String judul;
  final String? isi;
  final int? antreanId;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num).toInt(),
        judul: j['judul'] as String,
        isi: j['isi'] as String?,
        antreanId: (j['antrean_id'] as num?)?.toInt(),
      );
}

/// Hasil `batalkan_antrean`.
class CancelResult {
  const CancelResult({
    required this.nomor,
    required this.judulKelas,
    this.dibatalkanAt,
  });

  final String nomor;
  final String judulKelas;
  final DateTime? dibatalkanAt;
}
