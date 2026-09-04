import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/departments.dart';
import '../data/specialty_templates.dart';
import '../services/feedback_service.dart';
import '../services/question_bank_service.dart';
import '../utils/app_spacing.dart';
import '../utils/english_input.dart';
import '../widgets/app_card.dart';

/// Developer-only editor for the department question banks.
class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _bank = QuestionBankService.instance;

  String _departmentId = Departments.all.first.id;
  bool _loading = true;
  List<TemplateQuestion> _builtIn = [];
  List<TemplateQuestion> _custom = [];
  Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _builtIn = _bank.builtIn(_departmentId);
    try {
      _custom = await _bank.customQuestions(_departmentId);
      _hidden = await _bank.hiddenQuestions(_departmentId);
    } catch (_) {
      _custom = [];
      _hidden = {};
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editQuestion([TemplateQuestion? existing]) async {
    final result = await showModalBottomSheet<TemplateQuestion>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _QuestionForm(question: existing),
    );
    if (result == null) return;
    await _bank.saveCustomQuestion(_departmentId, result);
    if (!mounted) return;
    context.read<FeedbackService>().success();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('Question editor'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editQuestion(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New question'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: const InputDecoration(labelText: 'Department'),
                items: [
                  for (final d in Departments.all)
                    DropdownMenuItem(value: d.id, child: Text(d.nameEn)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _departmentId = v);
                  _load();
                },
              ),
            ),
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, 96),
                  children: [
                    _label('Built-in questions'),
                    for (final q in _builtIn)
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.en,
                                      style: theme.textTheme.bodyLarge),
                                  Text(q.ar,
                                      style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Switch(
                              value: !_hidden.contains(q.id),
                              onChanged: (v) async {
                                await _bank.setHidden(_departmentId, q.id, !v);
                                _load();
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    _label('Custom questions'),
                    if (_custom.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text('No custom questions yet',
                            style: theme.textTheme.bodySmall),
                      ),
                    for (final q in _custom)
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.en,
                                      style: theme.textTheme.bodyLarge),
                                  Text('${q.type}${q.critical ? " · critical" : ""}',
                                      style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () => _editQuestion(q),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () async {
                                await _bank.deleteCustomQuestion(
                                    _departmentId, q.id);
                                _load();
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(text.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(letterSpacing: 1)),
      );
}

class _QuestionForm extends StatefulWidget {
  final TemplateQuestion? question;
  const _QuestionForm({this.question});

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  late final TextEditingController _en =
      TextEditingController(text: widget.question?.en ?? '');
  late final TextEditingController _ar =
      TextEditingController(text: widget.question?.ar ?? '');
  late final TextEditingController _options = TextEditingController(
      text: widget.question?.options.join(', ') ?? '');
  String _type = 'text';
  bool _critical = false;

  @override
  void initState() {
    super.initState();
    _type = widget.question?.type ?? 'text';
    _critical = widget.question?.critical ?? false;
  }

  @override
  void dispose() {
    _en.dispose();
    _ar.dispose();
    _options.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _en,
            inputFormatters: EnglishInput.formatters,
            decoration:
                const InputDecoration(labelText: 'Question (English)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _ar,
            decoration: const InputDecoration(
                labelText: 'Arabic (optional — auto-translated if empty)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Answer type'),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Short text')),
              DropdownMenuItem(value: 'textarea', child: Text('Long text')),
              DropdownMenuItem(value: 'boolean', child: Text('Yes / No')),
              DropdownMenuItem(value: 'select', child: Text('Choice list')),
              DropdownMenuItem(value: 'number', child: Text('Number')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'text'),
          ),
          if (_type == 'select') ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _options,
              decoration: const InputDecoration(
                  labelText: 'Options (comma separated)'),
            ),
          ],
          SwitchListTile(
            value: _critical,
            onChanged: (v) => setState(() => _critical = v),
            title: const Text('Critical (red-flag) question'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final en = _en.text.trim();
                if (en.isEmpty) return;
                Navigator.of(context).pop(
                  TemplateQuestion(
                    id: widget.question?.id ??
                        'custom_${DateTime.now().millisecondsSinceEpoch}',
                    en: en,
                    ar: _ar.text.trim().isEmpty ? en : _ar.text.trim(),
                    type: _type,
                    options: _type == 'select'
                        ? _options.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : const [],
                    critical: _critical,
                  ),
                );
              },
              child: const Text('Save question'),
            ),
          ),
        ],
      ),
    );
  }
}
