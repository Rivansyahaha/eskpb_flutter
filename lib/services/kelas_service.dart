import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kelas.dart';
import 'service_utils.dart';

class Semester {
  const Semester(this.id, this.nama);
  final int id;
  final String nama;
}

/// Data kelas dari view `v_kelas` dan KRS milik pengguna.
class KelasService {
  Semester? _semester;

  Future<Semester> activeSemester() async {
    final cached = _semester;
    if (cached != null) return cached;
    final row = await db
        .from('semester')
        .select('id, nama')
        .eq('is_aktif', true)
        .maybeSingle();
    if (row == null) {
      throw StateError('Belum ada semester aktif');
    }
    return _semester = Semester((row['id'] as num).toInt(), row['nama'] as String);
  }

  Future<List<Kelas>> fetchKelas() async {
    final sem = await activeSemester();
    final rows = await db
        .from('v_kelas')
        .select()
        .eq('semester_id', sem.id)
        .order('nama_mk')
        .order('nomor');
    return rows.map(Kelas.fromJson).toList();
  }

  Future<Kelas> fetchById(int id) async {
    final row = await db.from('v_kelas').select().eq('id', id).single();
    return Kelas.fromJson(row);
  }

  /// Kelas di KRS semester aktif milik pengguna.
  Future<List<Kelas>> fetchMyKrs() async {
    final sem = await activeSemester();
    final uid = db.auth.currentUser?.id;
    if (uid == null) return [];
    final krs = await db.from('krs').select('kelas_id').eq('profile_id', uid);
    final ids = krs.map((r) => (r['kelas_id'] as num).toInt()).toList();
    if (ids.isEmpty) return [];
    final rows = await db
        .from('v_kelas')
        .select()
        .inFilter('id', ids)
        .eq('semester_id', sem.id);
    return rows.map(Kelas.fromJson).toList();
  }

  /// Kelas lain dari mata kuliah yang sama yang masih ada kursi dan tidak
  /// bentrok dengan KRS pengguna.
  Future<List<Kelas>> fetchAlternatives(Kelas kelas) async {
    final rows = await db
        .from('v_kelas')
        .select()
        .eq('mk_id', kelas.mkId)
        .eq('semester_id', kelas.semesterId)
        .neq('id', kelas.id)
        .neq('status_kuota', 'penuh')
        .order('sisa_kursi', ascending: false);
    final kandidat = rows.map(Kelas.fromJson);
    final krs = await fetchMyKrs();
    return kandidat.where((c) => !krs.any(c.bentrokDengan)).toList();
  }

  /// Kelas pengganti untuk Ubah Pengajuan: mata kuliah lain, belum penuh.
  Future<List<Kelas>> fetchReplacements(Kelas current) async {
    final rows = await db
        .from('v_kelas')
        .select()
        .eq('semester_id', current.semesterId)
        .neq('mk_id', current.mkId)
        .neq('status_kuota', 'penuh')
        .order('nama_mk')
        .order('nomor');
    return rows.map(Kelas.fromJson).toList();
  }

  /// Pantau perubahan tabel `kelas`. Panggil `removeChannel` saat selesai.
  RealtimeChannel listenKelasChanges(void Function() onChange) {
    return db
        .channel('kelas-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kelas',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> removeChannel(RealtimeChannel channel) =>
      db.removeChannel(channel);
}
