import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExcelExportService {
  static Future<String> exportAttendance(List<dynamic> records, String fileName, {Map<String, int>? stats, String? periodLabel}) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    // 1. Definisikan Style
    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#2563EB'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final dataStyle = CellStyle(
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Set Column Widths
    sheet.setColumnWidth(0, 6.0);  // No
    sheet.setColumnWidth(1, 30.0); // Nama Karyawan
    sheet.setColumnWidth(2, 18.0); // Tanggal
    sheet.setColumnWidth(3, 12.0); // Masuk
    sheet.setColumnWidth(4, 12.0); // Keluar
    sheet.setColumnWidth(5, 20.0); // Status

    int currentRow = 0;

    // 2. Judul & Ringkasan Dashboard
    var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    titleCell.value = TextCellValue("LAPORAN KEHADIRAN KARYAWAN");
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 16, fontColorHex: ExcelColor.fromHexString('#1E3A8A'));
    currentRow++;

    var periodCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    periodCell.value = TextCellValue("Periode: ${periodLabel ?? 'Semua Waktu'}");
    periodCell.cellStyle = CellStyle(italic: true, fontColorHex: ExcelColor.fromHexString('#64748B'));
    currentRow += 2;

    if (stats != null) {
      var summaryHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      summaryHeader.value = TextCellValue("DASHBOARD VISUALISASI KEHADIRAN (GRAFIK)");
      summaryHeader.cellStyle = CellStyle(bold: true, fontSize: 14, backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'));
      currentRow += 2;

      // Hitung total untuk persentase grafik
      int totalForChart = 0;
      stats.forEach((k, v) => totalForChart += v);
      if (totalForChart == 0) totalForChart = 1;

      final summaryKeys = {
        'PRESENT': {'label': 'Hadir Tepat Waktu', 'color': '#22C55E'},
        'LATE': {'label': 'Terlambat', 'color': '#F59E0B'},
        'ABSENT': {'label': 'Alpha', 'color': '#EF4444'},
        'WORKING': {'label': 'Sedang Bekerja', 'color': '#818CF8'},
        'NOT_YET': {'label': 'Belum Hadir', 'color': '#94A3B8'},
        'EARLY_LEAVE': {'label': 'Pulang di Jam Kerja', 'color': '#8B5CF6'},
      };

      summaryKeys.forEach((key, data) {
        final label = data['label'] as String;
        final color = data['color'] as String;
        final count = stats[key] ?? 0;
        final percent = (count / totalForChart * 100).toStringAsFixed(0);

        // 1. Label Status & Angka
        var lCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        lCell.value = TextCellValue("$label ($count)");
        lCell.cellStyle = CellStyle(fontColorHex: ExcelColor.fromHexString(color), bold: true);

        // 2. Bar Chart Berskala (Lebar 20 Kolom)
        double scaleWidth = (count / totalForChart) * 20;
        int barCols = scaleWidth.round();
        if (count > 0 && barCols == 0) barCols = 1; // Minimal 1 kotak jika ada data

        for (int b = 0; b < 20; b++) {
          var barCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + b, rowIndex: currentRow));
          if (b < barCols) {
            barCell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString(color));
            if (b == barCols - 1) {
              barCell.value = TextCellValue(" $percent%");
            }
          } else {
            barCell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'));
          }
        }
        currentRow++;
      });
      currentRow += 3;
    }

    // 3. Tabel Data Detail
    final headers = ["No", "Nama Karyawan", "Tanggal", "Masuk", "Keluar", "Status"];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    currentRow++;

    // Isi Data
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      
      String checkIn = '-';
      if (r['check_in_time'] != null && r['check_in_time'].toString().length >= 16) {
        checkIn = r['check_in_time'].toString().substring(11, 16);
      }
      
      String checkOut = '-';
      if (r['check_out_time'] != null && r['check_out_time'].toString().length >= 16) {
        checkOut = r['check_out_time'].toString().substring(11, 16);
      }

      // Format Tanggal: Rabu, 1 April 2026
      String formattedDate = r['date'] ?? '-';
      try {
        if (formattedDate != '-') {
          DateTime dt = DateTime.parse(formattedDate);
          formattedDate = _formatFullDate(dt);
        }
      } catch (_) {}

      final rowValues = [
        IntCellValue(i + 1),
        TextCellValue(r['user_name'] ?? '-'),
        TextCellValue(formattedDate),
        TextCellValue(checkIn),
        TextCellValue(checkOut),
        TextCellValue(_translateStatus(r['status']?.toString() ?? '-')),
      ];

      for (int j = 0; j < rowValues.length; j++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow));
        cell.value = rowValues[j];
        cell.cellStyle = dataStyle;
      }
      currentRow++;
    }

    // 4. Simpan File
    final fileBytes = excel.save();
    Directory? directory;
    
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    final finalPath = '${directory!.path}/$fileName.xlsx';
    final file = File(finalPath);
    await file.create(recursive: true);
    await file.writeAsBytes(fileBytes!);

    return finalPath;
  }

  static String _translateStatus(String status) {
    switch (status) {
      case 'PRESENT': return 'Hadir Tepat Waktu';
      case 'LATE': return 'Terlambat';
      case 'ABSENT': return 'Alpha';
      case 'WORKING': return 'Sedang Bekerja';
      case 'NOT_YET': return 'Belum Hadir';
      case 'EARLY_LEAVE': return 'Pulang di Jam Kerja';
      case 'LEAVE': return 'Izin';
      case 'SICK': return 'Sakit';
      default: return status;
    }
  }

  static String _formatFullDate(DateTime date) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
