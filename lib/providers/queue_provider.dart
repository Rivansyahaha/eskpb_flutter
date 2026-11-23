import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account.dart';
import '../models/queue_status.dart';
import '../services/queue_service.dart';
import '../services/service_utils.dart';
import 'user_scoped_provider.dart';

/// Antrean aktif milik pengguna (RPC status_antrean_saya) + realtime.
class QueueProvider extends UserScopedProvider {
  QueueProvider(this._service);

  final QueueService _service;

  bool _loading = false;
  bool _loaded = false;
  String? _error;
  QueueStatus? _status;
  AppNotification? _giliran;
  String? _flash;
  DateTime? _updatedAt;

  RealtimeChannel? _channel;
  Timer? _debounce;

  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  QueueStatus? get status => _status;
  bool get hasActive => _status != null;

  /// Notifikasi "giliran dekat" yang belum dibaca (layar 13).
  AppNotification? get giliran => _giliran;

  /// Pesan singkat sekali tampil (mis. "Pengajuan berhasil diperbarui").
  String? get flash => _flash;

  /// Kapan data antrean terakhir berhasil dimuat.
  DateTime? get updatedAt => _updatedAt;

  Future<void> load({bool force = false, bool silent = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    _error = null;
    if (!silent) notifyListeners();
    try {
      _status = await _service.statusSaya();
      _giliran = _status == null ? null : await _safeGiliran();
      _loaded = true;
      _updatedAt = DateTime.now();
      _startRealtime();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AppNotification?> _safeGiliran() async {
    try {
      return await _service.giliranBelumDibaca();
    } catch (_) {
      return null;
    }
  }

  /// Batalkan antrean aktif. Melempar error apa adanya (ditangani layar).
  Future<CancelResult> cancel() async {
    final q = _status;
    if (q == null) throw StateError('Tidak ada antrean aktif');
    final result = await _service.batalkan(q);
    await load(force: true);
    return result;
  }

  /// Ganti kelas pengajuan tanpa mengubah nomor antrean.
  Future<void> changeClass(int kelasBaruId) async {
    final q = _status;
    if (q == null) throw StateError('Tidak ada antrean aktif');
    await _service.ubahPengajuan(q.antreanId, kelasBaruId);
    _flash = 'Pengajuan berhasil diperbarui';
    await load(force: true);
  }

  Future<void> markGiliranRead() async {
    final n = _giliran;
    if (n == null) return;
    _giliran = null;
    notifyListeners();
    try {
      await _service.tandaiDibaca(n.id);
    } catch (_) {}
  }

  String? takeFlash() {
    final f = _flash;
    _flash = null;
    return f;
  }

  void _startRealtime() {
    if (_channel != null) return;
    try {
      _channel = _service.listenAntreanChanges(() {
        _debounce?.cancel();
        _debounce = Timer(
          const Duration(milliseconds: 400),
          () => load(force: true, silent: true),
        );
      });
    } catch (_) {
      // Realtime opsional; tombol "Perbarui Status" tetap bisa dipakai.
    }
  }

  void _stopRealtime() {
    _debounce?.cancel();
    final c = _channel;
    _channel = null;
    if (c != null) {
      unawaited(_service.removeChannel(c).catchError((_) => 'ok'));
    }
  }

  @override
  void resetState() {
    _stopRealtime();
    _loading = false;
    _loaded = false;
    _error = null;
    _status = null;
    _giliran = null;
    _flash = null;
    _updatedAt = null;
  }

  @override
  void dispose() {
    _stopRealtime();
    super.dispose();
  }
}
