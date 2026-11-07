class S {
  final String lang;
  const S(this.lang);

  String _t(String bn, String en) => lang == 'bn' ? bn : en;

  String get appName => _t('সহজ', 'Sahajjo');
  String get tagline => _t('সরকারি সেবা, সহজ নির্দেশনা', 'Government services, made simple');
  String get login => _t('লগইন', 'Login');
  String get register => _t('নিবন্ধন করুন', 'Register');
  String get createAccount => _t('নতুন অ্যাকাউন্ট খুলুন', 'Create an account');
  String get haveAccount => _t('আগে থেকেই অ্যাকাউন্ট আছে? লগইন করুন', 'Already have an account? Login');
  String get noAccount => _t('অ্যাকাউন্ট নেই? নিবন্ধন করুন', "Don't have an account? Register");
  String get fullName => _t('পুরো নাম', 'Full name');
  String get phone => _t('মোবাইল নম্বর', 'Mobile number');
  String get phoneOrEmail => _t('মোবাইল নম্বর বা ইমেইল', 'Mobile number or email');
  String get emailOptional => _t('ইমেইল (ঐচ্ছিক)', 'Email (optional)');
  String get password => _t('পাসওয়ার্ড', 'Password');
  String get confirmPassword => _t('পাসওয়ার্ড নিশ্চিত করুন', 'Confirm password');
  String get consent => _t(
      'আমি সম্মত যে আমার ব্যক্তিগত তথ্য শুধু সেবা প্রদানের জন্য ব্যবহার হবে এবং আমি যেকোনো সময় তা মুছে ফেলতে পারব।',
      'I consent to my personal data being used only to provide this service, and I understand I can delete it at any time.');
  String get welcome => _t('স্বাগতম', 'Welcome');
  String get logout => _t('লগআউট', 'Logout');
  String get deleteAccount => _t('আমার অ্যাকাউন্ট মুছুন', 'Delete my account');
  String get deleteConfirm => _t('আপনার অ্যাকাউন্ট ও সব তথ্য স্থায়ীভাবে মুছে যাবে। নিশ্চিত?', 'Your account and all data will be permanently deleted. Continue?');
  String get cancel => _t('বাতিল', 'Cancel');
  String get delete => _t('মুছুন', 'Delete');
  String get language => _t('ভাষা', 'Language');
  String get networkError => _t('সার্ভারের সাথে সংযোগ করা যায়নি।', 'Could not reach the server.');
  String get homePlaceholder => _t('সেবা তালিকা পরবর্তী ধাপে যুক্ত হবে।', 'Service catalog arrives in the next phase.');

  // Service catalog (FR3)
  String get services => _t('সেবা তালিকা', 'Service Catalog');
  String get searchHint => _t('সেবা খুঁজুন…', 'Search services…');
  String get noServices => _t('কোনো সেবা পাওয়া যায়নি।', 'No services found.');
  String get retry => _t('আবার চেষ্টা করুন', 'Try again');
  String get priorityService => _t('অগ্রাধিকার সেবা', 'Priority service');
  String get category => _t('বিভাগ', 'Category');
  String get close => _t('বন্ধ করুন', 'Close');

  // Service Request Input (FR4)
  String get tabRequest => _t('সহায়তা চান', 'Ask Sahajjo');
  String get tabCatalog => _t('সকল সেবা', 'Service Catalog');
  String get requestHeader => _t('কী সেবা বা সাহায্য প্রয়োজন?', 'What service or help do you need?');
  String get requestSubheader => _t('আপনার প্রয়োজনীয় সেবা সম্পর্কে বাংলায় বা ইংরেজিতে লিখুন', 'Describe the service you need in Bangla or English');
  String get requestHint => _t('যেমন: আমি নতুন পাসপোর্টের আবেদন করতে চাই, কী কী কাগজপত্র লাগবে?', 'e.g., What documents are required to apply for a new passport?');
  String get submitRequest => _t('অনুরোধ পাঠান', 'Submit Request');
  String get submitting => _t('পাঠানো হচ্ছে…', 'Submitting…');
  String get requestSuccess => _t('আপনার অনুরোধ সফলভাবে জমা হয়েছে!', 'Your request has been submitted successfully!');
  String get requestTrackingId => _t('ট্র্যাকিং আইডি:', 'Tracking ID:');
  String get suggestionsTitle => _t('সাধারণ কিছু অনুরোধ (চাপুন):', 'Common requests (tap to use):');
  String get chipPassport => _t('পাসপোর্ট নবায়ন আবেদন', 'Passport renewal');
  String get chipNid => _t('জাতীয় পরিচয়পত্রে নাম সংশোধন', 'NID name correction');
  String get chipTrade => _t('নতুন ট্রেড লাইসেন্স নিবন্ধন', 'New trade license');
  String get chipMutation => _t('জমির ই-নামজারি আবেদন', 'e-Mutation of land');
  String get myRequestsTitle => _t('আমার অনুরোধসমূহ', 'My Requests');
  String get noRequestsYet => _t('এখনো কোনো অনুরোধ জমা দেওয়া হয়নি। উপরের বক্সে লিখে অনুরোধ পাঠান।', 'No requests submitted yet. Type above and submit.');
  String get statusSubmitted => _t('জমা হয়েছে', 'Submitted');
  String get statusUnderReview => _t('পর্যালোচনাধীন', 'Under Review');
  String get statusProcessed => _t('এআই বিশ্লেষিত', 'AI Analyzed');
  String get reqTextMinError => _t('অনুরোধের বিবরণ অন্তত ৩ অক্ষরের হতে হবে', 'Request description must be at least 3 characters');

  // AI Service Identification & Guidelines
  String get aiDiagnosisTitle => _t('এআই সেবা শনাক্তকরণ ও নির্দেশনা', 'AI Service Identification & Guide');
  String get identifiedService => _t('চিহ্নিত সরকারি সেবা:', 'Identified Government Service:');
  String get matchConfidence => _t('মিল', 'match');
  String get requiredDocs => _t('প্রয়োজনীয় কাগজপত্র:', 'Required Documents:');
  String get stepsTitle => _t('পরবর্তী করণীয় ধাপসমূহ:', 'Step-by-Step Procedure:');
  String get aiPoweredBadge => _t('সহায় জেমিনাই এআই দ্বারা বিশ্লেষিত', 'Analyzed by Sahajjo Gemini AI');
  String get tapToViewGuidance => _t('এআই নির্দেশনা দেখতে ট্যাপ করুন', 'Tap to view AI guidance');

  // Validation
  String get reqName => _t('নাম লিখুন (কমপক্ষে ২ অক্ষর)', 'Enter your name (min 2 characters)');
  String get badPhone => _t('সঠিক মোবাইল নম্বর দিন (01XXXXXXXXX)', 'Enter a valid mobile number (01XXXXXXXXX)');
  String get badEmail => _t('সঠিক ইমেইল দিন', 'Enter a valid email');
  String get reqField => _t('এই ঘরটি পূরণ করুন', 'This field is required');
  String get pwLength => _t('পাসওয়ার্ড ৮-৭২ অক্ষরের হতে হবে', 'Password must be 8-72 characters');
  String get pwLower => _t('একটি ছোট হাতের অক্ষর দিন (a-z)', 'Include a lowercase letter (a-z)');
  String get pwUpper => _t('একটি বড় হাতের অক্ষর দিন (A-Z)', 'Include an uppercase letter (A-Z)');
  String get pwDigit => _t('একটি সংখ্যা দিন (0-9)', 'Include a digit (0-9)');
  String get pwSpecial => _t(r'একটি বিশেষ চিহ্ন দিন (!@#$%^&*)', r'Include a special character (!@#$%^&*)');
  String get pwMismatch => _t('পাসওয়ার্ড মিলছে না', 'Passwords do not match');
  String get reqConsent => _t('নিবন্ধনের জন্য সম্মতি আবশ্যক', 'Consent is required to register');

  // Password Checklist
  String get pwReqTitle => _t('পাসওয়ার্ডের প্রয়োজনীয় শর্তসমূহ:', 'Password requirements:');
  String get pwReqLength => _t('কমপক্ষে ৮টি অক্ষর', 'At least 8 characters');
  String get pwReqUpper => _t('অন্তত ১টি বড় হাতের অক্ষর (A-Z)', 'At least one uppercase letter (A-Z)');
  String get pwReqLower => _t('অন্তত ১টি ছোট হাতের অক্ষর (a-z)', 'At least one lowercase letter (a-z)');
  String get pwReqDigit => _t('অন্তত ১টি সংখ্যা (০-৯)', 'At least one number (0-9)');
  String get pwReqSpecial => _t(r'অন্তত ১টি বিশেষ চিহ্ন (!@#$%^&*)', r'At least one special character (!@#$%^&*)');

  // OTP Login Strings
  String get otpTitle => _t('ওটিপি যাচাইকরণ', 'OTP Verification');
  String get otpSubtitle => _t('নিরাপদ কোড দিয়ে সরাসরি সাইন ইন করুন', 'Sign in securely with a one-time code');
  String get enterOtp => _t('৬-সংখ্যার ওটিপি কোড দিন', 'Enter 6-digit OTP code');
  String get otpSentTo => _t('এই নম্বরে ওটিপি পাঠানো হয়েছে:', 'Code has been sent to:');
  String get sendOtp => _t('ওটিপি পাঠান', 'Send OTP');
  String get verifyAndLogin => _t('যাচাই করুন ও লগইন করুন', 'Verify & Login');
  String get resendOtp => _t('পুনরায় কোড পাঠান', 'Resend code');
  String get resendIn => _t('পুনরায় পাঠানো যাবে:', 'Resend in:');
  String get changePhone => _t('নম্বর পরিবর্তন', 'Change number');
  String get demoNotice => _t('ডেমো ওটিপি কোড (স্বয়ংক্রিয় পূরণ করতে চাপুন):', 'Demo OTP Code (Tap to autofill):');
}
