import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final s = auth.s;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAccount),
        content: Text(s.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await auth.deleteAccount();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message == 'network' ? s.networkError : e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = auth.s;
    final name = auth.user?['fullName'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'bn' || v == 'en') auth.setLanguage(v);
              if (v == 'delete') _confirmDelete(context);
              if (v == 'logout') auth.logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'bn', child: Text('বাংলা')),
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text(s.deleteAccount)),
              PopupMenuItem(value: 'logout', child: Text(s.logout)),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${s.welcome}, $name', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(s.homePlaceholder, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
