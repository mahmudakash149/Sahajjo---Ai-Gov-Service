import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final s = context.read<AuthProvider>().s;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bn ? svc['nameBn'] : svc['nameEn'], style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${s.category}: ${bn ? svc['categoryNameBn'] : svc['categoryNameEn']}',
                style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(bn ? svc['descriptionBn'] : svc['descriptionEn']),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.close)),
            ),
          ],
        ),
      ),
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
