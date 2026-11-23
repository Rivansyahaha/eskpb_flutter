import '../models/home_data.dart';
import '../models/kelas.dart';
import '../models/profile.dart';
import '../services/kelas_service.dart';
import '../services/profile_service.dart';
import '../services/service_utils.dart';
import 'user_scoped_provider.dart';

class HomeProvider extends UserScopedProvider {
  HomeProvider(this._profileService, this._kelasService);

  final ProfileService _profileService;
  final KelasService _kelasService;

  bool _loading = false;
  bool _loaded = false;
  String? _error;
  HomeData? _data;

  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  HomeData? get data => _data;

  Future<void> load({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _profileService.fetchMyProfile(),
        _kelasService.activeSemester(),
        _kelasService.fetchMyKrs(),
      ]);
      _data = HomeData(
        profile: results[0] as Profile,
        semesterNama: (results[1] as Semester).nama,
        krs: results[2] as List<Kelas>,
      );
      _loaded = true;
    } catch (e) {
      _error = e is StateError
          ? 'Belum ada semester aktif.'
          : friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void resetState() {
    _loading = false;
    _loaded = false;
    _error = null;
    _data = null;
  }
}
