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
  String _selectedDocType = 'NID';
  final List<Map<String, dynamic>> _uploadedFiles = [];
  bool _showReport = false;

  final List<Map<String, String>> _docTypes = [
    {'key': 'NID', 'bn': 'জাতীয় পরিচয়পত্র (NID)', 'en': 'National ID (NID)'},
    {'key': 'BIRTH_CERT', 'bn': 'অনলাইন জন্ম নিবন্ধন সনদ', 'en': 'Online Birth Certificate'},
    {'key': 'EDUCATIONAL', 'bn': 'শিক্ষাগত সনদ (SSC/HSC)', 'en': 'Educational Certificate (SSC/HSC)'},
    {'key': 'CITIZENSHIP', 'bn': 'নাগরিকত্ব প্রত্যয়নপত্র', 'en': 'Citizenship Certificate'},
    {'key': 'UTILITY_BILL', 'bn': 'বিদ্যুৎ/পানি বিল (ঠিকানা প্রমাণ)', 'en': 'Utility Bill (Address Proof)'},
    {'key': 'OTHER', 'bn': 'অন্যান্য নথি', 'en': 'Other Document'},
  ];

  void _simulateUpload() {
    final auth = context.read<AuthProvider>();
    final isBn = auth.lang == 'bn';

    final selectedObj = _docTypes.firstWhere(
      (d) => d['key'] == _selectedDocType,
      orElse: () => _docTypes[0],
    );

    final title = isBn ? selectedObj['bn']! : selectedObj['en']!;

    // Simulated OCR extraction data
    String extractedName = isBn ? 'মোঃ আকাশ মাহমুদ' : 'Md. Akash Mahmud';
    String extractedDate = '1998-05-12';

    // If uploading educational cert, simulate a slight name mismatch to demonstrate FR14
    if (_selectedDocType == 'EDUCATIONAL') {
      extractedName = isBn ? 'আকাশ মাহমুদ' : 'Akash Mahmud'; // Missing "Md."
    }

    setState(() {
      _uploadedFiles.add({
        'type': _selectedDocType,
        'title': title,
        'fileName': '${_selectedDocType.toLowerCase()}_sample_${_uploadedFiles.length + 1}.jpg',
        'fileSize': '1.2 MB',
        'uploadedAt': 'Just now',
        'ocrName': extractedName,
        'ocrDate': extractedDate,
      });
      _showReport = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBn
              ? 'ডকুমেন্ট সফলভাবে আপলোড ও ওসিআর (OCR) সম্পন্ন হয়েছে!'
              : 'Document uploaded and OCR extracted successfully!',
        ),
        backgroundColor: const Color(0xFF006A4E),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeDoc(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
      _showReport = false;
    });
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
                      'FR11: ${s.chooseFile}',
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
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDocType = val);
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006A4E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _simulateUpload,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: Text(isBn ? 'নথি নির্বাচন ও আপলোড করুন' : 'Select & Upload Document'),
                  ),
                ),
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
                    isBn ? 'OCR সক্রিয়' : 'OCR Active',
                    style: TextStyle(fontSize: 10.5, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_uploadedFiles.isEmpty)
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
                          Row(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  Text(
                                    '${file['fileName']} • ${file['fileSize']}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeDoc(idx),
                            tooltip: s.delete,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // FR12: OCR Extracted Fields Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'OCR: ${file['ocrName']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'DOB: ${file['ocrDate']}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
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
                onPressed: () => setState(() => _showReport = !_showReport),
                icon: const Icon(Icons.assessment_outlined, size: 18),
                label: Text(s.checkReadinessBtn),
              ),
            ),

          // FR13, FR14, FR15: Readiness Report View
          if (_showReport && _uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildReadinessReportCard(isBn),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildReadinessReportCard(bool isBn) {
    final s = context.read<AuthProvider>().s;
    final hasMismatch = _uploadedFiles.any((f) => f['type'] == 'EDUCATIONAL');
    final totalExpected = widget.requiredDocuments.isNotEmpty ? widget.requiredDocuments.length : 3;
    final totalUploaded = _uploadedFiles.length;
    final isReady = totalUploaded >= 2 && !hasMismatch;

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
                isBn ? 'রেডিনেস রিপোর্ট (FR15)' : 'Readiness Report (FR15)',
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
            isBn ? '১. অনুপস্থিত ডকুমেন্টস (FR13):' : '1. Missing Documents (FR13):',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          if (totalUploaded >= totalExpected)
            Text(
              isBn ? '✓ প্রয়োজনীয় সকল নথি আপলোড করা হয়েছে।' : '✓ All expected documents uploaded.',
              style: TextStyle(fontSize: 12.5, color: Colors.green.shade800),
            )
          else
            Text(
              isBn
                  ? '⚠️ এখনও ${(totalExpected - totalUploaded).clamp(1, 10)} টি আবশ্যক নথি অনুপস্থিত রয়েছে।'
                  : '⚠️ Still missing ${(totalExpected - totalUploaded).clamp(1, 10)} required document(s).',
              style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900),
            ),

          const SizedBox(height: 12),

          // FR14: Document Mismatch Detection
          Text(
            isBn ? '২. তথ্যের গরমিল ও অসঙ্গতি (FR14):' : '2. Information Mismatch (FR14):',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          if (hasMismatch)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                isBn
                    ? '⚠️ সতর্কবার্তা: শিক্ষাগত সনদের নামের সাথে ("Akash Mahmud") জাতীয় পরিচয়পত্রের নামের বানান ("Md. Akash Mahmud") হুবহু মিল নেই। যাচাই করুন।'
                    : '⚠️ Warning: Name spelling on Educational Certificate ("Akash Mahmud") does not strictly match NID ("Md. Akash Mahmud"). Please review.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade900, height: 1.3),
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
