import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

/// Renders a single dynamic medical-history question.
class DynamicQuestionWidget extends StatefulWidget {
  final EnhancedQuestion question;
  final dynamic answer;
  final Function(dynamic) onAnswerChanged;

  const DynamicQuestionWidget({
    super.key,
    required this.question,
    this.answer,
    required this.onAnswerChanged,
  });

  @override
  State<DynamicQuestionWidget> createState() => _DynamicQuestionWidgetState();
}

class _DynamicQuestionWidgetState extends State<DynamicQuestionWidget> {
  late TextEditingController _textController;
  dynamic _currentAnswer;

  @override
  void initState() {
    super.initState();
    _currentAnswer = widget.answer;
    _textController = TextEditingController(text: widget.answer?.toString() ?? '');
  }

  @override
  void didUpdateWidget(DynamicQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer) {
      _currentAnswer = widget.answer;
      _textController.text = widget.answer?.toString() ?? '';
    }
  }

  void _updateAnswer(dynamic answer) {
    setState(() => _currentAnswer = answer);
    widget.onAnswerChanged(answer);
  }

  Color _getPriorityColor() {
    switch (widget.question.priority) {
      case QuestionPriority.critical:
        return AppColors.error;
      case QuestionPriority.important:
        return AppColors.warning;
      case QuestionPriority.detailed:
        return AppColors.info;
      case QuestionPriority.optional:
        return AppColors.onSurfaceVariant;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData _getPriorityIcon() {
    switch (widget.question.priority) {
      case QuestionPriority.critical:
        return Icons.priority_high_rounded;
      case QuestionPriority.important:
        return Icons.info_outline_rounded;
      case QuestionPriority.detailed:
        return Icons.list_rounded;
      case QuestionPriority.optional:
        return Icons.help_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getPriorityLabel() {
    switch (widget.question.priority) {
      case QuestionPriority.critical:
        return 'Critical';
      case QuestionPriority.important:
        return 'Important';
      case QuestionPriority.detailed:
        return 'Detailed';
      case QuestionPriority.optional:
        return 'Optional';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _getPriorityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getPriorityIcon(), size: 14, color: priorityColor),
                    const SizedBox(width: 6),
                    Text(
                      _getPriorityLabel(),
                      style: AppTypography.caption(context).copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.question.required) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Required',
                    style: AppTypography.caption(context).copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.question.question,
            style: AppTypography.titleMedium(context),
          ),
          if (widget.question.helpText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.question.helpText!,
              style: AppTypography.bodyMedium(context).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _buildInputWidget(theme),
        ],
      ),
    );
  }

  Widget _buildInputWidget(ThemeData theme) {
    switch (widget.question.type.toLowerCase()) {
      case 'radio':
        return _buildRadioWidget(theme);
      case 'checkbox':
        return _buildCheckboxWidget(theme);
      case 'text':
        return _buildTextWidget(theme);
      case 'number':
        return _buildNumberWidget(theme);
      case 'date':
        return _buildDateWidget(theme);
      case 'time':
        return _buildTimeWidget(theme);
      case 'textarea':
        return _buildTextAreaWidget(theme);
      case 'select':
        return _buildSelectWidget(theme);
      case 'range':
        return _buildRangeWidget(theme);
      case 'boolean':
        return _buildBooleanWidget(theme);
      default:
        return _buildTextWidget(theme);
    }
  }

  Widget _buildRadioWidget(ThemeData theme) {
    if (widget.question.options == null || widget.question.options!.isEmpty) {
      return _buildNoOptions(theme);
    }
    return Column(
      children: widget.question.options!.map((option) {
        return RadioListTile<String>(
          title: Text(option, style: AppTypography.bodyLarge(context)),
          value: option,
          groupValue: _currentAnswer?.toString(),
          onChanged: (value) => _updateAnswer(value),
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: theme.colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxWidget(ThemeData theme) {
    if (widget.question.options == null || widget.question.options!.isEmpty) {
      return _buildNoOptions(theme);
    }

    List<String> selectedOptions = [];
    if (_currentAnswer is List) {
      selectedOptions = List<String>.from(_currentAnswer);
    } else if (_currentAnswer is String && _currentAnswer.isNotEmpty) {
      selectedOptions = [_currentAnswer];
    }

    return Column(
      children: widget.question.options!.map((option) {
        final isSelected = selectedOptions.contains(option);
        return CheckboxListTile(
          title: Text(option, style: AppTypography.bodyLarge(context)),
          value: isSelected,
          onChanged: (bool? value) {
            final newSelection = List<String>.from(selectedOptions);
            if (value == true) {
              if (!newSelection.contains(option)) newSelection.add(option);
            } else {
              newSelection.remove(option);
            }
            _updateAnswer(newSelection);
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: theme.colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildTextWidget(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: widget.question.placeholder ?? 'Enter answer...',
            ),
            onChanged: _updateAnswer,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildMic(),
      ],
    );
  }


  Widget _buildNumberWidget(ThemeData theme) {
    return TextFormField(
      controller: _textController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter number...',
      ),
      onChanged: (value) {
        final numValue = double.tryParse(value);
        _updateAnswer(numValue ?? value);
      },
    );
  }

  Widget _buildDateWidget(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          final formatted = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
          _textController.text = formatted;
          _updateAnswer(formatted);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Select date...',
            suffixIcon: Icon(Icons.calendar_today_rounded),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeWidget(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (selectedTime != null) {
          final formatted = '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}';
          _textController.text = formatted;
          _updateAnswer(formatted);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Select time...',
            suffixIcon: Icon(Icons.access_time_rounded),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAreaWidget(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: widget.question.placeholder ?? 'Enter details...',
            ),
            onChanged: _updateAnswer,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildMic(),
      ],
    );
  }

  /// Mic button that appends dictated text into the field.
  Widget _buildMic() {
    return VoiceInputButton(
      arabic: Directionality.of(context) == TextDirection.rtl,
      onTranscript: (text) {
        if (text.trim().isEmpty) return;
        _textController.text = text;
        _textController.selection =
            TextSelection.collapsed(offset: _textController.text.length);
        _updateAnswer(text);
      },
    );
  }


  Widget _buildSelectWidget(ThemeData theme) {
    if (widget.question.options == null || widget.question.options!.isEmpty) {
      return _buildNoOptions(theme);
    }
    return DropdownButtonFormField<String>(
      value: _currentAnswer?.toString(),
      hint: const Text('Select from list...'),
      items: widget.question.options!.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: _updateAnswer,
    );
  }

  Widget _buildRangeWidget(ThemeData theme) {
    double currentValue = 0.0;
    if (_currentAnswer is num) {
      currentValue = _currentAnswer.toDouble();
    } else if (_currentAnswer is String) {
      currentValue = double.tryParse(_currentAnswer) ?? 0.0;
    }

    return Column(
      children: [
        Text(
          'Value: ${currentValue.toInt()}',
          style: AppTypography.titleMedium(context),
        ),
        Slider(
          value: currentValue,
          min: 0,
          max: 10,
          divisions: 10,
          label: currentValue.toInt().toString(),
          onChanged: (value) => _updateAnswer(value.toInt()),
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildBooleanWidget(ThemeData theme) {
    bool currentValue = false;
    if (_currentAnswer is bool) {
      currentValue = _currentAnswer;
    } else if (_currentAnswer is String) {
      currentValue = _currentAnswer.toLowerCase() == 'true' ||
          _currentAnswer == 'نعم' ||
          _currentAnswer == '1';
    }

    return Row(
      children: [
        Expanded(
          child: RadioListTile<bool>(
            title: Text('Yes', style: AppTypography.bodyLarge(context)),
            value: true,
            groupValue: currentValue,
            onChanged: (value) => _updateAnswer(value),
            dense: true,
            activeColor: theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: RadioListTile<bool>(
            title: Text('No', style: AppTypography.bodyLarge(context)),
            value: false,
            groupValue: currentValue,
            onChanged: (value) => _updateAnswer(value),
            dense: true,
            activeColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoOptions(ThemeData theme) {
    return Text(
      'No options available',
      style: AppTypography.bodyMedium(context).copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
