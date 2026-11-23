import '../models/account.dart';
import '../models/profile.dart';
import 'service_utils.dart';

class ProfileService {
  Future<Profile> fetchMyProfile() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) throw StateError('Belum login');
    final row = await db
        .from('profiles')
        .select('id, nama, nrp, email, no_telp, ip_semester, batas_sks, status_akademik, program_studi_id, program_studi(nama)')
        .eq('id', uid)
        .single();
    return Profile.fromJson(row);
  }

  Future<List<ProgramStudi>> fetchProgramStudi() async {
    final rows = await db.from('program_studi').select().order('nama');
    return rows.map(ProgramStudi.fromJson).toList();
  }

  /// Hanya nama, no_telp, dan program studi yang boleh diubah (dijaga RLS).
  Future<void> updateProfile({
    required String nama,
    required String? noTelp,
    required int? programStudiId,
  }) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) throw StateError('Belum login');
    await db.from('profiles').update({
      'nama': nama,
      'no_telp': noTelp,
      'program_studi_id': programStudiId,
    }).eq('id', uid);
  }
}
