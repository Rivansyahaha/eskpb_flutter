/// Baris dari tabel `profiles` (+ nama program studi).
class Profile {
  const Profile({
    required this.id,
    required this.nama,
    required this.email,
    required this.batasSks,
    this.nrp,
    this.noTelp,
    this.ipSemester,
    this.programStudi,
    this.programStudiId,
    this.statusAkademik = 'Aktif',
  });

  final String id;
  final String nama;
  final String email;
  final String? nrp;
  final String? noTelp;
  final double? ipSemester;
  final int batasSks;
  final String? programStudi;
  final int? programStudiId;
  final String statusAkademik;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        nama: (j['nama'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        nrp: j['nrp'] as String?,
        noTelp: j['no_telp'] as String?,
        ipSemester: (j['ip_semester'] as num?)?.toDouble(),
        batasSks: (j['batas_sks'] as num?)?.toInt() ?? 24,
        programStudi: (j['program_studi'] as Map?)?['nama'] as String?,
        programStudiId: (j['program_studi_id'] as num?)?.toInt(),
        statusAkademik: (j['status_akademik'] as String?) ?? 'Aktif',
      );

  /// Nama untuk sapaan: nama depan, atau bagian depan email kalau nama kosong.
  String get namaSapaan {
    final n = nama.trim();
    if (n.isNotEmpty) return n.split(' ').first;
    return email.split('@').first;
  }
}
