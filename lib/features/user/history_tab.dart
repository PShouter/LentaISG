import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/types.dart';

class HistoryTab extends StatefulWidget {
  final String tkNumber;

  const HistoryTab({super.key, required this.tkNumber});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  JsonList _reports = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('tk_number', widget.tkNumber)
          .order('created_at', ascending: false)
          .limit(40)
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;
      setState(() {
        _reports = (res as List).cast<JsonMap>();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    if (_reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Отчетов по вашему объекту пока нет',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFFE50914),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _reports[index];
          final isNotArrived =
              item['shipment_status'] == 'Нет, представитель не приехал';
          final created =
              DateTime.tryParse(item['created_at']?.toString() ?? '');

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Дата отгрузки: ${item['shipment_date']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      created != null
                          ? DateFormat('dd.MM.yyyy HH:mm')
                              .format(created.toLocal())
                          : '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Сдал: ${item['employee_name']} (${item['position']})',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  item['shipment_status'] ?? '',
                  style: TextStyle(
                    color: isNotArrived ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isNotArrived) ...[
                  const Divider(height: 16, color: Colors.white10),
                  Text(
                    'Фрукты: ${item['fruits']} кг | Хлеб: ${item['bakery']} кг | Масло: ${item['fat_oil']} кг | ОЖП: ${item['animal_waste']} кг',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
