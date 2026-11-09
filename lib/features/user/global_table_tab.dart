import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/excel_service.dart';
import '../../core/types.dart';

class GlobalTableTab extends StatefulWidget {
  final String tkNumber;

  const GlobalTableTab({super.key, required this.tkNumber});

  @override
  State<GlobalTableTab> createState() => _GlobalTableTabState();
}

class _GlobalTableTabState extends State<GlobalTableTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _hasAccess = false;
  DateTime? _accessUntil;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;

  JsonList _allReports = [];
  String _filter = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAccessAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final accountRes = await Supabase.instance.client
          .from('tk_accounts')
          .select('table_access_until')
          .eq('tk_number', widget.tkNumber)
          .single()
          .timeout(const Duration(seconds: 4));

      final untilStr = accountRes['table_access_until']?.toString();
      DateTime? until = untilStr != null ? DateTime.tryParse(untilStr) : null;

      if (until != null && until.isAfter(DateTime.now())) {
        _hasAccess = true;
        _accessUntil = until;
        _startTimer();

        final reportsRes = await Supabase.instance.client
            .from('reports')
            .select()
            .order('created_at', ascending: false)
            .limit(300)
            .timeout(const Duration(seconds: 5));

        _allReports = (reportsRes as List).cast<JsonMap>();
      } else {
        _hasAccess = false;
        _countdownTimer?.cancel();
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_accessUntil == null) return;
      final diff = _accessUntil!.difference(DateTime.now());
      if (diff.isNegative) {
        timer.cancel();
        if (mounted) setState(() => _hasAccess = false);
      } else {
        if (mounted) setState(() => _remaining = diff);
      }
    });
  }

  Future<void> _requestAccess() async {
    try {
      await Supabase.instance.client.from('access_requests').insert({
        'tk_number': widget.tkNumber,
        'status': 'pending',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запрос на доступ на 24 часа отправлен координатору!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки запроса: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    if (!_hasAccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_outlined,
                  size: 64, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              const Text(
                'Сводная таблица сети защищена',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Просмотр всей сети доступен только по разовому согласованию с координатором.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: _requestAccess,
                label: const Text('Запросить доступ на 24 часа'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _checkAccessAndLoad,
                child: const Text('Проверить статус одобрения',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _allReports.where((r) {
      if (_filter.isEmpty) return true;
      return r['tk_number']
          .toString()
          .toLowerCase()
          .contains(_filter.toLowerCase());
    }).toList();

    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E281E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Доступ активен еще: $hours:$minutes:$seconds',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700]),
                onPressed: () => ExcelService.exportReports(filtered),
                label: const Text('Выгрузить в Excel'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Поиск по номеру ТК или РЦ...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) => setState(() => _filter = val.trim()),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFF242424)),
                columns: const [
                  DataColumn(label: Text('Объект')),
                  DataColumn(label: Text('Дата отгрузки')),
                  DataColumn(label: Text('Статус')),
                  DataColumn(label: Text('Фрукты')),
                  DataColumn(label: Text('Хлеб')),
                  DataColumn(label: Text('Масложир')),
                  DataColumn(label: Text('ОЖП')),
                ],
                rows: filtered.map((r) {
                  return DataRow(cells: [
                    DataCell(Text(r['tk_number'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(r['shipment_date'] ?? '')),
                    DataCell(Text(r['shipment_status'] ?? '',
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${r['fruits'] ?? 0} кг')),
                    DataCell(Text('${r['bakery'] ?? 0} кг')),
                    DataCell(Text('${r['fat_oil'] ?? 0} кг')),
                    DataCell(Text('${r['animal_waste'] ?? 0} кг')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
