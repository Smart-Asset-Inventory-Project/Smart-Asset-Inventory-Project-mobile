import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/user_directory.dart';
import '../../core/services/work_order_service.dart';
import '../../core/theme/app_colors.dart';

/// AST-FR-06: إنشاء أمر شغل جديد مع الأولوية، الفني، الجدولة والملاحظات.
class CreateWorkOrderPage extends StatefulWidget {
  final String? presetAssetId;
  final String? presetAssetTag;
  final String? initialNotes;

  const CreateWorkOrderPage({
    super.key,
    this.presetAssetId,
    this.presetAssetTag,
    this.initialNotes,
  });

  @override
  State<CreateWorkOrderPage> createState() => _CreateWorkOrderPageState();
}

class _CreateWorkOrderPageState extends State<CreateWorkOrderPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _assetCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _technician;

  String _priority = 'medium';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _technician = TextEditingController();
    _assetCtrl = TextEditingController(
      text: widget.presetAssetTag ?? widget.presetAssetId ?? '',
    );
    _notesCtrl = TextEditingController(text: widget.initialNotes ?? '');
    _dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _technician.dispose();
    _assetCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateCtrl.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await WorkOrderService().createWorkOrder({
        'title': _titleCtrl.text.trim(),
        'assetId': _assetCtrl.text.trim(),
        'priority': _priority.toUpperCase(),
        if (_technician.text.trim().isNotEmpty)
          'assignedToUserId': _technician.text.trim(),
        'dueDate': _dateCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty)
          'description': _notesCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'createOrderSuccess'))),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'createWorkOrder')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title (required by backend)
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'title *',
                prefixIcon: const Icon(Icons.title_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? tr(context, 'required') : null,
            ),
            const SizedBox(height: 16),

            // Asset ID or Tag
            TextFormField(
              controller: _assetCtrl,
              decoration: InputDecoration(
                labelText: '${tr(context, 'assetIdTag')} *',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? tr(context, 'required') : null,
            ),
            const SizedBox(height: 16),

            // Priority Selection
            Text(
              tr(context, 'selectPriority'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;
                final color = p == 'high'
                    ? AppColors.red
                    : p == 'medium'
                        ? AppColors.orange
                        : AppColors.blue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          tr(context, p),
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Technician: من الدليل أو ID يدوي (لا /users في الباك)
            Builder(builder: (context) {
              final known = UserDirectory.instance.all;
              if (known.isEmpty) {
                return TextFormField(
                  controller: _technician,
                  decoration: InputDecoration(
                    labelText: tr(context, 'selectTechnician'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                );
              }
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: tr(context, 'selectTechnician'),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('-')),
                  ...known.map((u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(u.name,
                          overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => _technician.text = v ?? '',
              );
            }),
            const SizedBox(height: 16),

            // Scheduled Date
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: tr(context, 'scheduledDate'),
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: _pickDate,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Notes / Checklist
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: tr(context, 'notes'),
                hintText: 'e.g. Clean fans, update antivirus, verify disk...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        tr(context, 'createWorkOrder'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
