import 'package:flutter/material.dart';
import '../../../data/models/pertumbuhan_model.dart';
import '../../../data/repositories/pertumbuhan_repository.dart';

class PertumbuhanProvider extends ChangeNotifier {
  final _repo = PertumbuhanRepository();

  List<PertumbuhanModel> _daftar = [];
  bool _isLoading = false;
  String? _subscribedBalitaId;
  String? _error;

  List<PertumbuhanModel> get daftar => _daftar;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PertumbuhanModel? get terakhir => _daftar.isNotEmpty ? _daftar.last : null;

  Future<void> muatByBalita(String balitaId) async {
    _setLoading(true);
    try {
      _daftar = await _repo.getByBalita(balitaId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    if (_subscribedBalitaId != balitaId) {
      _subscribedBalitaId = balitaId;
      _repo.subscribeRealtime(balitaId, () => muatByBalita(balitaId));
    }
  }

  void reset() {
    _repo.unsubscribeRealtime();
    _daftar = [];
    _isLoading = false;
    _subscribedBalitaId = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repo.unsubscribeRealtime();
    super.dispose();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
