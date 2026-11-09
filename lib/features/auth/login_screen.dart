import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/session_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../user/home_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAdminMode = false;
  bool _isLoading = false;

  final _tkController = TextEditingController();
  final _passwordController = TextEditingController();

  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void dispose() {
    _tkController.dispose();
    _passwordController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginTk() async {
    final tk = _tkController.text.trim();
    final password = _passwordController.text.trim();

    if (tk.isEmpty || password.isEmpty) {
      _showMessage('Введите номер ТК/РЦ и пароль');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('tk_accounts')
          .select('tk_number, password_hash')
          .eq('tk_number', tk)
          .limit(1)
          .timeout(const Duration(seconds: 12));

      final list = res as List;
      if (list.isEmpty || list.first['password_hash'] != password) {
        _showMessage('Неверный номер объекта или пароль');
        setState(() => _isLoading = false);
        return;
      }

      await SessionService.saveTkSession(tk);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeShellScreen(tkNumber: tk)),
      );
    } catch (e) {
      debugPrint('Login TK error: $e');
      _showMessage('Ошибка подключения к базе: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAdmin() async {
    final email = _adminEmailController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Введите email и пароль координатора');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRes = await Supabase.instance.client.auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 12));

      if (authRes.user == null) {
        _showMessage('Неверные учетные данные координатора');
        setState(() => _isLoading = false);
        return;
      }

      await SessionService.saveAdminSession(true);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } catch (e) {
      debugPrint('Login Admin error: $e');
      _showMessage('Ошибка входа координатора: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.recycling_rounded,
                      size: 54,
                      color: Color(0xFFE50914),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isAdminMode ? 'Вход координатора' : 'Портал учета ИСГ',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isAdminMode
                          ? 'Панель сводной аналитики'
                          : 'Вход для сотрудников ТК и РЦ',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    if (!_isAdminMode) ...[
                      TextField(
                        controller: _tkController,
                        decoration: const InputDecoration(
                          labelText: 'Объект (например: ТК 176 или РЦ 1)',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль объекта',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE50914),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _loginTk,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Войти как ТК / РЦ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _adminEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Корпоративный Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _adminPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE50914),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _loginAdmin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Войти в панель координатора',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => _isAdminMode = !_isAdminMode);
                      },
                      child: Text(
                        _isAdminMode
                            ? '← Вернуться ко входу ТК / РЦ'
                            : 'Вход для координаторов и администраторов',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Divider(height: 32, color: Colors.white12),
                    Text(
                      'Координатор: ${AppConstants.coordinatorName}\n${AppConstants.coordinatorPhone}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
