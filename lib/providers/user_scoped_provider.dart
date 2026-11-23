import 'package:flutter/foundation.dart';

/// Provider berisi data milik satu pengguna. Saat pengguna berganti (login atau
/// logout), data lama dibuang tanpa memanggil notifyListeners (aman dipanggil
/// dari fase build).
abstract class UserScopedProvider extends ChangeNotifier {
  String? _userId;

  void bindUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    resetState();
  }

  @protected
  void resetState();
}
