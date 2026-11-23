import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

SupabaseClient get db => Supabase.instance.client;

/// Ubah error apa pun menjadi pesan ramah berbahasa Indonesia.
String friendlyError(Object e) {
  if (e is AuthFailure) return e.message;
  if (e is PostgrestException) {
    // RAISE EXCEPTION di fungsi RPC (kode P0001) sudah berisi pesan Indonesia.
    if (e.code == 'P0001' && e.message.isNotEmpty) {
      if (e.message == 'Belum login') {
        return 'Sesi berakhir. Silakan masuk lagi.';
      }
      return e.message;
    }
    if (e.code == 'PGRST301' || e.code == '401') {
      return 'Sesi berakhir. Silakan masuk lagi.';
    }
    if (e.code == '42501') {
      return 'Kamu tidak punya akses ke data ini.';
    }
    return 'Terjadi kesalahan pada server. Coba lagi sebentar.';
  }
  if (e is AuthException) return 'Sesi berakhir. Silakan masuk lagi.';
  return 'Tidak dapat terhubung ke server. Periksa koneksi internetmu.';
}
