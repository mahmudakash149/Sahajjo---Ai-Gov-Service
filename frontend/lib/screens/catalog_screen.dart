import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// FR3: service catalog grouped by category, with search and a short description.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _requestId = 0; // ignore out-of-date responses while the user keeps typing
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_requestId;
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await auth.fetchServices(_search.text.trim());
      if (!mounted || id != _requestId) return;
      setState(() {
        _services = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = e.message == 'network' ? auth.s.networkError : e.message;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
    setState(() {}); // refresh the clear (x) button
  }

  void _showDetails(Map<String, dynamic> svc, bool bn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ServiceDetailsSheet(svc: svc, isBn: bn),
    );
  }

  Widget _body(AuthProvider auth, bool bn) {
    final s = auth.s;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: Text(s.retry)),
          ],
        ),
      );
    }
    if (_services.isEmpty) return Center(child: Text(s.noServices));

    final items = <Widget>[];
    int? lastCategory;
    for (final svc in _services) {
      if (svc['categoryId'] != lastCategory) {
        lastCategory = svc['categoryId'] as int;
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Text(
            bn ? svc['categoryNameBn'] : svc['categoryNameEn'],
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ));
      }
      items.add(Card(
        child: ListTile(
          leading: const Icon(Icons.account_balance_outlined),
          title: Text(bn ? svc['nameBn'] : svc['nameEn']),
          subtitle: Text(bn ? svc['descriptionBn'] : svc['descriptionEn'],
              maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: svc['isPriority'] == true
              ? Icon(Icons.star, color: Colors.amber.shade700, semanticLabel: s.priorityService)
              : null,
          onTap: () => _showDetails(svc, bn),
        ),
      ));
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: items);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bn = auth.lang == 'bn';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: auth.s.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        _load();
                        setState(() {});
                      },
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(child: _body(auth, bn)),
      ],
    );
  }
}

/// Comprehensive interactive details modal for government services in the catalog.
/// Provides tabbed switching between "New Application" (নতুন আবেদন) and "Correction/Renewal" (তথ্য সংশোধন).
class ServiceDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> svc;
  final bool isBn;

  const ServiceDetailsSheet({
    super.key,
    required this.svc,
    required this.isBn,
  });

  @override
  State<ServiceDetailsSheet> createState() => _ServiceDetailsSheetState();
}

class _ServiceDetailsSheetState extends State<ServiceDetailsSheet> {
  int _selectedTab = 0; // 0 = New Application, 1 = Correction & Renewal

