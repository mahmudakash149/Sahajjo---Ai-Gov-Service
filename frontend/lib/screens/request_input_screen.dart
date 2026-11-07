import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// FR4: Citizen Service Request Input Screen
/// Allows citizens to submit requests in natural Bangla or English.
class RequestInputScreen extends StatefulWidget {
  const RequestInputScreen({super.key});

  @override
  State<RequestInputScreen> createState() => _RequestInputScreenState();
}

class _RequestInputScreenState extends State<RequestInputScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _loadingHistory = true;
  String? _error;
  List<Map<String, dynamic>> _myRequests = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthProvider>();
    try {
      final list = await auth.fetchMyRequests();
      if (!mounted) return;
      setState(() {
        _myRequests = list;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    final auth = context.read<AuthProvider>();
    final s = auth.s;

    if (text.length < 3) {
      setState(() => _error = s.reqTextMinError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await auth.submitServiceRequest(text);
      if (!mounted) return;
      _controller.clear();
      setState(() => _submitting = false);

      final reqData = res['request'] as Map<String, dynamic>?;
      final trackingId = reqData?['id']?.toString() ?? '–';

      _showSuccessDialog(trackingId);
      _loadHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message == 'network' ? s.networkError : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  void _showSuccessDialog(String trackingId) {
    final s = context.read<AuthProvider>().s;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF006A4E), size: 48),
        title: Text(s.requestSuccess, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${s.requestTrackingId} #REQ-$trackingId',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              s.statusSubmitted,
              style: const TextStyle(color: Color(0xFF006A4E)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF006A4E)),
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  void _applySuggestion(String text) {
    setState(() {
      _controller.text = text;
      _error = null;
    });
  }

  Widget _buildStatusChip(String status, AuthProvider auth) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'under_review':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = auth.s.statusUnderReview;
        break;
      case 'processed':
      case 'completed':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = auth.s.statusProcessed;
        break;
      case 'submitted':
      default:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = auth.s.statusSubmitted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = auth.s;
    final isBn = auth.lang == 'bn';

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006A4E).withOpacity(0.08),
                  const Color(0xFF006A4E).withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006A4E).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: Color(0xFF006A4E), size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.requestHeader,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A4E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        isBn ? 'বাংলা' : 'English',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.requestSubheader,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),

                // Multi-line Text Field
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 1500,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    hintText: s.requestHint,
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF006A4E), width: 1.8),
                    ),
                  ),
                ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                // Quick suggestions
                Text(
                  s.suggestionsTitle,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ActionChip(
                      label: Text(s.chipPassport, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applySuggestion(
                        isBn
                            ? 'আমি নতুন পাসপোর্টের আবেদন করতে চাই। প্রয়োজনীয় কাগজপত্র ও ফি সম্পর্কে জানতে চাই।'
                            : 'I want to apply for a new passport. What are the required documents and fees?',
                      ),
                    ),
                    ActionChip(
                      label: Text(s.chipNid, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applySuggestion(
                        isBn
                            ? 'আমার জাতীয় পরিচয়পত্রে নামের বানান ভুল হয়েছে, কীভাবে সংশোধন করব?'
                            : 'My name is misspelled on my National ID card, how can I correct it?',
                      ),
                    ),
                    ActionChip(
                      label: Text(s.chipTrade, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applySuggestion(
                        isBn
                            ? 'আমি একটি নতুন ব্যবসা প্রতিষ্ঠান চালু করতে চাই। ট্রেড লাইসেন্স পাওয়ার প্রক্রিয়া কী?'
                            : 'I want to register a new trade license for my business. What is the procedure?',
                      ),
                    ),
                    ActionChip(
                      label: Text(s.chipMutation, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applySuggestion(
                        isBn
                            ? 'জমি কেনার পর অনলাইনে ই-নামজারি (খারিজ) আবেদনের নিয়ম জানতে চাই।'
                            : 'How do I apply online for land mutation (e-Mutation)?',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006A4E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_submitting ? s.submitting : s.submitRequest),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Previous Requests Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.myRequestsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadHistory,
                tooltip: s.retry,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Previous Requests List
          if (_loadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_myRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  s.noRequestsYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            )
          else
            ..._myRequests.map((req) {
              final reqId = req['id']?.toString() ?? '–';
              final text = req['requestText']?.toString() ?? '';
              final status = req['status']?.toString() ?? 'submitted';
              final lang = req['language']?.toString().toUpperCase() ?? 'BN';

              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#REQ-$reqId',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(lang, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                              ),
                            ],
                          ),
                          _buildStatusChip(status, auth),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
