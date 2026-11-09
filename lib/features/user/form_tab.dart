import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';

class FormTab extends StatefulWidget {
  final String tkNumber;

  const FormTab({super.key, required this.tkNumber});

  @override
  State<FormTab> createState() => _FormTabState();
}

class _FormTabState extends State<FormTab> with AutomaticKeepAliveClientMixin {
  final _employeeNameController = TextEditingController();
  final _customPositionController = TextEditingController();
  final _dateController = TextEditingController();

  final _fruitsController = TextEditingController(text: '0');
  final _bakeryController = TextEditingController(text: '0');
  final _fatOilController = TextEditingController(text: '0');
  final _animalWasteController = TextEditingController(text: '0');
  final _commentController = TextEditingController();

  static const List<String> _positionsList = [
    'Оператор',
    'Специалист по учету',
    'Товаровед',
    'Директор ТК / Заместитель',
    'Кладовщик РЦ',
    'Начальник смены РЦ',
    'Другое (ввести вручную)',
  ];

  String _selectedPosition = 'Оператор';
  bool _arrived = true;
  bool _isSubmitting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd.MM.yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _customPositionController.dispose();
    _dateController.dispose();
    _fruitsController.dispose();
    _bakeryController.dispose();
    _fatOilController.dispose();
    _animalWasteController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double _parseWeight(String val) {
    if (val.trim().isEmpty) return 0.0;
    final normalized = val.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  Future<void> _submitReport() async {
    final name = _employeeNameController.text.trim();
    final pos = _selectedPosition == 'Другое (ввести вручную)'
        ? _customPositionController.text.trim()
        : _selectedPosition;
    final date = _dateController.text.trim();

    if (name.isEmpty || pos.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите ФИО, должность и дату отгрузки')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final status = _arrived
          ? 'Да, представитель приехал'
          : 'Нет, представитель не приехал';

      await Supabase.instance.client.from('reports').insert({
        'tk_number': widget.tkNumber,
        'employee_name': name,
        'position': pos,
        'shipment_date': date,
        'shipment_status': status,
        'fruits': _arrived ? _parseWeight(_fruitsController.text) : 0,
        'bakery': _arrived ? _parseWeight(_bakeryController.text) : 0,
        'fat_oil': _arrived ? _parseWeight(_fatOilController.text) : 0,
        'animal_waste':
            _arrived ? _parseWeight(_animalWasteController.text) : 0,
        'comment': _commentController.text.trim(),
      }).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      _showSuccessDialog();

      _fruitsController.text = '0';
      _bakeryController.text = '0';
      _fatOilController.text = '0';
      _animalWasteController.text = '0';
      _commentController.clear();
      _customPositionController.clear();
    } catch (e) {
      debugPrint('Submit report error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки отчета: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Отчет успешно принят!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Данные записаны в единый реестр компании.'),
            SizedBox(height: 12),
            Text(
              'Координатор: ${AppConstants.coordinatorName}\nТелефон: ${AppConstants.coordinatorPhone}',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Заполнить еще отчет',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.store, color: Color(0xFFE50914)),
                const SizedBox(width: 10),
                Text(
                  'Фиксация сдачи: ${widget.tkNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _employeeNameController,
            decoration: const InputDecoration(labelText: 'ФИО сотрудника *'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedPosition,
            decoration: const InputDecoration(labelText: 'Должность *'),
            dropdownColor: const Color(0xFF242424),
            items: _positionsList.map((pos) {
              return DropdownMenuItem(value: pos, child: Text(pos));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPosition = val);
            },
          ),
          if (_selectedPosition == 'Другое (ввести вручную)') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customPositionController,
              decoration: const InputDecoration(
                labelText: 'Укажите должность вручную *',
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: 'Дата отгрузки (ДД.ММ.ГГГГ) *',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Прибыл ли представитель перевозчика?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Да, представитель прибыл'),
              ),
              ButtonSegment(
                value: false,
                label: Text('Нет, перевозчик не приехал'),
              ),
            ],
            selected: {_arrived},
            onSelectionChanged: (set) => setState(() => _arrived = set.first),
          ),
          const SizedBox(height: 20),
          if (_arrived) ...[
            const Text(
              'Фактический вес (в килограммах):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _weightInput('Фрукты / овощи (кг)', _fruitsController),
            const SizedBox(height: 10),
            _weightInput(
              'Хлебобулочные / кондитерские (кг)',
              _bakeryController,
            ),
            const SizedBox(height: 10),
            _weightInput('Масложировая продукция (кг)', _fatOilController),
            const SizedBox(height: 10),
            _weightInput(
              'Отходы животного происхождения (ОЖП) (кг)',
              _animalWasteController,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Text(
                'Будет зафиксирован факт невывоза. Поля ввода веса отключены.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Примечание / комментарий к отгрузке',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              label: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Отправить отчет по смене',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Заменяем точку на запятую при вводе и не сбиваем позицию курсора
        TextInputFormatter.withFunction((oldValue, newValue) {
          final replaced = newValue.text.replaceAll('.', ',');
          return newValue.copyWith(
            text: replaced,
            selection: TextSelection.collapsed(
              offset: newValue.selection.baseOffset,
            ),
          );
        }),
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d*')),
      ],
      decoration: InputDecoration(labelText: label, suffixText: 'кг'),
    );
  }
}
