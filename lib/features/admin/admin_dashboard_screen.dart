import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/excel_service.dart';
import '../../core/session_service.dart';
import '../../core/types.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isExporting = false;

  JsonList _reports = [];
  JsonList _requests = [];
  JsonList _tickets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    // Запускаем независимые быстрые запросы
    await Future.wait([
      _fetchReports(),
      _fetchRequests(),
      _fetchTickets(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReports() async {
    try {
      final res = await Supabase.instance.client
          .from('reports')
          .select()
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        setState(() => _reports = (res as List).cast<JsonMap>());
      }
    } catch (e) {
      debugPrint('Fetch reports error: $e');
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final res = await Supabase.instance.client
          .from('access_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        setState(() => _requests = (res as List).cast<JsonMap>());
      }
    } catch (e) {
      debugPrint('Fetch requests error: $e');
    }
  }

  Future<void> _fetchTickets() async {
    try {
      final res = await Supabase.instance.client
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        setState(() => _tickets = (res as List).cast<JsonMap>());
      }
    } catch (e) {
      debugPrint('Fetch tickets error: $e');
    }
  }

  Future<void> _downloadFullExcel() async {
    setState(() => _isExporting = true);
    try {
      final res = await Supabase.instance.client
          .from('reports')
          .select()
          .order('created_at', ascending: false)
          .limit(5000);

      final fullData = (res as List).cast<JsonMap>();
      ExcelService.exportReports(fullData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выгрузки: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _approveAccess(String requestId) async {
    try {
      await Supabase.instance.client
          .rpc('approve_tk_access', params: {'target_request_id': requestId});
      _fetchRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Доступ успешно одобрен на 24 часа!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка одобрения: $e')));
    }
  }

  void _logout() async {
    await SessionService.clearSession();
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель координатора'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить данные',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE50914),
          tabs: [
            Tab(text: 'Отчеты (${_reports.length})'),
            Tab(text: 'Заявки 24ч (${_requests.length})'),
            Tab(text: 'Тикеты (${_tickets.length})'),
          ],
        ),
      ),
      body: _isLoading &&
              _reports.isEmpty &&
              _requests.isEmpty &&
              _tickets.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsView(),
                _buildRequestsView(),
                _buildTicketsView(),
              ],
            ),
    );
  }

  Widget _buildReportsView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Записей в реестре: ${_reports.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              ElevatedButton.icon(
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: _isExporting ? null : _downloadFullExcel,
                label: const Text('Выгрузить ВСЕ в Excel (.xlsx)'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _reports.isEmpty
              ? const Center(
                  child: Text('Отчетов пока нет',
                      style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFF242424)),
                      columns: const [
                        DataColumn(label: Text('Объект')),
                        DataColumn(label: Text('Дата отгрузки')),
                        DataColumn(label: Text('Сотрудник')),
                        DataColumn(label: Text('Должность')),
                        DataColumn(label: Text('Статус')),
                        DataColumn(label: Text('Фрукты')),
                        DataColumn(label: Text('Хлеб')),
                        DataColumn(label: Text('Масло')),
                        DataColumn(label: Text('ОЖП')),
                        DataColumn(label: Text('Примечание')),
                      ],
                      rows: _reports.map((r) {
                        return DataRow(cells: [
                          DataCell(Text(r['tk_number']?.toString() ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                          DataCell(Text(r['shipment_date']?.toString() ?? '')),
                          DataCell(Text(r['employee_name']?.toString() ?? '')),
                          DataCell(Text(r['position']?.toString() ?? '')),
                          DataCell(Text(r['shipment_status']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Text('${r['fruits'] ?? 0} кг')),
                          DataCell(Text('${r['bakery'] ?? 0} кг')),
                          DataCell(Text('${r['fat_oil'] ?? 0} кг')),
                          DataCell(Text('${r['animal_waste'] ?? 0} кг')),
                          DataCell(Text(r['comment']?.toString() ?? '')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsView() {
    if (_requests.isEmpty) {
      return const Center(
          child: Text('Нет активных запросов на доступ к общей таблице',
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = _requests[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Запрос доступа от: ${req['tk_number']}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _approveAccess(req['id'].toString()),
                label: const Text('Одобрить на 24 часа'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketsView() {
    if (_tickets.isEmpty) {
      return const Center(
          child: Text('Нет обращений', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = _tickets[index];

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
              Text('${t['tk_number']} • ${t['subject']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(t['user_message'] ?? '',
                  style: const TextStyle(color: Colors.white70)),
              if (t['admin_reply'] != null) ...[
                const SizedBox(height: 8),
                Text('Ответ: ${t['admin_reply']}',
                    style: const TextStyle(color: Colors.greenAccent)),
              ],
            ],
          ),
        );
      },
    );
  }
}
