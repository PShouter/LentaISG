import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'types.dart';

class ExcelService {
  static void exportReports(JsonList reports) {
    final excel = Excel.createExcel();
    final sheet = excel['Отчеты ИСГ'];
    excel.delete('Sheet1');

    final headers = [
      'Дата записи',
      'Объект (ТК/РЦ)',
      'ФИО сотрудника',
      'Должность',
      'Дата отгрузки',
      'Статус приезда',
      'Фрукты/овощи (кг)',
      'Хлеб/кондит. (кг)',
      'Масложировая (кг)',
      'ОЖП (кг)',
      'Примечание',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (final r in reports) {
      sheet.appendRow([
        TextCellValue(r['created_at']?.toString() ?? ''),
        TextCellValue(r['tk_number']?.toString() ?? ''),
        TextCellValue(r['employee_name']?.toString() ?? ''),
        TextCellValue(r['position']?.toString() ?? ''),
        TextCellValue(r['shipment_date']?.toString() ?? ''),
        TextCellValue(r['shipment_status']?.toString() ?? ''),
        TextCellValue(r['fruits']?.toString() ?? '0'),
        TextCellValue(r['bakery']?.toString() ?? '0'),
        TextCellValue(r['fat_oil']?.toString() ?? '0'),
        TextCellValue(r['animal_waste']?.toString() ?? '0'),
        TextCellValue(r['comment']?.toString() ?? ''),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null && kIsWeb) {
      final base64String = base64Encode(fileBytes);
      final anchor = html.AnchorElement(
        href:
            'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64String',
      )
        ..setAttribute('download',
            'Отчеты_ИСГ_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
    }
  }
}
