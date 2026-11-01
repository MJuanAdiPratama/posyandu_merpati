import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../models/balita_model.dart';
import '../models/imunisasi_model.dart';
import '../models/jadwal_imunisasi_model.dart';
import '../models/pertumbuhan_model.dart';

class LaporanRepository {
  Future<File> eksporBalitaPDF(List<BalitaModel> daftar) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Data Balita - Posyandu Merpati',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tanggal: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['No', 'Nama', 'NIK', 'Tgl Lahir', 'JK', 'Status'],
            data: daftar.asMap().entries.map((e) {
              final b = e.value;
              return [
                '${e.key + 1}',
                b.nama,
                b.nik,
                dateFormat.format(b.tanggalLahir),
                b.jenisKelamin,
                b.statusVerifikasi,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ),
    );

    return _simpanPDF(pdf, 'laporan_balita');
  }

  Future<File> eksporImunisasiPDF(List<ImunisasiModel> daftar) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Imunisasi - Posyandu Merpati',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tanggal: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['No', 'Balita', 'Imunisasi', 'Tgl', 'BB (kg)', 'TB (cm)'],
            data: daftar.asMap().entries.map((e) {
              final i = e.value;
              return [
                '${e.key + 1}',
                i.namaBalita ?? '-',
                i.namaImunisasi ?? '-',
                dateFormat.format(i.tanggalImunisasi),
                i.beratBadan?.toString() ?? '-',
                i.tinggiBadan?.toString() ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ),
    );

    return _simpanPDF(pdf, 'laporan_imunisasi');
  }

  Future<File> eksporPertumbuhanPDF(
    List<PertumbuhanModel> daftar,
    String namaBalita,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Pertumbuhan - $namaBalita',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Tanggal',
              'Usia',
              'BB (kg)',
              'TB (cm)',
              'Status Gizi',
            ],
            data: daftar.asMap().entries.map((e) {
              final p = e.value;
              return [
                '${e.key + 1}',
                dateFormat.format(p.tanggalPemeriksaan),
                '${p.usiaBulan} bln',
                p.beratBadan.toString(),
                p.tinggiBadan.toString(),
                p.statusGizi ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ),
    );

    return _simpanPDF(pdf, 'laporan_pertumbuhan_$namaBalita');
  }

  Future<File> eksporBalitaExcel(List<BalitaModel> daftar) async {
    final excel = Excel.createExcel();
    final sheet = excel['Balita'];

    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Nama'),
      TextCellValue('NIK'),
      TextCellValue('Tgl Lahir'),
      TextCellValue('Jenis Kelamin'),
      TextCellValue('Nama Ortu'),
      TextCellValue('Status'),
    ]);

    for (var i = 0; i < daftar.length; i++) {
      final b = daftar[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(b.nama),
        TextCellValue(b.nik),
        TextCellValue(
          '${b.tanggalLahir.day}/${b.tanggalLahir.month}/${b.tanggalLahir.year}',
        ),
        TextCellValue(b.jenisKelamin),
        TextCellValue(b.namaOrtu),
        TextCellValue(b.statusVerifikasi),
      ]);
    }

    return _simpanExcel(excel, 'laporan_balita');
  }

  Future<File> eksporImunisasiExcel(List<ImunisasiModel> daftar) async {
    final excel = Excel.createExcel();
    final sheet = excel['Imunisasi'];

    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Balita'),
      TextCellValue('Imunisasi'),
      TextCellValue('Tanggal'),
      TextCellValue('BB (kg)'),
      TextCellValue('TB (cm)'),
    ]);

    for (var i = 0; i < daftar.length; i++) {
      final item = daftar[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item.namaBalita ?? '-'),
        TextCellValue(item.namaImunisasi ?? '-'),
        TextCellValue(
          '${item.tanggalImunisasi.day}/${item.tanggalImunisasi.month}/${item.tanggalImunisasi.year}',
        ),
        item.beratBadan != null
            ? DoubleCellValue(item.beratBadan!)
            : TextCellValue('-'),
        item.tinggiBadan != null
            ? DoubleCellValue(item.tinggiBadan!)
            : TextCellValue('-'),
      ]);
    }

    return _simpanExcel(excel, 'laporan_imunisasi');
  }

  Future<File> eksporPertumbuhanExcel(
    List<PertumbuhanModel> daftar,
    String namaBalita,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Pertumbuhan'];

    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Tanggal'),
      TextCellValue('Usia (bln)'),
      TextCellValue('BB (kg)'),
      TextCellValue('TB (cm)'),
      TextCellValue('Status Gizi'),
    ]);

    for (var i = 0; i < daftar.length; i++) {
      final p = daftar[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(
          '${p.tanggalPemeriksaan.day}/${p.tanggalPemeriksaan.month}/${p.tanggalPemeriksaan.year}',
        ),
        IntCellValue(p.usiaBulan),
        DoubleCellValue(p.beratBadan),
        DoubleCellValue(p.tinggiBadan),
        TextCellValue(p.statusGizi ?? '-'),
      ]);
    }

    return _simpanExcel(excel, 'laporan_pertumbuhan_$namaBalita');
  }

  Future<File> eksporJadwalImunisasiPDF(
    List<JadwalImunisasiModel> daftar,
    String namaBalita,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Jadwal Imunisasi - $namaBalita',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tanggal: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['No', 'Imunisasi', 'Usia (bln)', 'Tanggal', 'Status'],
            data: daftar.asMap().entries.map((e) {
              final j = e.value;
              return [
                '${e.key + 1}',
                j.namaImunisasi ?? '-',
                '${j.usiaBulanImunisasi ?? '-'}',
                dateFormat.format(j.tanggalJadwal),
                j.status,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ),
    );

    return _simpanPDF(pdf, 'laporan_jadwal_imunisasi_$namaBalita');
  }

  Future<File> eksporJadwalImunisasiExcel(
    List<JadwalImunisasiModel> daftar,
    String namaBalita,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Jadwal Imunisasi'];

    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Imunisasi'),
      TextCellValue('Usia (bln)'),
      TextCellValue('Tanggal Jadwal'),
      TextCellValue('Status'),
    ]);

    for (var i = 0; i < daftar.length; i++) {
      final j = daftar[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(j.namaImunisasi ?? '-'),
        j.usiaBulanImunisasi != null
            ? IntCellValue(j.usiaBulanImunisasi!)
            : TextCellValue('-'),
        TextCellValue(
          '${j.tanggalJadwal.day}/${j.tanggalJadwal.month}/${j.tanggalJadwal.year}',
        ),
        TextCellValue(j.status),
      ]);
    }

    return _simpanExcel(excel, 'laporan_jadwal_imunisasi_$namaBalita');
  }

  Future<File> _simpanPDF(pw.Document pdf, String namaFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/${namaFile}_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> _simpanExcel(Excel excel, String namaFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/${namaFile}_$timestamp.xlsx');
    final bytes = excel.save();
    if (bytes == null) throw Exception('Gagal generate Excel');
    await file.writeAsBytes(bytes);
    return file;
  }
}
