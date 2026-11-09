import 'package:flutter/material.dart';
import '../../core/session_service.dart';
import '../auth/login_screen.dart';
import 'form_tab.dart';
import 'history_tab.dart';
import 'global_table_tab.dart';
import 'support_tab.dart';

class HomeShellScreen extends StatefulWidget {
  final String tkNumber;

  const HomeShellScreen({super.key, required this.tkNumber});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      FormTab(tkNumber: widget.tkNumber),
      HistoryTab(tkNumber: widget.tkNumber),
      GlobalTableTab(tkNumber: widget.tkNumber),
      SupportTab(tkNumber: widget.tkNumber),
    ];
  }

  void _logout() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tkNumber,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Выйти из профиля',
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFE50914),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1E1E1E),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.edit_note), label: 'Сдать отчет'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Моя история'),
          BottomNavigationBarItem(
              icon: Icon(Icons.table_chart_outlined),
              label: 'Сводка сети (24ч)'),
          BottomNavigationBarItem(
              icon: Icon(Icons.support_agent), label: 'Поддержка'),
        ],
      ),
    );
  }
}
