import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/types.dart';

class SupportTab extends StatefulWidget {
  final String tkNumber;

  const SupportTab({super.key, required this.tkNumber});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab>
    with AutomaticKeepAliveClientMixin {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = true;
  JsonList _tickets = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('support_tickets')
          .select()
          .eq('tk_number', widget.tkNumber)
          .order('created_at', ascending: false)
          .limit(30)
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;
      setState(() {
        _tickets = (res as List).cast<JsonMap>();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _createTicketDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Новое обращение координатору'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Тема обращения'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Текст обращения'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914)),
            onPressed: () async {
              final sub = _subjectController.text.trim();
              final msg = _messageController.text.trim();
              if (sub.isEmpty || msg.isEmpty) return;

              Navigator.of(ctx).pop();
              await Supabase.instance.client.from('support_tickets').insert({
                'tk_number': widget.tkNumber,
                'subject': sub,
                'user_message': msg,
              });

              _subjectController.clear();
              _messageController.clear();
              _loadTickets();
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Обращения объекта',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914)),
                onPressed: _createTicketDialog,
                label: const Text('Написать'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)))
              : _tickets.isEmpty
                  ? const Center(
                      child: Text('Нет открытых обращений',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = _tickets[index];
                        final hasReply = t['admin_reply'] != null;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: hasReply
                                    ? Colors.greenAccent.withOpacity(0.4)
                                    : Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['subject'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(t['user_message'] ?? '',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              if (hasReply) ...[
                                const Divider(
                                    height: 16, color: Colors.white10),
                                Text('Ответ координатора: ${t['admin_reply']}',
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 13)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