  // Local fallback knowledge base in case backend API doesn't provide guideline payload
  static final Map<int, Map<String, dynamic>> _localGuidelines = {
    1: {
      'portalUrl': 'https://bdris.gov.bd',
      'tipsBn': 'দালাল পরিহার করুন। আবেদন ফি সর্বদা অনুমোদিত ব্যাংকে বা অনলাইনে জমা দিয়ে চালান রশিদ সংগ্রহ করুন।',
      'tipsEn': 'Avoid unauthorized brokers. Always pay official fees through accredited banks or online challan.',
      'newApplication': {
        'docsBn': [
          'শিশুর ইপিআই (EPI) টিকা কার্ডের মূল কপি ও সত্যায়িত ফটোকপি',
          'পিতা ও মাতার ১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন ও এনআইডি কপি',
          'বাসার হোল্ডিং ট্যাক্স রশিদ / হালনাগাদ জমির খাজনা দাখিলা / ভাড়ার চুক্তিপত্র',
          'সরকারি আবেদন ফি জমার রশিদ (চালান কপি)',
        ],
        'docsEn': [
          "Child's original EPI immunization card and attested copy",
          "Parents' 17-digit online birth certificates and NID copies",
          'Holding tax payment receipt / Land revenue tax slip / Rental agreement',
          'Official government application fee challan / payment receipt',
        ],
        'stepsBn': [
          'bdris.gov.bd ওয়েবসাইটে গিয়ে "জন্ম নিবন্ধনের জন্য আবেদন" ফরমটি নির্ভুলভাবে পূরণ করুন।',
          'আবেদন সম্পন্ন করে আবেদনপত্রের প্রিন্ট কপি ও চালান ফি প্রস্তুত করুন।',
          'স্থানীয় ইউনিয়ন পরিষদ / পৌরসভা / সিটি কর্পোরেশন অফিসে মূল কাগজপত্রসহ প্রিন্ট কপি জমা দিয়ে সনদ গ্রহণ করুন।',
        ],
        'stepsEn': [
          'Fill out the online application at the official bdris.gov.bd portal.',
          'Print the submitted application form and pay the designated government fee.',
          'Submit the printed form with original supporting documents to your local Union Parishad / Municipality / City Corporation office to collect the certificate.',
        ],
      },
      'correction': {
        'docsBn': [
          'বিদ্যমান মূল জন্ম নিবন্ধন সনদের ডিজিটাল কপি ও ফটোকপি',
          'নাম বা বয়স প্রমাণের স্বপক্ষে শিক্ষাগত সনদ (JSC/SSC/সমমান) অথবা পাসপোর্ট',
          'পিতা/মাতার নাম সংশোধনের ক্ষেত্রে পিতা-মাতার এনআইডি/সংশোধিত জন্ম সনদ',
          'স্থানীয় ওয়ার্ড কাউন্সিলর / চেয়ারম্যানের সত্যায়িত প্রত্যয়নপত্র',
        ],
        'docsEn': [
          'Existing original birth registration certificate and digital copy',
          'Educational certificates (JSC/SSC/equivalent) or Passport as evidence of age/name',
          "Parents' corrected NID or birth certificate (if correcting parental details)",
          'Verification certificate from local Ward Councilor / Union Chairman',
        ],
        'stepsBn': [
          'bdris.gov.bd ওয়েবসাইটে "জন্ম তথ্য সংশোধন আবেদন" নির্বাচন করে প্রয়োজনীয় তথ্য আপডেট করুন।',
          'প্রমাণের স্বপক্ষে প্রয়োজনীয় কাগজপত্রাদি স্ক্যান করে সিস্টেমে আপলোড করুন।',
          'আবেদন ফরম প্রিন্ট করে সংশ্লিষ্ট নিবন্ধক কার্যালয়ে মূল কাগজপত্রসহ যাচাইয়ের জন্য জমা দিন।',
        ],
        'stepsEn': [
          "Choose 'Birth Information Correction Application' on bdris.gov.bd.",
          'Scan and upload verified supporting proof documents.',
          'Print the application and present it with original documents to the registrar office for verification.',
        ],
      },
    },
    2: {
      'portalUrl': 'https://services.nidw.gov.bd',
      'tipsBn': 'এনআইডি সংশোধনে প্রমাণের ক্ষেত্রে শিক্ষাগত সনদ বা পাসপোর্ট অত্যন্ত নির্ভরযোগ্য প্রমাণ হিসেবে বিবেচিত হয়।',
      'tipsEn': 'Educational board certificates or Passports are considered primary conclusive evidence for NID corrections.',
      'newApplication': {
        'docsBn': [
          '১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন সনদপত্র (ডিজিটাল কপি)',
          'শিক্ষাগত যোগ্যতার সনদপত্র (SSC/HSC বা সমমানের বোর্ড সনদ)',
          'পিতা ও মাতার জাতীয় পরিচয়পত্র (NID) এর ফটোকপি',
          'নাগরিকত্ব সনদপত্র / চেয়ারম্যান প্রত্যয়নপত্র',
          'বিদ্যুৎ বিল / পানির বিল / হোল্ডিং ট্যাক্সের রসিদ (ঠিকানার প্রমাণ হিসেবে)',
        ],
        'docsEn': [
          '17-digit verified online birth registration certificate',
          'Educational qualification certificates (SSC/HSC/equivalent board cert)',
          "Photocopy of parents' National ID cards",
          'Citizenship certificate from local Ward Councilor / Chairman',
          'Utility bill copy (electricity/water) or holding tax slip as residence proof',
        ],
        'stepsBn': [
          'services.nidw.gov.bd ওয়েবসাইটে নতুন ভোটার নিবন্ধনের অনলাইন ফর্ম পূরণ করুন।',
          'ফরম প্রিন্ট করে প্রয়োজনীয় কাগজপত্রসহ নিকটস্থ উপজেলা/থানা নির্বাচন অফিসে বায়োমেট্রিক ও ছবি প্রদান করুন।',
          'নির্বাচন কমিশন থেকে যাচাই ও অনুমোদন শেষে অনলাইন থেকে স্মার্ট/ডিজিটাল এনআইডি ডাউনলোড করুন।',
        ],
        'stepsEn': [
          'Fill out the new voter registration form on services.nidw.gov.bd.',
          'Print the form and visit your Upazila/Thana Election Office for biometric scanning and photograph.',
          'Upon verification and approval, log into the portal to download your digital NID.',
        ],
      },
      'correction': {
        'docsBn': [
          'বিদ্যমান মূল এনআইডি কার্ড / ডিজিটাল কপি',
          'নাম বা বয়স সংশোধনে: এসএসসি/বোর্ড সনদপত্র অথবা পাসপোর্ট/ড্রাইভিং লাইসেন্স',
          'বৈবাহিক অবস্থা সংশোধনে: নিকাহনামা / তালাকনামা / ম্যারিজ সার্টিফিকেট',
          'প্রযোজ্য সরকারি ফি (বিকাশ/রকেট/নগদ এর মাধ্যমে চালান কোডে প্রদেয়)',
        ],
        'docsEn': [
          'Current original National ID card / digital copy',
          'For Name/DOB change: SSC or board certificate, Passport, or Driving License',
          'For Marital status: Nikahnama / Marriage certificate or Divorce deed',
          'Government amendment fee payment slip (via bKash, Rocket, or Nagad)',
        ],
        'stepsBn': [
          'services.nidw.gov.bd এ নিজস্ব প্রোফাইলে লগইন করে "তথ্য সংশোধন" অপশন বেছে নিন।',
          'নির্ধারিত ফি মোবাইল ব্যাংকিংয়ের মাধ্যমে পরিশোধ করে সঠিক তথ্য এন্ট্রি করুন।',
          'সংশোধনের সপক্ষে নথিপত্র আপলোড করে সাবমিট করুন এবং অনুমোদন শেষে সংশোধিত এনআইডি ডাউনলোড করুন।',
        ],
        'stepsEn': [
          "Log in to your citizen profile at services.nidw.gov.bd and navigate to 'Information Correction'.",
          'Pay the required government amendment fee through mobile banking.',
          'Upload verified supporting documents, submit the request, and download the revised NID after approval.',
        ],
      },
    },
    3: {
      'portalUrl': 'https://epassport.gov.bd',
      'tipsBn': 'পাসপোর্ট আবেদনের তথ্য যেন অবশ্যই আপনার এনআইডি বা জন্ম নিবন্ধনের সাথে শতভাগ মিল থাকে।',
      'tipsEn': 'Ensure all personal details strictly match your National ID or 17-digit online birth certificate.',
      'newApplication': {
        'docsBn': [
          'জাতীয় পরিচয়পত্র (NID) মূল ও ফটোকপি (প্রাপ্তবয়স্কদের জন্য) অথবা ১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন (অপ্রাপ্তবয়স্কদের জন্য)',
          'আবেদন সারাংশ প্রিন্ট কপি (Application Summary with Barcode)',
          'ব্যাংকে বা অনলাইনে এ-চালান (A-Challan) এর মাধ্যমে পাসপোর্ট ফি জমার রশিদ',
          'সরকারি চাকরিজীবী হলে জিও (GO) / এনওসি (NOC) কপি',
        ],
        'docsEn': [
          'Original NID and photocopy (for adults) or 17-digit online birth certificate (for minors)',
          'Online application summary with barcode',
          'Passport fee payment receipt through A-Challan or accredited bank',
          'Government Order (GO) / NOC (if government employee)',
        ],
        'stepsBn': [
          'epassport.gov.bd পোর্টালে গিয়ে ই-পাসপোর্টের অনলাইন আবেদন সম্পূর্ণ করুন।',
          'নির্ধারিত ব্যাংকে বা এ-চালানে সরকারি ফি পরিশোধ করে সময়সূচি নির্ধারণ করুন।',
          'নির্দিষ্ট তারিখে আঞ্চলিক পাসপোর্ট অফিসে গিয়ে বায়োমেট্রিক ও ছবি প্রদান করে ডেলিভারি স্লিপ নিন।',
        ],
        'stepsEn': [
          'Complete the online e-Passport application at epassport.gov.bd.',
          'Pay the designated passport fees via A-Challan / online banking and select an appointment date.',
          'Visit your Regional Passport Office with documents for biometric capture, photo, and collect the delivery slip.',
        ],
      },
      'correction': {
        'docsBn': [
          'পূর্ববর্তী মূল পাসপোর্ট ও ডেটা পেইজের ফটোকপি',
          'জাতীয় পরিচয়পত্র (NID) এর ফটোকপি',
          'তথ্য পরিবর্তনের সপক্ষে সরকারি গ্যাজেট বিজ্ঞপ্তি / আদালতের হলফনামা / নিকাহনামা (প্রযোজ্য ক্ষেত্রে)',
          'পাসপোর্ট নবায়ন/রি-ইস্যু ফি প্রদানের রশিদ',
        ],
        'docsEn': [
          'Previous original passport and photocopy of data pages',
          'National ID card photocopy',
          'Official government gazette / court affidavit / marriage certificate (if modifying major details)',
          'Re-issue / renewal fee payment receipt',
        ],
        'stepsBn': [
          'epassport.gov.bd ওয়েবসাইটে "রি-ইস্যু / নবায়ন" অপশন বেছে নিয়ে তথ্য পূরণ করুন।',
          'সরকারি রি-ইস্যু ফি পরিশোধ করে অ্যাপয়েন্টমেন্ট তারিখ নিন।',
          'পূর্বের পাসপোর্ট ও প্রয়োজনীয় প্রমাণপত্রসহ পাসপোর্ট অফিসে যাচাই শেষ করে ডেলিভারি নিন।',
        ],
        'stepsEn': [
          "Select 'Passport Re-issue / Renewal' on epassport.gov.bd and enter details.",
          'Pay the re-issue fee and book your appointment slot.',
          'Submit your old passport and supporting documents at the passport office for verification.',
        ],
      },
    },
    4: {
      'portalUrl': 'https://mutation.land.gov.bd',
      'tipsBn': 'নামজারির শুনানিতে মূল দলিলের সকল মূল কপি সাথে নিয়ে উপস্থিত থাকতে হবে।',
      'tipsEn': 'All original title deeds must be produced physically before the Assistant Commissioner (Land) during hearings.',
      'newApplication': {
        'docsBn': [
          'মূল রেজিস্ট্রার্ড দলিলের কপি (সাব-কবলা / হেবা / বণ্টননামা ইত্যাদি)',
          'সংশ্লিষ্ট খতিয়ানের কপি (CS, SA, RS বা সিটি জরিপ খতিয়ান)',
          'হালনাগাদ ভূমি উন্নয়ন কর (খাজনা) পরিশোধের দাখিলা',
          'ওয়ারিশান সনদ (ওয়ারিশসূত্রে মালিকানা হলে) ও আবেদনকারীর এনআইডি কপি',
        ],
        'docsEn': [
          'Registered deed copy (Sub-Kabala, Heba, Deed of Partition, etc.)',
          'Relevant Khatian records (CS, SA, RS, or City Survey Khatian)',
          'Up-to-date land development tax (Khajna) payment receipt',
          "Succession certificate (Warishan Sanad, if inherited) & applicant's NID",
        ],
        'stepsBn': [
          'mutation.land.gov.bd পোর্টালে নাগরিক হিসেবে অ্যাকাউন্ট খুলে নামজারি আবেদন করুন।',
          'কোর্ট ফি ও নোটিশ জারি ফি (৭০ টাকা) অনলাইনে পরিশোধ করুন।',
          'এসি ল্যান্ড (AC Land) শুনানিতে মূল দলিল প্রদর্শন করুন এবং ডিসিআর ও নতুন খতিয়ান ফি প্রদান করে খতিয়ান সংগ্রহ করুন।',
        ],
        'stepsEn': [
          'Open a citizen account at mutation.land.gov.bd and file the mutation request.',
          'Pay initial court and notice service fees (BDT 70) online.',
          'Attend the Assistant Commissioner (Land) hearing with original deeds and pay the DCR fee to receive the final Khatian.',
        ],
      },
      'correction': {
        'docsBn': [
          'বিদ্যমান ভুল নামজারি খতিয়ানের কপি ও ডিসিআর রশিদ',
          'মূল মালিকানা ও স্বত্ব প্রমাণকারী দলিল',
          'সংশ্লিষ্ট এলাকার মাঠ পর্চা / সিএস-আরএস খতিয়ান কপি',
          'আবেদনকারীর এনআইডি ও সংশোধনীর যৌক্তিক বিবরণী',
        ],
        'docsEn': [
          'Copy of existing erroneous mutation Khatian and DCR receipt',
          'Original title deeds confirming authentic land ownership',
          'Relevant Mauza map / CS-RS Khatian records demonstrating clerical error',
          "Applicant's NID and formal petition detailing requested correction",
        ],
        'stepsBn': [
          'সহকারী কমিশনার (ভূমি) বরাবর নামজারি সংশোধনের জন্য মিস কেস (Mis-case) আবেদন দায়ের করুন।',
          'ইউনিয়ন ভূমি সহকারী কর্মকর্তার তদন্ত প্রতিবেদন সাপেক্ষে শুনানির তারিখ গ্রহণ করুন।',
          'শুনানিতে সমস্ত সঠিক রেকর্ড প্রদর্শন করে সংশোধিত নামজারি খতিয়ান অনুমোদন করান।',
        ],
        'stepsEn': [
          'File a Miss-case (amendment petition) with the Assistant Commissioner (Land) office.',
          'Receive the field investigation report and official hearing date from the Union Land Office.',
          'Present all primary authentic deeds during the hearing to approve the corrected mutation record.',
        ],
      },
    },
    5: {
      'portalUrl': 'https://etradelicense.gov.bd',
      'tipsBn': 'ব্যবসা শুরু করার পূর্বে ট্রেড লাইসেন্স সংগ্রহ করা আইনত বাধ্যতামূলক।',
      'tipsEn': 'Obtaining a trade license is legally mandatory prior to initiating commercial business operations.',
      'newApplication': {
        'docsBn': [
          'ব্যবসায়ী প্রতিষ্ঠানের ভাড়ার চুক্তিপত্র অথবা নিজস্ব জায়গার হোল্ডিং ট্যাক্স রশিদ',
          'আবেদনকারী/স্বত্বাধিকারীর জাতীয় পরিচয়পত্র (NID) ও পাসপোর্ট সাইজ ছবি',
          'অংশীদারি ব্যবসার ক্ষেত্রে পার্টনারশিপ ডিড (Partnership Deed)',
          'লিমিটেড কোম্পানির ক্ষেত্রে মেমোরেন্ডাম অব আর্টিকেলস (MoA) ও ইনকর্পোরেশন সনদ',
        ],
        'docsEn': [
          'Rental agreement of business premises or holding tax slip of owned property',
          "Applicant/owner's National ID copy and passport-sized photographs",
          'Partnership deed (for partnership business entities)',
          'Memorandum of Association (MoA) & Certificate of Incorporation (for limited companies)',
        ],
        'stepsBn': [
          'সিটি কর্পোরেশন / পৌরসভা / ইউনিয়ন পরিষদের ই-ট্রেড লাইসেন্স পোর্টালে আবেদন ফর্ম পূরণ করুন।',
          'প্রয়োজনীয় কাগজপত্র ও প্রতিষ্ঠানের সাইনবোর্ডের ছবি আপলোড করুন।',
          'ট্রেড লাইসেন্স ফি ও সাইনবোর্ড ট্যাক্স পরিশোধ করে তাৎক্ষণিক ডিজিটাল লাইসেন্স ডাউনলোড করুন।',
        ],
        'stepsEn': [
          'Fill out the online application on the local City Corporation / Pourashava / UP e-Trade License portal.',
          'Upload tenant agreement, NID, and signage photograph.',
          'Pay the prescribed trade license fees and tax online to instantly download the validated digital license.',
        ],
      },
      'correction': {
        'docsBn': [
          'পূর্ববর্তী বছরের মূল ট্রেড লাইসেন্স কপি ও ফি জমার রশিদ',
          'হালনাগাদ ভাড়ার চুক্তিপত্র / পৌর কর বা হোল্ডিং ট্যাক্স রশিদ',
          'নাম, মালিকানা বা ঠিকানা পরিবর্তনের ক্ষেত্রে রেজিস্টার্ড এফিডেভিট / সংবিধিবদ্ধ দলিল',
        ],
        'docsEn': [
          "Previous year's original Trade License and challan receipt",
          'Updated rental agreement / local holding tax receipt',
          'Registered affidavit or amended company deed (if changing business name, owner, or premises)',
        ],
        'stepsBn': [
          'অনলাইন পোর্টালে বিদ্যমান ট্রেড লাইসেন্স নম্বর দিয়ে "নবায়ন/সংশোধন" অপশন বেছে নিন।',
          'পরিবর্তিত তথ্য প্রদান করে প্রমাণপত্র আপলোড করুন।',
          'নবায়ন ফি পরিশোধ করে হালনাগাদ ট্রেড লাইসেন্স গ্রহণ করুন।',
        ],
        'stepsEn': [
          "Enter your existing Trade License number on the online portal and select 'Renew/Amend'.",
          'Input amended data and upload corresponding supporting documentation.',
          'Pay the annual renewal fee and download the newly renewed license.',
        ],
      },
    },
    6: {
      'portalUrl': 'https://bdris.gov.bd',
      'tipsBn': 'মৃত্যুর ৪৫ দিনের মধ্যে মৃত্যু নিবন্ধন করালে সরকারি কোনো বিলম্ব ফি লাগে না।',
      'tipsEn': 'Registering death within 45 days of occurrence incurs zero delay penalties.',
      'newApplication': {
        'docsBn': [
          'রেজিস্টার্ড ডাক্তার বা হাসপাতালের অফিসিয়াল ডেথ সার্টিফিকেট (মৃত্যু সনদ)',
          'মৃত ব্যক্তির মূল জাতীয় পরিচয়পত্র (NID) অথবা অনলাইন জন্ম নিবন্ধন সনদ',
          'কবরস্থান বা শ্মশান কমিটি কর্তৃক প্রদত্ত দাফন/সৎকার প্রত্যয়নপত্র',
          'আবেদনকারীর (ওয়ারিশের) এনআইডি ও সম্পর্ক প্রমাণের ওয়ারিশান প্রত্যয়ন',
        ],
        'docsEn': [
          'Registered medical practitioner or hospital official death certificate',
          "Deceased person's National ID card or online birth registration certificate",
          'Burial / cremation confirmation certificate from cemetery or crematorium authority',
          "Applicant's (heir's) NID and relationship proof / inheritance certificate",
        ],
        'stepsBn': [
          'bdris.gov.bd পোর্টালে গিয়ে মৃত্যু নিবন্ধনের আবেদন ফর্মটি পূরণ করুন।',
          'আবেদনপত্র প্রিন্ট করে চিকিৎসকের সনদ ও আবেদনকারীর প্রমাণপত্র সংযুক্ত করুন।',
          'স্থানীয় ইউনিয়ন পরিষদ / পৌরসভা / সিটি কর্পোরেশন কার্যালয়ে জমা দিয়ে সরকারি মৃত্যু সনদ গ্রহণ করুন।',
        ],
        'stepsEn': [
          'Complete the online death registration application form at bdris.gov.bd.',
          'Print the form and attach medical death verification and identity documents.',
          'Submit to the local Union Parishad / Municipality / City Corporation office to obtain the official certificate.',
        ],
      },
      'correction': {
        'docsBn': [
          'বিদ্যমান মূল মৃত্যু নিবন্ধন সনদপত্র',
          'সংশোধনের সপক্ষে অফিসিয়াল মেডিকেল রেকর্ড অথবা স্থানীয় চেয়ারম্যানের সংশোধনী প্রত্যয়ন',
          'আবেদনকারী বৈধ উত্তরাধিকারীর জাতীয় পরিচয়পত্র',
        ],
        'docsEn': [
          'Existing issued death registration certificate',
          "Official medical records or Chairman's affidavit validating the typographical/clerical correction",
          "Valid legal heir's National ID",
        ],
        'stepsBn': [
          'bdris.gov.bd ওয়েবসাইটে "মৃত্যু নিবন্ধন তথ্য সংশোধন" অপশনে গিয়ে ফর্ম পূরণ করুন।',
          'সঠিক তথ্যের সপক্ষে প্রমাণাদি আপলোড করুন।',
          'প্রিন্ট কপি ও মূল কাগজপত্র নিয়ে নিবন্ধক কার্যালয়ে উপস্থিত হয়ে সংশোধিত সনদ সংগ্রহ করুন।',
        ],
        'stepsEn': [
          "Go to bdris.gov.bd and choose 'Death Registration Information Correction'.",
          'Upload supporting documentation for the corrected fields.',
          'Submit printed form and original records to the registrar office to collect the amended certificate.',
        ],
      },
    },
    7: {
      'portalUrl': 'https://bsp.brta.gov.bd',
      'tipsBn': 'বিআরটিএ লার্নার কার্ড সংগ্রহের পর নির্দিষ্ট মেয়াদ শেষে ব্যবহারিক ড্রাইভিং পরীক্ষায় অংশ নিতে হয়।',
      'tipsEn': 'After receiving your BRTA learner card, appear for the scheduled practical driving test.',
      'newApplication': {
        'docsBn': [
          'রেজিস্টার্ড ডাক্তারের নিকট থেকে নির্ধারিত ফরম্যাটে মেডিকেল ফিটনেস সার্টিফিকেট',
          'জাতীয় পরিচয়পত্র (NID) এর সত্যায়িত ফটোকপি',
          'ন্যূনতম শিক্ষাগত যোগ্যতার সনদপত্র (কমপক্ষে ৮ম শ্রেণী বা জেএসসি/সমমান)',
          'সাম্প্রতিক পাসপোর্ট সাইজ ছবি ও ইউটিলিটি বিলের কপি',
        ],
        'docsEn': [
          "Registered physician's medical fitness certificate on standard BRTA format",
          'Attested photocopy of National ID card',
          'Minimum educational qualification certificate (at least 8th grade / JSC / equivalent)',
          'Recent passport-sized color photographs & utility bill copy',
        ],
        'stepsBn': [
          'bsp.brta.gov.bd পোর্টালে গিয়ে "শিক্ষানবিস (লার্নার) ড্রাইভিং লাইসেন্স" এর আবেদন করুন ও ফি প্রদান করুন।',
          'নির্ধারিত তারিখে বিআরটিএ টেস্ট ভেন্যুতে লিখিত, মৌখিক ও ফিল্ড টেস্ট পরীক্ষায় অংশ নিন।',
          'পরীক্ষায় উত্তীর্ণ হয়ে স্মার্ট কার্ড লাইসেন্স ফি প্রদান করুন এবং বায়োমেট্রিক দিয়ে লাইসেন্স গ্রহণ করুন।',
        ],
        'stepsEn': [
          'Register at bsp.brta.gov.bd and apply for the Learner Driving License with fee payment.',
          'Appear at the designated BRTA venue for written, oral, and practical field driving examinations.',
          'Upon passing, pay smart card fees, provide biometrics, and receive the digital driving license.',
        ],
      },
      'correction': {
        'docsBn': [
          'বিদ্যমান মূল ড্রাইভিং লাইসেন্স কার্ড ও ফটোকপি',
          'হালনাগাদ মেডিকেল সার্টিফিকেট (ফরম বিআরটিএ নির্ধারিত)',
          'জাতীয় পরিচয়পত্রের ফটোকপি',
          'নাম বা ঠিকানা পরিবর্তনের স্বপক্ষে হলফনামা / ম্যারিজ সার্টিফিকেট / হোল্ডিং ট্যাক্স রশিদ',
          'নবায়ন ফি প্রদানের এ-চালান / ব্যাংক রশিদ',
        ],
        'docsEn': [
          'Existing original driving license smart card and photocopy',
          'Fresh medical fitness certificate from an accredited doctor',
          'National ID card photocopy',
          'Supporting affidavit / marriage deed / utility bill (if updating name or address)',
          'Renewal fee payment challan / transaction slip',
        ],
        'stepsBn': [
          'বিআরটিএ সার্ভিস পোর্টালে (BSP) লগইন করে "লাইসেন্স নবায়ন/সংশোধন" ফর্ম পূরণ করুন।',
          'নির্ধারিত নবায়ন ফি অনলাইনে বা ব্যাংকে পরিশোধ করুন।',
          'বায়োমেট্রিক ও প্রয়োজনীয় নথিপত্র যাচাই শেষে নতুন স্মার্ট কার্ড ড্রাইভিং লাইসেন্স গ্রহণ করুন।',
        ],
        'stepsEn': [
          "Log in to the BRTA Service Portal (BSP) and choose 'License Renewal / Correction'.",
          'Pay the official renewal fee through authorized payment gateways.',
          'Complete biometric re-verification (if required) and obtain the renewed driving license.',
        ],
      },
    },
    8: {
      'portalUrl': 'https://secure.incometax.gov.bd',
      'tipsBn': 'ই-টিআইএন সম্পূর্ণ বিনামূল্যে অনলাইনে তাৎক্ষণিকভাবে পাওয়া যায়। কোনো ফি প্রয়োজন হয় না।',
      'tipsEn': 'e-TIN is completely free of cost and generated instantly online without any service fees.',
      'newApplication': {
        'docsBn': [
          'জাতীয় পরিচয়পত্র (NID) নম্বর ও সঠিক জন্ম তারিখ',
          'সক্রিয় ও নিবন্ধিত ব্যক্তিগত মোবাইল নম্বর (ভেরিফিকেশন OTP এর জন্য)',
          'ব্যবসায়িক টিআইএন হলে হালনাগাদ ট্রেড লাইসেন্স ও কোম্পানির ইনকর্পোরেশন নম্বর',
        ],
        'docsEn': [
          'National ID card number and exact date of birth',
          'Active personal mobile number for one-time password (OTP) verification',
          'Up-to-date trade license and registration details (for commercial entities)',
        ],
        'stepsBn': [
          'secure.incometax.gov.bd পোর্টালে গিয়ে "Register" বাটনে ক্লিক করে অ্যাকাউন্ট খুলুন।',
          'করদাতার ধরন ও এনআইডি নম্বর ইনপুট দিয়ে তাৎক্ষণিক তথ্য যাচাই করুন।',
          'সম্পূর্ণ বিনামূল্যে কোনো সরকারি ফি ছাড়াই ১২ ডিজিটের ই-টিআইএন সার্টিফিকেট ডাউনলোড ও প্রিন্ট করুন।',
        ],
        'stepsEn': [
          "Visit secure.incometax.gov.bd and click 'Register' to create a taxpayer account.",
          'Input taxpayer classification, purpose, and NID for instant automated database verification.',
          'Instantly download and print the official 12-digit e-TIN certificate (completely free of cost).',
        ],
      },
      'correction': {
        'docsBn': [
          'বিদ্যমান ই-টিআইএন সনদের কপি বা ১২ ডিজিটের টিআইএন নম্বর',
          'সংশোধিত জাতীয় পরিচয়পত্র (NID) কপি',
          'কর অঞ্চলের উপ-কর কমিশনার (DCT) বরাবর লিখিত সংশোধনী দরখাস্ত (গুরুতর পরিবর্তনের ক্ষেত্রে)',
        ],
        'docsEn': [
          'Current 12-digit TIN number or old certificate copy',
          'Updated National ID card copy',
          'Written petition addressed to Deputy Commissioner of Taxes (DCT) for formal amendments',
        ],
        'stepsBn': [
          'secure.incometax.gov.bd পোর্টালে পূর্বের ইউজার আইডি ও পাসওয়ার্ড দিয়ে লগইন করুন।',
          '"View/Print Certificate" থেকে সরাসরি পুনরায় সার্টিফিকেট ডাউনলোড করুন।',
          'নাম বা তথ্য পরিবর্তনের জন্য এনআইডি ডাটাবেজ আপডেট হওয়ার পর পোর্টালে স্বয়ংক্রিয় রিফ্রেশ অথবা সংশ্লিষ্ট কর সার্কেলে আবেদন জমা দিন।',
        ],
        'stepsEn': [
          'Log in with your registered username and password at secure.incometax.gov.bd.',
          "Choose 'View/Print Certificate' to immediately reprint a lost certificate.",
          'If amending personal details, sync with the updated NID registry or submit a request to your assigned tax circle.',
        ],
      },
    },
  };

