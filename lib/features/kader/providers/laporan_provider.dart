import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/pertumbuhan_model.dart';
import '../../../data/repositories/balita_repository.dart';
import '../../../data/repositories/imunisasi_repository.dart';
import '../../../data/repositories/jadwal_imunisasi_repository.dart';
import '../../../data/repositories/laporan_repository.dart';
import '../../../data/repositories/pertumbuhan_repository.dart';

class LaporanProvider extends ChangeNotifier {
  final _balitaRepo = BalitaRepository();
  final _imunisasiRepo = ImunisasiRepository();
  final _pertumbuhanRepo = PertumbuhanRepository();
  final _jadwalImunisasiRepo = JadwalImunisasiRepository();
  final _laporanRepo = LaporanRepository();

  bool _isLoading = false;
  String? _error;
  File? _fileTerakhir;

  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get fileTerakhir => _fileTerakhir;

  Future<File?> eksporBalitaPDF() async {
    _setLoading(true);
    try {
      final daftar = await _balitaRepo.getDaftarBalita();
      _fileTerakhir = await _laporanRepo.eksporBalitaPDF(daftar);
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporImunisasiPDF([DateTime? bulan]) async {
    _setLoading(true);
    try {
      final daftar = await _imunisasiRepo.getBulanIni(bulan);
      _fileTerakhir = await _laporanRepo.eksporImunisasiPDF(daftar);
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporPertumbuhanPDF(
    List<PertumbuhanModel> daftar,
    String namaBalita,
  ) async {
    _setLoading(true);
    try {
      _fileTerakhir = await _laporanRepo.eksporPertumbuhanPDF(
        daftar,
        namaBalita,
      );
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporBalitaExcel() async {
    _setLoading(true);
    try {
      final daftar = await _balitaRepo.getDaftarBalita();
      _fileTerakhir = await _laporanRepo.eksporBalitaExcel(daftar);
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporImunisasiExcel([DateTime? bulan]) async {
    _setLoading(true);
    try {
      final daftar = await _imunisasiRepo.getBulanIni(bulan);
      _fileTerakhir = await _laporanRepo.eksporImunisasiExcel(daftar);
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporPertumbuhanPDFByBalita(
    String balitaId,
    String namaBalita,
  ) async {
    _setLoading(true);
    try {
      final daftar = await _pertumbuhanRepo.getByBalita(balitaId);
      _fileTerakhir = await _laporanRepo.eksporPertumbuhanPDF(
        daftar,
        namaBalita,
      );
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporPertumbuhanExcelByBalita(
    String balitaId,
    String namaBalita,
  ) async {
    _setLoading(true);
    try {
      final daftar = await _pertumbuhanRepo.getByBalita(balitaId);
      _fileTerakhir = await _laporanRepo.eksporPertumbuhanExcel(
        daftar,
        namaBalita,
      );
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporJadwalImunisasiPDFByBalita(
    String balitaId,
    String namaBalita,
  ) async {
    _setLoading(true);
    try {
      final daftar = await _jadwalImunisasiRepo.getByBalita(balitaId);
      _fileTerakhir = await _laporanRepo.eksporJadwalImunisasiPDF(
        daftar,
        namaBalita,
      );
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> eksporJadwalImunisasiExcelByBalita(
    String balitaId,
    String namaBalita,
  ) async {
    _setLoading(true);
    try {
      final daftar = await _jadwalImunisasiRepo.getByBalita(balitaId);
      _fileTerakhir = await _laporanRepo.eksporJadwalImunisasiExcel(
        daftar,
        namaBalita,
      );
      _error = null;
      return _fileTerakhir;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
