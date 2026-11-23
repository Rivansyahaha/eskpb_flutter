/// Satu baris hasil RPC `status_antrean_saya()`.
class QueueStatus {
  const QueueStatus({
    required this.antreanId,
    required this.nomor,
    required this.status,
    required this.urutan,
    required this.sedangDilayani,
    required this.sisaSebelum,
    required this.persen,
    required this.estimasiMenit,
    required this.kelasId,
    required this.namaMk,
    required this.nomorKelas,
    required this.sks,
  });

  final int antreanId;
  final String nomor; // "A-040"
  final String status; // menunggu | dipanggil
  final int urutan;
  final int sedangDilayani;
  final int sisaSebelum;
  final int persen;
  final int estimasiMenit;
  final int kelasId;
  final String namaMk;
  final int nomorKelas;
  final int sks;

  factory QueueStatus.fromJson(Map<String, dynamic> j) => QueueStatus(
        antreanId: (j['antrean_id'] as num).toInt(),
        nomor: j['nomor'] as String,
        status: j['status'] as String,
        urutan: (j['urutan'] as num).toInt(),
        sedangDilayani: (j['sedang_dilayani'] as num).toInt(),
        sisaSebelum: (j['sisa_sebelum'] as num).toInt(),
        persen: (j['persen'] as num).toInt(),
        estimasiMenit: (j['estimasi_menit'] as num).toInt(),
        kelasId: (j['kelas_id'] as num).toInt(),
        namaMk: j['nama_mk'] as String,
        nomorKelas: (j['nomor_kelas'] as num).toInt(),
        sks: (j['sks'] as num).toInt(),
      );

  bool get dipanggil => status == 'dipanggil';
  String get judulKelas => '$namaMk — Kelas $nomorKelas';
}
