import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'document_upload_screen.dart';

/// FR4 + AI Service Identification Screen
/// Accepts citizen requests in Bangla/English and displays Gemini AI service identification.
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
      final aiDiagnosis = reqData?['aiDiagnosis'] as Map<String, dynamic>?;

      _showGuidanceBottomSheet(trackingId, aiDiagnosis);
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

  void _showGuidanceBottomSheet(String trackingId, Map<String, dynamic>? aiDiagnosis) {
    if (aiDiagnosis == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => GuidanceBottomSheetWidget(
        trackingId: trackingId,
        initialAiDiagnosis: aiDiagnosis,
        onRefined: _loadHistory,
      ),
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
      case 'refined':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = auth.s.refinedBadge;
        break;
      case 'under_review':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = auth.s.statusUnderReview;
        break;
      case 'processed':
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade900;
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
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
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
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006A4E).withValues(alpha: 0.08),
                  const Color(0xFF006A4E).withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006A4E).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF006A4E), size: 26),
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

                // Quick Suggestions
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
                      avatar: const Icon(Icons.flight_takeoff, size: 16),
                      label: Text(s.chipPassport, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applySuggestion(
                        isBn
                            ? 'আমি নতুন পাসপোর্টের আবেদন করতে চাই। প্রয়োজনীয় কাগজপত্র ও ফি সম্পর্কে জানতে চাই।'
                            : 'I want to apply for a new passport. What are the required documents and fees?',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.badge_outlined, size: 16),
                      label: Text(s.chipNid, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applySuggestion(
                        isBn
                            ? 'আমার জাতীয় পরিচয়পত্রে নামের বানান ভুল হয়েছে, কীভাবে সংশোধন করব?'
                            : 'My name is misspelled on my National ID card, how can I correct it?',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.storefront_outlined, size: 16),
                      label: Text(s.chipTrade, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applySuggestion(
                        isBn
                            ? 'আমি একটি নতুন ব্যবসা প্রতিষ্ঠান চালু করতে চাই। ট্রেড লাইসেন্স পাওয়ার প্রক্রিয়া কী?'
                            : 'I want to register a new trade license for my business. What is the procedure?',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.landscape_outlined, size: 16),
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
                        : const Icon(Icons.auto_awesome, size: 18),
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
              final ai = req['aiDiagnosis'] as Map<String, dynamic>?;

              final matchedServiceName = ai != null
                  ? (isBn ? (ai['serviceNameBn'] ?? ai['serviceName']) : (ai['serviceName'] ?? ai['serviceNameBn']))
                  : null;

              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: ai != null ? const Color(0xFF006A4E).withValues(alpha: 0.3) : Colors.grey.shade200,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (ai != null) {
                      _showGuidanceBottomSheet(reqId, ai);
                    }
                  },
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
                        Text(text, style: const TextStyle(fontSize: 14)),
                        if (matchedServiceName != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006A4E).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFF006A4E), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$matchedServiceName',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: Color(0xFF006A4E),
                                    ),
                                  ),
                                ),
                                Text(
                                  s.tapToViewGuidance,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF006A4E),
                                side: const BorderSide(color: Color(0xFF006A4E), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DocumentUploadScreen(
                                      requestId: reqId,
                                      requestText: text,
                                      serviceId: (ai != null && ai['serviceId'] is int) ? ai['serviceId'] : 0,
                                      serviceName: matchedServiceName,
                                      requiredDocuments: (ai != null && ai['requiredDocuments'] is List)
                                          ? (ai['requiredDocuments'] as List).map((e) => e.toString()).toList()
                                          : [],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.upload_file_outlined, size: 16),
                              label: Text(
                                s.uploadDocsBtn,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// FR6: Interactive Guidance Bottom Sheet Widget with Follow-Up Questions and Refinement
class GuidanceBottomSheetWidget extends StatefulWidget {
  final String trackingId;
  final Map<String, dynamic> initialAiDiagnosis;
  final VoidCallback onRefined;

  const GuidanceBottomSheetWidget({
    super.key,
    required this.trackingId,
    required this.initialAiDiagnosis,
    required this.onRefined,
  });

  @override
  State<GuidanceBottomSheetWidget> createState() => _GuidanceBottomSheetWidgetState();
}

class _GuidanceBottomSheetWidgetState extends State<GuidanceBottomSheetWidget> {
  late Map<String, dynamic> _ai = Map<String, dynamic>.from(widget.initialAiDiagnosis);
  final Map<String, String> _selectedAnswers = {};
  bool _refining = false;
  String? _refineError;

  Future<void> _submitRefinement(AuthProvider auth) async {
    if (_selectedAnswers.isEmpty) {
      setState(() => _refineError = auth.s.selectAnswerPrompt);
      return;
    }

    setState(() {
      _refining = true;
      _refineError = null;
    });

    final rawQuestions = _ai['followUpQuestions'] as List? ?? [];
    final followUpQuestions = rawQuestions.whereType<Map>().toList();

    // Collect all question texts (including sub-questions) for accurate refinement payloads
    final questionTextMap = <String, String>{};
    for (final q in followUpQuestions) {
      final id = q['id']?.toString() ?? '';
      final text = q['question']?.toString() ?? '';
      if (id.isNotEmpty) questionTextMap[id] = text;
      final subMap = q['subQuestionsByOption'] as Map?;
      if (subMap != null) {
        subMap.forEach((_, subList) {
          if (subList is List) {
            for (final sq in subList) {
              if (sq is Map) {
                final sqId = sq['id']?.toString() ?? '';
                final sqText = sq['question']?.toString() ?? '';
                if (sqId.isNotEmpty) questionTextMap[sqId] = sqText;
              }
            }
          }
        });
      }
    }

    final answersList = _selectedAnswers.entries.map((entry) {
      final qId = entry.key;
      final answer = entry.value;
      final questionText = questionTextMap[qId] ?? qId;
      return {
        'questionId': qId,
        'question': questionText,
        'answer': answer,
      };
    }).toList();

    try {
      final res = await auth.submitFollowUpAnswer(widget.trackingId, answersList);
      if (!mounted) return;

      final updatedReq = res['request'] as Map<String, dynamic>?;
      final newAi = updatedReq?['aiDiagnosis'] as Map<String, dynamic>?;

      if (newAi != null) {
        setState(() {
          _ai = Map<String, dynamic>.from(newAi);
          _selectedAnswers.clear();
        });
      }

      widget.onRefined();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.s.guidanceRefinedSuccess),
          backgroundColor: const Color(0xFF006A4E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _refineError = e.toString());
    } finally {
      if (mounted) setState(() => _refining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = auth.s;
    final isBn = auth.lang == 'bn';

    final serviceName = isBn
        ? (_ai['serviceNameBn'] ?? _ai['serviceName'] ?? '')
        : (_ai['serviceName'] ?? _ai['serviceNameBn'] ?? '');
    final confidence = ((_ai['confidence'] ?? 0.9) * 100).toInt();
    final summary = _ai['summary']?.toString() ?? '';
    final docs = (_ai['requiredDocuments'] as List? ?? []).map((e) => e.toString()).toList();
    final steps = (_ai['steps'] as List? ?? []).map((e) => e.toString()).toList();

    final rawQuestions = _ai['followUpQuestions'] as List? ?? [];
    final followUpQuestions = rawQuestions.whereType<Map>().toList();

    final isRefined = _ai['refined'] == true || _ai['clarifiedDetails'] != null;
    final clarifiedDetails = _ai['clarifiedDetails'] as List? ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Top Header: AI Badge / Refined Badge & Tracking ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isRefined ? Colors.green : const Color(0xFF006A4E)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRefined ? Icons.verified : Icons.auto_awesome,
                      color: isRefined ? Colors.green.shade800 : const Color(0xFF006A4E),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRefined ? s.refinedBadge : s.aiPoweredBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isRefined ? Colors.green.shade800 : const Color(0xFF006A4E),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '#REQ-${widget.trackingId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Identified Service Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF006A4E).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006A4E).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.identifiedService,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A4E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$confidence% ${s.matchConfidence}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    summary,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                  ),
                ],
              ],
            ),
          ),

          // Refined summary banner if already answered
          if (isRefined && clarifiedDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF006A4E), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        s.guidanceRefinedSuccess,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF006A4E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...clarifiedDetails.map((detail) {
                    final q = (detail is Map ? (detail['question'] ?? '') : '').toString();
                    final a = (detail is Map ? (detail['answer'] ?? '') : '').toString();
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• ${q.isNotEmpty ? '$q: ' : ''}$a',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // FR6: Interactive Follow-up Questions Card
          if (followUpQuestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // light emerald
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF006A4E).withValues(alpha: 0.35), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A4E).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: Color(0xFF006A4E), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.followUpTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: Color(0xFF006A4E),
                              ),
                            ),
                            Text(
                              s.followUpSubtitle,
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 10),

                  // Questions & Choice Chips
                  ...followUpQuestions.map((q) {
                    final qId = q['id']?.toString() ?? 'q1';
                    final qText = q['question']?.toString() ?? '';
                    final options = (q['options'] as List? ?? []).map((e) => e.toString()).toList();
                    final selectedVal = _selectedAnswers[qId];

                    // Check for dynamic sub-questions based on selected option (e.g. Final NID Question Bank)
                    final subQuestionsMap = q['subQuestionsByOption'] as Map?;
                    List<dynamic>? activeSubQuestions;
                    if (subQuestionsMap != null && selectedVal != null) {
                      activeSubQuestions = subQuestionsMap[selectedVal] as List?;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            qText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: options.map((opt) {
                              final isSelected = selectedVal == opt;
                              return ChoiceChip(
                                label: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF006A4E),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF006A4E) : Colors.grey.shade300,
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedAnswers[qId] = opt;
                                    } else {
                                      _selectedAnswers.remove(qId);
                                      // Clean any previous sub-answers if parent question changed
                                      if (subQuestionsMap != null) {
                                        subQuestionsMap.forEach((_, subs) {
                                          if (subs is List) {
                                            for (final sq in subs) {
                                              if (sq is Map && sq['id'] != null) {
                                                _selectedAnswers.remove(sq['id'].toString());
                                              }
                                            }
                                          }
                                        });
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          if (activeSubQuestions != null && activeSubQuestions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              margin: const EdgeInsets.only(top: 4, left: 4),
                              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: const BorderSide(color: Color(0xFF006A4E), width: 3.5),
                                  top: BorderSide(color: Colors.grey.shade200),
                                  right: BorderSide(color: Colors.grey.shade200),
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: activeSubQuestions.whereType<Map>().map((sq) {
                                  final sqId = sq['id']?.toString() ?? 'sq1';
                                  final sqText = sq['question']?.toString() ?? '';
                                  final sqOptions = (sq['options'] as List? ?? []).map((e) => e.toString()).toList();
                                  final sqSelected = _selectedAnswers[sqId];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sqText,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: sqOptions.map((sopt) {
                                            final isSqSelected = sqSelected == sopt;
                                            return ChoiceChip(
                                              label: Text(
                                                sopt,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: isSqSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSqSelected ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              selected: isSqSelected,
                                              selectedColor: const Color(0xFF006A4E),
                                              backgroundColor: Colors.grey.shade50,
                                              side: BorderSide(
                                                color: isSqSelected ? const Color(0xFF006A4E) : Colors.grey.shade300,
                                              ),
                                              onSelected: (bool selected) {
                                                setState(() {
                                                  if (selected) {
                                                    _selectedAnswers[sqId] = sopt;
                                                  } else {
                                                    _selectedAnswers.remove(sqId);
                                                  }
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  if (_refineError != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _refineError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  // Refine action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF006A4E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _refining ? null : () => _submitRefinement(auth),
                      icon: _refining
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        _refining ? s.refining : s.refineGuidance,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Required Documents
          if (docs.isNotEmpty) ...[
            Text(
              s.requiredDocs,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF006A4E), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(doc, style: const TextStyle(fontSize: 13.5, height: 1.3)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006A4E).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFF006A4E),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentUploadScreen(
                        requestId: widget.trackingId,
                        requestText: '',
                        serviceId: _ai['serviceId'] ?? 0,
                        serviceName: serviceName,
                        requiredDocuments: docs,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(
                  s.uploadDocsBtn,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Step-by-Step Procedure
          if (steps.isNotEmpty) ...[
            Text(
              s.stepsTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map(
              (entry) {
                final idx = entry.key + 1;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: const Color(0xFF006A4E),
                        child: Text(
                          '$idx',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(step, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 20),

          // Close Button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }
}
