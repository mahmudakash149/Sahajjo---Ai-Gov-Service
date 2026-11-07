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

  // Validation
  String get reqName => _t('নাম লিখুন (কমপক্ষে ২ অক্ষর)', 'Enter your name (min 2 characters)');
  String get badPhone => _t('সঠিক মোবাইল নম্বর দিন (01XXXXXXXXX)', 'Enter a valid mobile number (01XXXXXXXXX)');
  String get badEmail => _t('সঠিক ইমেইল দিন', 'Enter a valid email');
  String get reqField => _t('এই ঘরটি পূরণ করুন', 'This field is required');
  String get pwLength => _t('পাসওয়ার্ড ৮-৭২ অক্ষরের হতে হবে', 'Password must be 8-72 characters');
  String get pwLower => _t('একটি ছোট হাতের অক্ষর দিন', 'Include a lowercase letter');
  String get pwUpper => _t('একটি বড় হাতের অক্ষর দিন', 'Include an uppercase letter');
  String get pwDigit => _t('একটি সংখ্যা দিন', 'Include a digit');
  String get pwMismatch => _t('পাসওয়ার্ড মিলছে না', 'Passwords do not match');
  String get reqConsent => _t('নিবন্ধনের জন্য সম্মতি আবশ্যক', 'Consent is required to register');
}