  Future<void> _launchPortalUrl(BuildContext context, String urlString) async {
    final s = context.read<AuthProvider>().s;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(urlString);

    // Auto copy link to clipboard for convenience
    try {
      await Clipboard.setData(ClipboardData(text: urlString));
    } catch (_) {}

    bool launched = false;
    if (uri != null) {
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              launched ? Icons.open_in_browser : Icons.content_copy,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                launched ? s.openingPortal : s.linkCopied,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006A4E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AuthProvider>().s;
    final bn = widget.isBn;
    final svc = widget.svc;
    final svcId = (svc['id'] is int) ? svc['id'] as int : int.tryParse(svc['id']?.toString() ?? '1') ?? 1;

    final serviceName = bn ? (svc['nameBn'] ?? '') : (svc['nameEn'] ?? '');
    final categoryName = bn ? (svc['categoryNameBn'] ?? '') : (svc['categoryNameEn'] ?? '');
    final description = bn ? (svc['descriptionBn'] ?? '') : (svc['descriptionEn'] ?? '');

    // Extract guidelines from API payload or fallback to local knowledge base
    final apiGuidelines = svc['guidelines'] as Map<String, dynamic>?;
    final localGuide = _localGuidelines[svcId] ?? _localGuidelines[1]!;

    final portalUrl = svc['portalUrl']?.toString().isNotEmpty == true
        ? svc['portalUrl'].toString()
        : localGuide['portalUrl'].toString();

    final tips = bn
        ? (svc['tipsBn']?.toString().isNotEmpty == true ? svc['tipsBn'].toString() : localGuide['tipsBn'].toString())
        : (svc['tipsEn']?.toString().isNotEmpty == true ? svc['tipsEn'].toString() : localGuide['tipsEn'].toString());

    List<String> docs = [];
    List<String> steps = [];

    if (_selectedTab == 0) {
      // New Application
      if (apiGuidelines?['newApplication'] != null) {
        final newApp = apiGuidelines!['newApplication'] as Map<String, dynamic>;
        final rawDocs = bn ? newApp['requiredDocumentsBn'] : newApp['requiredDocumentsEn'];
        final rawSteps = bn ? newApp['stepsBn'] : newApp['stepsEn'];
        docs = (rawDocs as List? ?? []).map((e) => e.toString()).toList();
        steps = (rawSteps as List? ?? []).map((e) => e.toString()).toList();
      }
      if (docs.isEmpty) {
        final localNewApp = localGuide['newApplication'] as Map<String, dynamic>;
        docs = ((bn ? localNewApp['docsBn'] : localNewApp['docsEn']) as List)
            .map((e) => e.toString())
            .toList();
        steps = ((bn ? localNewApp['stepsBn'] : localNewApp['stepsEn']) as List)
            .map((e) => e.toString())
            .toList();
      }
    } else {
      // Correction & Renewal
      if (apiGuidelines?['correction'] != null) {
        final corr = apiGuidelines!['correction'] as Map<String, dynamic>;
        final rawDocs = bn ? corr['requiredDocumentsBn'] : corr['requiredDocumentsEn'];
        final rawSteps = bn ? corr['stepsBn'] : corr['stepsEn'];
        docs = (rawDocs as List? ?? []).map((e) => e.toString()).toList();
        steps = (rawSteps as List? ?? []).map((e) => e.toString()).toList();
      }
      if (docs.isEmpty) {
        final localCorr = localGuide['correction'] as Map<String, dynamic>;
        docs = ((bn ? localCorr['docsBn'] : localCorr['docsEn']) as List)
            .map((e) => e.toString())
            .toList();
        steps = ((bn ? localCorr['stepsBn'] : localCorr['stepsEn']) as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

          // Header Badge & Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A4E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF006A4E), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      s.serviceGuidelines,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A4E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Identified Service Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF006A4E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006A4E).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.identifiedService,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A4E),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800, height: 1.4),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Interactive Workflow Selector Tabs (New Application vs Correction)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? const Color(0xFF006A4E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF006A4E).withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 16,
                            color: _selectedTab == 0 ? Colors.white : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.newApplicationTab,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 0 ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? const Color(0xFF006A4E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF006A4E).withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 18,
                            color: _selectedTab == 1 ? Colors.white : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.correctionTab,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 1 ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Required Documents Section
          Text(
            s.requiredDocs,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...docs.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF006A4E), size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      doc,
                      style: const TextStyle(fontSize: 13.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Step-by-Step Procedure Section
          Text(
            s.stepsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
            (entry) {
              final idx = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Official Portal & Important Tips Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.public, color: Colors.amber.shade900, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      s.officialPortal,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Clickable Official Website Tile
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _launchPortalUrl(context, portalUrl),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF006A4E).withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: Color(0xFF006A4E), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  portalUrl,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006A4E),
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.tapForFullGuidance,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006A4E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _launchPortalUrl(context, portalUrl),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: Text(
                              s.visitPortal,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade900, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tips,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Close Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A4E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(s.close, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
