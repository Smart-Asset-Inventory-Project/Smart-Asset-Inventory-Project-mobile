import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/catalog_service.dart';
import '../../core/widgets/role_gate.dart';
import '../../models/category_model.dart';

/// إدارة الفئات: عرض + إضافة (POST /categories).
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<List<CategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = CatalogService().fetchCategories();
  }

  void _reload() =>
      setState(() => _future = CatalogService().fetchCategories());

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'name *')),
            const SizedBox(height: 8),
            TextField(
                controller: codeCtrl,
                decoration:
                    const InputDecoration(labelText: 'code')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
                MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (nameCtrl.text.trim().isEmpty) return;
    try {
      await ApiService.instance.dio.post(
        '/categories',
        data: {
          'name': nameCtrl.text.trim(),
          if (codeCtrl.text.trim().isNotEmpty)
            'code': codeCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        },
      );
      _reload();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AuthService.backendMessage(e, 'Create failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'category'))),
      floatingActionButton: HideForAuditor(
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(tr(context, 'add')),
          onPressed: _add,
        ),
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No categories'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = items[i];
              return Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.folder_outlined, color: Colors.blue),
                  title: Text(c.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(c.code ?? '-'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
