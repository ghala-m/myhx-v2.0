// Fixed Dynamic Question Widget
// lib/widgets/dynamic_question_widget.dart or lib/screens/dynamic_question_widget.dart

import 'package:flutter/material.dart';
import '../models/question_model.dart';

class DynamicQuestionWidget extends StatefulWidget {
  final EnhancedQuestion question;
  final dynamic answer;
  final Function(dynamic) onAnswerChanged;

  const DynamicQuestionWidget({
    super.key,
    required this.question,
    this.answer,
    required this.onAnswerChanged, required currentAnswer,
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
    _textController = TextEditingController(
      text: widget.answer?.toString() ?? '',
    );
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
    setState(() {
      _currentAnswer = answer;
    });
    widget.onAnswerChanged(answer);
  }

  Color _getPriorityColor() {
    switch (widget.question.priority) {
      case QuestionPriority.critical:
        return Colors.red;
      case QuestionPriority.important:
        return Colors.orange;
      case QuestionPriority.detailed:
        return Colors.blue;
      case QuestionPriority.optional:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon() {
    switch (widget.question.priority) {
      case QuestionPriority.critical:
        return Icons.priority_high;
      case QuestionPriority.important:
        return Icons.info;
      case QuestionPriority.detailed:
        return Icons.list;
      case QuestionPriority.optional:
        return Icons.help_outline;
      default:
        return Icons.help_outline;
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question title with priority indicator
          Row(
            children: [
              // Priority indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getPriorityColor(), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPriorityIcon(),
                      size: 14,
                      color: _getPriorityColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPriorityLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPriorityColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Required indicator
              if (widget.question.required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Question text
          Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          // Help text
          if (widget.question.helpText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.question.helpText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Input element based on question type
          _buildInputWidget(),
        ],
      ),
    );
  }

  Widget _buildInputWidget() {
    switch (widget.question.type.toLowerCase()) {
      case 'radio':
        return _buildRadioWidget();
      case 'checkbox':
        return _buildCheckboxWidget();
      case 'text':
        return _buildTextWidget();
      case 'number':
        return _buildNumberWidget();
      case 'date':
        return _buildDateWidget();
      case 'time':
        return _buildTimeWidget();
      case 'textarea':
        return _buildTextAreaWidget();
      case 'select':
        return _buildSelectWidget();
      case 'range':
        return _buildRangeWidget();
      case 'boolean':
        return _buildBooleanWidget();
      default:
        return _buildTextWidget();
    }
  }

  Widget _buildRadioWidget() {
    if (widget.question.options == null || widget.question.options!.isEmpty) {
      return const Text('No options available');
    }

    return Column(
      children: widget.question.options!.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: _currentAnswer?.toString(),
          onChanged: (value) => _updateAnswer(value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxWidget() {
    if (widget.question.options == null || widget.question.options!.isEmpty) {
      return const Text('No options available');
    }

    List<String> selectedOptions = [];
    if (_currentAnswer is List) {
      selectedOptions = List<String>.from(_currentAnswer);
    } else if (_currentAnswer is String && _currentAnswer.isNotEmpty) {
      selectedOptions = [_currentAnswer];
    }

    return Column(
      children: widget.question.options!.map((option) {
        bool isSelected = selectedOptions.contains(option);
        
        return CheckboxListTile(
          title: Text(option),
          value: isSelected,
          onChanged: (bool? value) {
            List<String> newSelection = List<String>.from(selectedOptions);
            if (value == true) {
              if (!newSelection.contains(option)) {
                newSelection.add(option);
              }
            } else {
              newSelection.remove(option);
            }
            _updateAnswer(newSelection);
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildTextWidget() {
    return TextFormField(
      controller: _textController,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter answer...',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: _updateAnswer,
    );
  }

  Widget _buildNumberWidget() {
    return TextFormField(
      controller: _textController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter number...',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) {
        double? numValue = double.tryParse(value);
        _updateAnswer(numValue ?? value);
      },
    );
  }

  Widget _buildDateWidget() {
    return InkWell(
      onTap: () async {
        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        
        if (selectedDate != null) {
          String formattedDate = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
          _textController.text = formattedDate;
          _updateAnswer(formattedDate);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Select date...',
            border: OutlineInputBorder(),
            isDense: true,
            suffixIcon: Icon(Icons.calendar_today),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeWidget() {
    return InkWell(
      onTap: () async {
        TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        
        if (selectedTime != null) {
          String formattedTime = "${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}";
          _textController.text = formattedTime;
          _updateAnswer(formattedTime);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Select time...',
            border: OutlineInputBorder(),
            isDense: true,
            suffixIcon: Icon(Icons.access_time),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAreaWidget() {
    return TextFormField(
      controller: _textController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: widget.question.placeholder ?? 'Enter details...',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: _updateAnswer,
    );
  }

  Widget _buildSelectWidget() {
    if (widget.question.options == null || widget.question.options!.isEmpty) {
      return const Text('No options available');
    }

    return DropdownButtonFormField<String>(
      value: _currentAnswer?.toString(),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
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

  Widget _buildRangeWidget() {
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: currentValue,
          min: 0,
          max: 10,
          divisions: 10,
          label: currentValue.toInt().toString(),
          onChanged: (value) {
            _updateAnswer(value.toInt());
          },
        ),
      ],
    );
  }

  Widget _buildBooleanWidget() {
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
            title: const Text('Yes'),
            value: true,
            groupValue: currentValue,
            onChanged: (value) => _updateAnswer(value),
            dense: true,
          ),
        ),
        Expanded(
          child: RadioListTile<bool>(
            title: const Text('No'),
            value: false,
            groupValue: currentValue,
            onChanged: (value) => _updateAnswer(value),
            dense: true,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

