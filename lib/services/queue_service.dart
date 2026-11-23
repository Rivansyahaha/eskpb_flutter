import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account.dart';
import '../models/queue_status.dart';
import 'service_utils.dart';

class QueueService {
  /// Antrean aktif milikku, atau null kalau tidak ada.
  Future<QueueStatus?> statusSaya() async {
    final rows = await db.rpc('status_antrean_saya') as List;
    if (rows.isEmpty) return null;
    return QueueStatus.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  /// Ambil nomor antrean; mengembalikan nomor (mis. "A-040").
  Future<String> ambil(int kelasId) async {
    final row = await db.rpc('ambil_antrean', params: {'p_kelas_id': kelasId});
    return (row as Map)['nomor'] as String;
  }

  Future<CancelResult> batalkan(QueueStatus q) async {
    final row = await db.rpc('batalkan_antrean', params: {'p_antrean_id': q.antreanId})
        as Map;
    return CancelResult(
      nomor: row['nomor'] as String,
      judulKelas: q.judulKelas,
      dibatalkanAt: DateTime.tryParse('${row['dibatalkan_at'] ?? ''}'),
    );
  }

  Future<void> ubahPengajuan(int antreanId, int kelasBaruId) async {
    await db.rpc('ubah_pengajuan', params: {
      'p_antrean_id': antreanId,
      'p_kelas_baru_id': kelasBaruId,
    });
  }

  /// Notifikasi "giliran dekat" terbaru yang belum dibaca.
  Future<AppNotification?> giliranBelumDibaca() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await db
        .from('notifikasi')
        .select()
        .eq('profile_id', uid)
        .eq('tipe', 'giliran_dekat')
        .eq('dibaca', false)
        .order('created_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : AppNotification.fromJson(rows.first);
  }

  Future<void> tandaiDibaca(int notifId) async {
    await db.from('notifikasi').update({'dibaca': true}).eq('id', notifId);
  }

  /// Pantau perubahan tabel `antrean`.
  RealtimeChannel listenAntreanChanges(void Function() onChange) {
    return db
        .channel('antrean-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'antrean',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> removeChannel(RealtimeChannel c) => db.removeChannel(c);
}
