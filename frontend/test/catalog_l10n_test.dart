import 'package:flutter_test/flutter_test.dart';
import 'package:sahajjo/l10n/strings.dart';

void main() {
  group('FR2 & FR3 Localization (S) Unit Tests', () {
    test('FR2: Language Selection toggles correctly between Bangla and English', () {
      const bn = S('bn');
      const en = S('en');

      expect(bn.lang, 'bn');
      expect(en.lang, 'en');

      // Verify general app translation
      expect(bn.appName, 'সহজ');
      expect(en.appName, 'Sahajjo');

      expect(bn.language, 'ভাষা');
      expect(en.language, 'Language');
    });

    test('FR3: Service Catalog strings are present and non-empty in Bangla', () {
      const bn = S('bn');

      expect(bn.services, isNotEmpty);
      expect(bn.searchHint, isNotEmpty);
      expect(bn.noServices, isNotEmpty);
      expect(bn.priorityService, isNotEmpty);
      expect(bn.category, isNotEmpty);
      expect(bn.close, isNotEmpty);

      expect(bn.category, 'বিভাগ');
      expect(bn.close, 'বন্ধ করুন');
      expect(bn.newApplicationTab, 'নতুন আবেদন');
      expect(bn.correctionTab, 'তথ্য সংশোধন ও নবায়ন');
      expect(bn.officialPortal, isNotEmpty);
      expect(bn.importantTips, isNotEmpty);
      expect(bn.visitPortal, 'ওয়েবসাইটে যান');
      expect(bn.openingPortal, isNotEmpty);
      expect(bn.linkCopied, isNotEmpty);
    });

    test('FR3: Service Catalog strings are present and non-empty in English', () {
      const en = S('en');

      expect(en.services, 'Service Catalog');
      expect(en.category, 'Category');
      expect(en.close, 'Close');
      expect(en.priorityService, 'Priority service');
      expect(en.noServices, 'No services found.');
      expect(en.newApplicationTab, 'New Application');
      expect(en.correctionTab, 'Correction & Renewal');
      expect(en.officialPortal, isNotEmpty);
      expect(en.importantTips, isNotEmpty);
      expect(en.visitPortal, 'Visit Portal');
      expect(en.openingPortal, isNotEmpty);
      expect(en.linkCopied, isNotEmpty);
    });
  });
}
