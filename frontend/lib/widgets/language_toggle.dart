import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'bn', label: Text('বাংলা')),
        ButtonSegment(value: 'en', label: Text('English')),
      ],
      selected: {auth.lang},
      onSelectionChanged: (v) => auth.setLanguage(v.first),
      showSelectedIcon: false,
    );
  }
}
