import '../widgets/status_pill.dart';

/// Satu baris dari view `v_kelas` (kelas + info mata kuliah + status kuota).
class Kelas {
  const Kelas({
    required this.id,
    required this.semesterId,
    required this.nomor,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kuota,
    required this.terisi,
    required this.dipesan,
    required this.sisaKursi,
    required this.statusKuota,
    required this.waktu,
    required this.mkId,
    required this.kode,
    required this.namaMk,
    required this.sks,
    this.gedung,
    this.ruangan,
    this.dosen,
    this.kelompok,
    this.prasyarat,
  });

  final int id;
  final int semesterId;
  final int nomor;
  final String hari; // senin..sabtu
  final String jamMulai; // HH:mm
  final String jamSelesai; // HH:mm
  final String? gedung;
  final String? ruangan;
  final String? dosen;
  final int kuota;
  final int terisi;
  final int dipesan;
  final int sisaKursi;
  final String statusKuota; // tersedia | hampir_penuh | penuh
  final String waktu; // pagi | siang | sore
  final int mkId;
  final String kode;
  final String namaMk;
  final int sks;
  final String? kelompok;
  final String? prasyarat;

  factory Kelas.fromJson(Map<String, dynamic> j) => Kelas(
        id: (j['id'] as num).toInt(),
        semesterId: (j['semester_id'] as num).toInt(),
        nomor: (j['nomor'] as num).toInt(),
        hari: j['hari'] as String,
        jamMulai: _hhmm(j['jam_mulai'] as String),
        jamSelesai: _hhmm(j['jam_selesai'] as String),
        gedung: j['gedung'] as String?,
        ruangan: j['ruangan'] as String?,
        dosen: j['dosen'] as String?,
        kuota: (j['kuota'] as num).toInt(),
        terisi: (j['terisi'] as num).toInt(),
        dipesan: (j['dipesan'] as num).toInt(),
        sisaKursi: (j['sisa_kursi'] as num).toInt(),
        statusKuota: j['status_kuota'] as String,
        waktu: j['waktu'] as String,
        mkId: (j['mk_id'] as num).toInt(),
        kode: j['kode'] as String,
        namaMk: j['nama_mk'] as String,
        sks: (j['sks'] as num).toInt(),
        kelompok: j['kelompok'] as String?,
        prasyarat: j['prasyarat'] as String?,
      );

  static String _hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  static const urutanHari = [
    'senin',
    'selasa',
    'rabu',
    'kamis',
    'jumat',
    'sabtu',
  ];

  String get judul => '$namaMk — Kelas $nomor';
  String get hariLabel => hari.isEmpty ? '' : hari[0].toUpperCase() + hari.substring(1);
  String get jamLabel => jamMulai.replaceAll(':', '.');
  String get rentangJam =>
      '${jamMulai.replaceAll(':', '.')}–${jamSelesai.replaceAll(':', '.')}';
  String get lokasi =>
      [gedung, ruangan].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  QuotaStatus get status => QuotaStatus.fromDb(statusKuota);
  bool get penuh => statusKuota == 'penuh';

  /// Bagian kuota yang sudah terpakai (0..1), untuk progress bar.
  double get terpakai => kuota == 0 ? 1 : ((kuota - sisaKursi) / kuota).clamp(0, 1);

  int get _mulaiMenit => _menit(jamMulai);
  int get _selesaiMenit => _menit(jamSelesai);
  static int _menit(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  /// Hari sama dan jam beririsan.
  bool bentrokDengan(Kelas o) =>
      o.id != id &&
      o.hari == hari &&
      _mulaiMenit < o._selesaiMenit &&
      o._mulaiMenit < _selesaiMenit;

  /// Indeks hari (0 = senin) untuk pengurutan.
  int get hariIndex => urutanHari.indexOf(hari);
  int get mulaiMenit => _mulaiMenit;
}
