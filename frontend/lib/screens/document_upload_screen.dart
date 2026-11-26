import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Screen for FR11 (Document Upload), FR12 (OCR Extraction),
/// FR13 (Missing Document Detection), FR14 (Mismatch Check), and FR15 (Readiness Report).
class DocumentUploadScreen extends StatefulWidget {
  final String requestId;
  final String requestText;
  final int serviceId;
  final String serviceName;
  final List<String> requiredDocuments;

  const DocumentUploadScreen({
    super.key,
    required this.requestId,
    required this.requestText,
    required this.serviceId,
    required this.serviceName,
    required this.requiredDocuments,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  late String _selectedDocType;
  late List<Map<String, String>> _docTypes;
  final List<Map<String, dynamic>> _uploadedFiles = [];
  Map<String, dynamic>? _readinessReport;
  bool _loadingDocs = true;
  bool _uploading = false;
  String? _uploadingFileName;
  bool _checkingReadiness = false;
  bool _consentGiven = false;

  static const Map<String, Map<String, String>> _allDocTypeCatalog = {
    'NID': {'key': 'NID', 'bn': 'জাতীয় পরিচয়পত্র (NID)', 'en': 'National ID (NID)'},
    'BIRTH_CERT': {'key': 'BIRTH_CERT', 'bn': 'অনলাইন জন্ম নিবন্ধন সনদ', 'en': 'Online Birth Certificate'},
    'PHOTO': {'key': 'PHOTO', 'bn': 'পাসপোর্ট সাইজ ছবি', 'en': 'Passport Size Photograph'},
    'CHALLAN': {'key': 'CHALLAN', 'bn': 'পেমেন্ট রশিদ / চালান কপি', 'en': 'Payment Receipt / Challan'},
    'EDUCATIONAL': {'key': 'EDUCATIONAL', 'bn': 'শিক্ষাগত সনদ (SSC/HSC)', 'en': 'Educational Certificate (SSC/HSC)'},
    'CITIZENSHIP': {'key': 'CITIZENSHIP', 'bn': 'নাগরিকত্ব প্রত্যয়নপত্র', 'en': 'Citizenship Certificate'},
    'UTILITY_BILL': {'key': 'UTILITY_BILL', 'bn': 'বিদ্যুৎ/পানি বিল বা ঠিকানা প্রমাণ', 'en': 'Utility Bill / Address Proof'},
    'PASSPORT': {'key': 'PASSPORT', 'bn': 'পাসপোর্ট কপি', 'en': 'Passport Copy'},
    'LAND_DEED': {'key': 'LAND_DEED', 'bn': 'জমির দলিল / খতিয়ান / নামজারি', 'en': 'Land Deed / Khatian / Mutation'},
    'TRADE_LICENSE': {'key': 'TRADE_LICENSE', 'bn': 'ট্রেড লাইসেন্স / ব্যবসার নথি', 'en': 'Trade License / Business Doc'},
    'MEDICAL_CERT': {'key': 'MEDICAL_CERT', 'bn': 'টিকা কার্ড / মেডিকেল সনদ', 'en': 'EPI Card / Medical Certificate'},
    'DRIVING_LICENSE': {'key': 'DRIVING_LICENSE', 'bn': 'ড্রাইভিং / লার্নার লাইসেন্স', 'en': 'Driving / Learner License'},
    'TIN_CERT': {'key': 'TIN_CERT', 'bn': 'টিআইএন (TIN) সনদ', 'en': 'TIN Certificate'},
    'OTHER': {'key': 'OTHER', 'bn': 'অন্যান্য নথি', 'en': 'Other Document'},
  };

  static const Map<int, List<String>> _serviceDocTypeKeys = {
    1: ['BIRTH_CERT', 'NID', 'MEDICAL_CERT', 'UTILITY_BILL', 'PHOTO', 'CHALLAN'],
    2: ['NID', 'BIRTH_CERT', 'EDUCATIONAL', 'CITIZENSHIP', 'UTILITY_BILL', 'PHOTO', 'CHALLAN'],
    3: ['NID', 'BIRTH_CERT', 'PASSPORT', 'CITIZENSHIP', 'UTILITY_BILL', 'PHOTO', 'CHALLAN'],
    4: ['NID', 'LAND_DEED', 'UTILITY_BILL', 'PHOTO', 'CHALLAN'],
    5: ['NID', 'TRADE_LICENSE', 'UTILITY_BILL', 'PHOTO', 'CHALLAN'],
    6: ['NID', 'BIRTH_CERT', 'MEDICAL_CERT', 'CITIZENSHIP', 'CHALLAN'],
    7: ['NID', 'DRIVING_LICENSE', 'MEDICAL_CERT', 'EDUCATIONAL', 'PHOTO', 'CHALLAN'],
    8: ['NID', 'TIN_CERT', 'TRADE_LICENSE', 'UTILITY_BILL', 'PHOTO'],
  };

  List<Map<String, String>> _buildServiceDocTypes() {
    final keys = List<String>.from(
      _serviceDocTypeKeys[widget.serviceId] ??
          ['NID', 'BIRTH_CERT', 'PHOTO', 'CHALLAN', 'EDUCATIONAL', 'CITIZENSHIP', 'UTILITY_BILL'],
    );

    // Ensure any requiredDocuments keywords are also represented in the dropdown
    final reqJoined = widget.requiredDocuments.join(' ').toLowerCase();
    void ensureKey(String key, List<String> triggers) {
      if (!keys.contains(key) && triggers.any((t) => reqJoined.contains(t))) {
        keys.add(key);
      }
    }

    ensureKey('NID', ['nid', 'national id', 'জাতীয় পরিচয়পত্র', 'এনআইডি']);
    ensureKey('BIRTH_CERT', ['birth', 'জন্ম']);
    ensureKey('PHOTO', ['photo', 'ছবি']);
    ensureKey('CHALLAN', ['challan', 'receipt', 'payment', 'চালান', 'রশিদ']);
    ensureKey('EDUCATIONAL', ['ssc', 'hsc', 'educational', 'শিক্ষাগত']);
    ensureKey('CITIZENSHIP', ['citizenship', 'নাগরিকত্ব']);
    ensureKey('UTILITY_BILL', ['utility', 'holding', 'rental', 'বিল', 'হোল্ডিং']);

    if (!keys.contains('OTHER')) keys.add('OTHER');
    return keys
        .where((k) => _allDocTypeCatalog.containsKey(k))
        .map((k) => _allDocTypeCatalog[k]!)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _docTypes = _buildServiceDocTypes();
    _selectedDocType = _docTypes.first['key']!;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  String _docTitle(String docType, bool isBn) {
    final match = _allDocTypeCatalog[docType] ?? _allDocTypeCatalog['OTHER']!;
    return isBn ? match['bn']! : match['en']!;
  }

  String _formatBytes(dynamic bytesVal) {
    final bytes = int.tryParse(bytesVal?.toString() ?? '0') ?? 0;
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  String _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  Future<void> _loadDocuments() async {
    try {
      final auth = context.read<AuthProvider>();
      final docs = await auth.fetchRequestDocuments(widget.requestId);
      if (!mounted) return;
      setState(() {
        _uploadedFiles
          ..clear()
          ..addAll(docs);
        _loadingDocs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDocs = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    final auth = context.read<AuthProvider>();
    final isBn = auth.lang == 'bn';

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'ফাইল পড়া যায়নি।' : 'Could not read selected file.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadingFileName = picked.name;
    });
    try {
      final res = await auth.uploadDocument(
        requestId: widget.requestId,
        docType: _selectedDocType,
        fileName: picked.name,
        bytes: bytes,
        mimeType: _inferMimeType(picked.name),
      );

      final doc = Map<String, dynamic>.from(res['document'] ?? {});
      if (!mounted) return;
      setState(() {
        _uploadedFiles.add(doc);
        _readinessReport = null;
        _uploading = false;
        _uploadingFileName = null;
      });

      final ocrMap = doc['ocrData'] is Map
          ? Map<String, dynamic>.from(doc['ocrData'] as Map)
          : <String, dynamic>{};
      final isReadable = ocrMap['isReadable'] != false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReadable
                ? (isBn
                    ? 'ডকুমেন্ট S3 স্টোরেজে আপলোড ও OCR সম্পন্ন হয়েছে!'
                    : 'Document uploaded to S3 and OCR extracted successfully!')
                : (isBn
                    ? 'ফাইল আপলোড হয়েছে, তবে ছবিটি অস্পষ্ট। অনুগ্রহ করে আরও স্পষ্ট ছবি আপলোড করুন।'
                    : 'Uploaded, but text is unclear. Please upload a clearer photo.'),
          ),
          backgroundColor: isReadable ? const Color(0xFF006A4E) : Colors.amber.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadingFileName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn ? 'আপলোড ব্যর্থ হয়েছে: $e' : 'Upload failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeDoc(int index) async {
    final auth = context.read<AuthProvider>();
    final doc = _uploadedFiles[index];
    final docId = doc['id'];

    setState(() {
      _uploadedFiles.removeAt(index);
      _readinessReport = null;
    });

    if (docId != null) {
      try {
        await auth.deleteDocument(docId);
      } catch (_) {
        // Ignore delete error if already removed
      }
    }
  }

  Future<void> _checkReadiness() async {
    final auth = context.read<AuthProvider>();
    final isBn = auth.lang == 'bn';
    setState(() => _checkingReadiness = true);

    try {
      final report = await auth.generateReadinessReport(
        requestId: widget.requestId,
        requiredDocuments: widget.requiredDocuments,
      );
      if (!mounted) return;
      setState(() {
        _readinessReport = report;
        _checkingReadiness = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkingReadiness = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'রিপোর্ট তৈরি ব্যর্থ: $e' : 'Failed to generate report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = auth.s;
    final isBn = auth.lang == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.docUploadTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '#REQ-${widget.requestId} • ${widget.serviceName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner introducing FR11-FR15
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF006A4E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF006A4E).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Color(0xFF006A4E), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? 'ডকুমেন্ট ভেরিফিকেশন ও রেডিনেস মডিউল' : 'Document Readiness Module',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF006A4E)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.docUploadSubtitle,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Required Checklist Section (FR13 source)
          Text(
            s.requiredDocs,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: widget.requiredDocuments.isEmpty
                ? Text(
                    isBn ? 'কোনো নির্দিষ্ট কাগজপত্রের তালিকা নেই।' : 'No specific checklist for this service.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  )
                : Column(
                    children: widget.requiredDocuments.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF006A4E), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(doc, style: const TextStyle(fontSize: 13, height: 1.3)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 20),

          // FR11: Document Upload Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: Color(0xFF006A4E), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      s.chooseFile,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  s.selectDocType,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDocType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _docTypes.map((dt) {
                    return DropdownMenuItem<String>(
                      value: dt['key'],
                      child: Text(
                        isBn ? dt['bn']! : dt['en']!,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _uploading
                      ? null
                      : (val) {
                          if (val != null) setState(() => _selectedDocType = val);
                        },
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _consentGiven,
                  onChanged: _uploading
                      ? null
                      : (val) => setState(() => _consentGiven = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF006A4E),
                  title: Text(
                    isBn
                        ? 'আমি আমার নথি নিরাপদে সংরক্ষণ ও OCR যাচাইয়ের জন্য সম্মতি দিচ্ছি (আপনি যেকোনো সময় নথি মুছতে পারবেন)।'
                        : 'I consent to securely storing and scanning my documents via OCR (you can delete them anytime).',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006A4E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (_uploading || !_consentGiven) ? null : _pickAndUploadDocument,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: Text(
                      _uploading
                          ? (isBn ? 'আপলোড ও OCR চলছে...' : 'Uploading & Running OCR...')
                          : (isBn ? 'নথি নির্বাচন ও আপলোড করুন' : 'Select & Upload Document'),
                    ),
                  ),
                ),
                if (_uploading) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A4E).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF006A4E).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn
                              ? 'প্রক্রিয়াকরণ চলছে: ${_uploadingFileName ?? ''}'
                              : 'Processing: ${_uploadingFileName ?? ''}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006A4E)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn
                              ? '• S3 স্টোরেজে সংরক্ষণ ও OCR দিয়ে নাম, জন্ম তারিখ, আইডি নম্বর, পিতা/মাতার নাম এবং ঠিকানা পড়া হচ্ছে...'
                              : '• Saving to S3 storage & extracting Name, DOB, ID Number, Parents & Address via OCR...',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Uploaded Documents List with OCR (FR11 & FR12)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.uploadedDocs} (${_uploadedFiles.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              if (_uploadedFiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    isBn ? 'S3 + OCR সক্রিয়' : 'S3 + OCR Active',
                    style: TextStyle(fontSize: 10.5, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_loadingDocs)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_uploadedFiles.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      s.noDocsUploaded,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._uploadedFiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final file = entry.value;
              final docType = (file['docType'] ?? 'OTHER').toString();
              final ocr = file['ocrData'] is Map
                  ? Map<String, dynamic>.from(file['ocrData'] as Map)
                  : <String, dynamic>{};

              return Card(
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
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF006A4E).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.description, color: Color(0xFF006A4E), size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _docTitle(docType, isBn),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${file['fileName'] ?? ''} • ${_formatBytes(file['fileSize'])}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeDoc(idx),
                            tooltip: s.delete,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // FR12: Detailed OCR Extracted Fields Card
                      _buildOcrDetailsBox(ocr, isBn),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),

          // FR15: Readiness Report Button
          if (_uploadedFiles.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006A4E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _checkingReadiness ? null : _checkReadiness,
                icon: _checkingReadiness
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.assessment_outlined, size: 18),
                label: Text(s.checkReadinessBtn),
              ),
            ),

          // FR13, FR14, FR15: Readiness Report View
          if (_readinessReport != null && _uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildReadinessReportCard(isBn, _readinessReport!),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOcrDetailsBox(Map<String, dynamic> ocr, bool isBn) {
    final ocrEngine = ocr['ocrEngine']?.toString() ?? 'ocr';
    final confRaw = ocr['confidence'];
    final confPct = confRaw is num ? '${(confRaw * 100).round()}%' : null;

    final nameEn = ocr['fullNameEn']?.toString() ?? ocr['fullName']?.toString();
    final nameBn = ocr['fullNameBn']?.toString();
    final dob = ocr['dateOfBirth']?.toString();
    final docNo = ocr['documentNumber']?.toString();
    final father = ocr['fatherName']?.toString();
    final mother = ocr['motherName']?.toString();
    final address = ocr['address']?.toString();
    final rawText = ocr['rawText']?.toString() ?? '';
    final isReadable = ocr['isReadable'] != false;

    final rows = <MapEntry<String, String>>[];
    if (nameEn != null && nameEn.isNotEmpty) {
      rows.add(MapEntry(isBn ? 'নাম (EN)' : 'Name (EN)', nameEn));
    }
    if (nameBn != null && nameBn.isNotEmpty && nameBn != nameEn) {
      rows.add(MapEntry(isBn ? 'নাম (BN)' : 'Name (BN)', nameBn));
    }
    if (dob != null && dob.isNotEmpty) {
      rows.add(MapEntry(isBn ? 'জন্ম তারিখ' : 'Date of Birth', dob));
    }
    if (docNo != null && docNo.isNotEmpty) {
      rows.add(MapEntry(isBn ? 'ডকুমেন্ট নম্বর' : 'Document No.', docNo));
    }
    if (father != null && father.isNotEmpty) {
      rows.add(MapEntry(isBn ? 'পিতার নাম' : "Father's Name", father));
    }
    if (mother != null && mother.isNotEmpty) {
      rows.add(MapEntry(isBn ? 'মাতার নাম' : "Mother's Name", mother));
    }
    if (address != null && address.isNotEmpty) {
      rows.add(MapEntry(isBn ? 'ঠিকানা' : 'Address', address));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? 'OCR থেকে প্রাপ্ত তথ্য' : 'OCR Extracted Info',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A4E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  confPct != null ? '$ocrEngine • $confPct' : ocrEngine,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF006A4E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!isReadable)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                isBn
                    ? '⚠️ ছবিটি অস্পষ্ট বা পঠনযোগ্য নয়। অনুগ্রহ করে এই নথিটি মুছে আরও স্পষ্ট ছবি আপলোড করুন।'
                    : '⚠️ This document looks blurry or unreadable. Please delete it and upload a clearer photo.',
                style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
              ),
            ),
          if (rows.isEmpty)
            Text(
              isBn ? 'কোনো টেক্সট/তথ্য সনাক্ত করা যায়নি।' : 'No structured text fields detected.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            )
          else
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        '${r.key}:',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (rawText.trim().isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4),
                dense: true,
                title: Text(
                  isBn ? 'সম্পূর্ণ OCR টেক্সট দেখুন' : 'View full extracted OCR text',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      rawText,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadinessReportCard(bool isBn, Map<String, dynamic> report) {
    final s = context.read<AuthProvider>().s;
    final isReady = report['isReady'] == true;
    final missing = (report['missingDocuments'] as List? ?? []).map((e) => e.toString()).toList();
    final mismatches = (report['mismatches'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isReady ? Colors.green.shade300 : Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? 'রেডিনেস রিপোর্ট' : 'Readiness Report',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isReady ? Colors.green.shade900 : Colors.amber.shade900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReady ? Colors.green.shade200 : Colors.amber.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isReady ? (isBn ? 'প্রস্তুত' : 'Ready') : (isBn ? 'অসম্পূর্ণ' : 'Action Needed'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isReady ? Colors.green.shade900 : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // FR13: Missing Document Detection
          Text(
            isBn ? '১. অনুপস্থিত ডকুমেন্টস:' : '1. Missing Documents:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          if (missing.isEmpty)
            Text(
              isBn ? '✓ প্রয়োজনীয় সকল নথি আপলোড করা হয়েছে।' : '✓ All expected documents uploaded.',
              style: TextStyle(fontSize: 12.5, color: Colors.green.shade800),
            )
          else
            ...missing.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '⚠️ $m',
                  style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // FR14: Document Mismatch Detection
          Text(
            isBn ? '২. তথ্যের গরমিল ও অসঙ্গতি:' : '2. Information Mismatch:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          if (mismatches.isNotEmpty)
            ...mismatches.map(
              (mm) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '⚠️ ${isBn ? (mm['messageBn'] ?? mm['messageEn']) : (mm['messageEn'] ?? mm['messageBn'])}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade900, height: 1.3),
                ),
              ),
            )
          else
            Text(
              isBn ? '✓ আপলোডকৃত নথির নাম ও জন্ম তারিখে কোনো গরমিল পাওয়া যায়নি।' : '✓ No name or date discrepancies detected across files.',
              style: TextStyle(fontSize: 12.5, color: Colors.green.shade800),
            ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Mandatory Preliminary Disclaimer (SRS requirement)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.preliminaryDisclaimer,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
