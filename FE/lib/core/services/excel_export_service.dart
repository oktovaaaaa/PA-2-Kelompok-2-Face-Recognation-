import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExcelExportService {
  static Future<String> exportAttendance(List<dynamic> records, String fileName) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    // Header styling
    final CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2563EB'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Headers
    List<CellValue> headers = [
      TextCellValue('No'),
      TextCellValue('Nama Karyawan'),
      TextCellValue('Tanggal'),
      TextCellValue('Jam Masuk'),
      TextCellValue('Jam Keluar'),
      TextCellValue('Status'),
    ];
    sheet.appendRow(headers);

    // Apply header style
    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Write Data
    for (var i = 0; i < records.length; i++) {
      final r = records[i] as Map<String, dynamic>;
      
      String checkIn = '-';
      if (r['check_in_time'] != null && r['check_in_time'].toString().length >= 16) {
        checkIn = r['check_in_time'].toString().substring(11, 16);
      }

      String checkOut = '-';
      if (r['check_out_time'] != null && r['check_out_time'].toString().length >= 16) {
        checkOut = r['check_out_time'].toString().substring(11, 16);
      }

      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(r['user_name'] ?? r['name'] ?? '-'),
        TextCellValue(r['date'] ?? '-'),
        TextCellValue(checkIn),
        TextCellValue(checkOut),
        TextCellValue(r['status'] ?? '-'),
      ]);
    }

    // Set Column Widths
    sheet.setColumnWidth(1, 30.0); // Nama
    sheet.setColumnWidth(2, 20.0); // Tanggal
    sheet.setColumnWidth(3, 15.0); // Masuk
    sheet.setColumnWidth(4, 15.0); // Keluar

    // Save File
    final fileBytes = excel.save();
    
    // Find most accessible directory
    Directory? directory;
    if (Platform.isAndroid) {
      // Try public Download folder first
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to internal storage if Download folder is not accessible
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    final filePath = '${directory!.path}/$fileName.xlsx';
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(fileBytes!);

    // Open File
    try {
      await OpenFilex.open(filePath);
    } catch (_) {
      // Ignore open error on some platforms
    }
    
    return filePath;
  }
}
