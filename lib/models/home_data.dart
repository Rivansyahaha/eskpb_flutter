import 'kelas.dart';
import 'profile.dart';

/// Data yang dibutuhkan layar Beranda (selain antrean aktif).
class HomeData {
  const HomeData({
    required this.profile,
    required this.semesterNama,
    required this.krs,
  });

  final Profile profile;
  final String semesterNama;

  /// Kelas di KRS semester aktif.
  final List<Kelas> krs;

  /// True kalau ada dua kelas di KRS yang jadwalnya bertabrakan.
  bool get adaBentrok =>
      krs.any((a) => krs.any((b) => a.id != b.id && a.bentrokDengan(b)));

  int get sksDiambil => krs.fold(0, (sum, k) => sum + k.sks);

  /// Kelas terdekat dari [now] berdasarkan hari dan jam (mingguan, berputar).
  Kelas? nextClass(DateTime now) {
    if (krs.isEmpty) return null;
    final hariIni = now.weekday - 1; // senin = 0 (minggu = 6, tidak ada kelas)
    final menitIni = now.hour * 60 + now.minute;

    int jarak(Kelas k) {
      final hariBeda = (k.hariIndex - hariIni) % 7;
      final menit = hariBeda * 1440 + k.mulaiMenit - menitIni;
      return menit < 0 ? menit + 7 * 1440 : menit;
    }

    final sorted = [...krs]..sort((a, b) => jarak(a).compareTo(jarak(b)));
    return sorted.first;
  }
}
