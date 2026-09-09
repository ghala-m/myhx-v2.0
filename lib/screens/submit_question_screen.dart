import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/departments.dart';
import '../models/question_suggestion.dart';
import '../services/question_suggestion_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/english_input.dart';
import '../utils/locale_provider.dart';
import '../widgets/app_card.dart';

/// A student can propose a structured question, or paste a free-form
/// "notebook" note for a developer to turn into one or more questions —
/// instead of being limited to whatever's already in the question bank.
class SubmitQuestionScreen extends StatefulWidget {
  const SubmitQuestionScreen({super.key});

  @override
  State<SubmitQuestionScreen> createState() => _SubmitQuestionScreenState();
}

class _SubmitQuestionScreenState extends State<SubmitQuestionScreen>
    with SingleTickerProviderStateMixin {
  final _service = QuestionSuggestionService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arabic = context.watch<LocaleProvider>().isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(arabic ? 'اقترح سؤالًا' : 'Suggest a question'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: arabic ? 'إرسال جديد' : 'New submission'),
            Tab(text: arabic ? 'مقترحاتي' : 'My submissions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SubmitForm(service: _service, arabic: arabic),
          _MySubmissions(service: _service, arabic: arabic),
        ],
      ),
    );
  }
}

class _SubmitForm extends StatefulWidget {
  const _SubmitForm({required this.service, required this.arabic});

  final QuestionSuggestionService service;
  final bool arabic;

  @override
  State<_SubmitForm> createState() => _SubmitFormState();
}

class _SubmitFormState extends State<_SubmitForm> {
  bool _isNotebook = false;
  String _departmentId = Departments.all.first.id;
  final _en = TextEditingController();
  final _ar = TextEditingController();
  final _options = TextEditingController();
  final _notebook = TextEditingController();
  String _type = 'text';
  bool _critical = false;
  bool _submitting = false;

  @override
  void dispose() {
    _en.dispose();
    _ar.dispose();
    _options.dispose();
    _notebook.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_isNotebook && _en.text.trim().isEmpty) return;
    if (_isNotebook && _notebook.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      await widget.service.submit(QuestionSuggestion(
        id: '',
        submittedBy: user.uid,
        submittedByName: user.displayName ?? 'Student',
        department: _departmentId,
        type: _isNotebook ? 'notebook' : 'question',
        status: 'pending',
        en: _en.text.trim(),
        ar: _ar.text.trim(),
        questionType: _type,
        options: _type == 'select'
            ? _options.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : const [],
        critical: _critical,
        notebookText: _notebook.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.arabic
              ? 'أُرسل للمراجعة، بينتظر مبرمج التطبيق'
              : 'Submitted for review'),
        ));
        _en.clear();
        _ar.clear();
        _options.clear();
        _notebook.clear();
        setState(() => _critical = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arabic = widget.arabic;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                  value: false,
                  label: Text(arabic ? 'سؤال منظّم' : 'Structured question')),
              ButtonSegment(
                  value: true, label: Text(arabic ? 'نوت بوك' : 'Notebook')),
            ],
            selected: {_isNotebook},
            onSelectionChanged: (s) => setState(() => _isNotebook = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _departmentId,
            decoration:
                InputDecoration(labelText: arabic ? 'القسم' : 'Department'),
            items: [
              for (final d in Departments.all)
                DropdownMenuItem(value: d.id, child: Text(d.name(arabic))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _departmentId = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isNotebook) ...[
            Text(
              arabic
                  ? 'الصقي ملاحظاتك أو نوت بوكك هنا؛ المبرمج يحوّلها لأسئلة رسمية لاحقًا.'
                  : 'Paste your notes/notebook here; a developer will turn it into formal questions.',
              style: AppTypography.bodyMedium(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notebook,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. onset, duration, associated symptoms...',
              ),
            ),
          ] else ...[
            TextField(
              controller: _en,
              inputFormatters: EnglishInput.formatters,
              decoration: InputDecoration(
                  labelText:
                      arabic ? 'السؤال (إنجليزي)' : 'Question (English)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _ar,
              decoration: InputDecoration(
                  labelText:
                      arabic ? 'بالعربي (اختياري)' : 'Arabic (optional)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                  labelText: arabic ? 'نوع الإجابة' : 'Answer type'),
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
              title: Text(
                  arabic ? 'سؤال علامة خطر' : 'Critical (red-flag) question'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(arabic ? 'إرسال للمراجعة' : 'Submit for review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MySubmissions extends StatelessWidget {
  const _MySubmissions({required this.service, required this.arabic});

  final QuestionSuggestionService service;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<QuestionSuggestion>>(
      stream: service.mySuggestions(user.uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Text(arabic ? 'لا يوجد شيء بعد' : 'Nothing submitted yet'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final s = items[i];
            final statusColor = switch (s.status) {
              'approved' => Colors.green,
              'rejected' => Theme.of(context).colorScheme.error,
              _ => Colors.orange,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.type == 'notebook'
                                ? (arabic ? 'نوت بوك' : 'Notebook note')
                                : s.en,
                            style: AppTypography.titleMedium(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (s.reviewNote != null && s.reviewNote!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(s.reviewNote!,
                          style: AppTypography.bodyMedium(context)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
