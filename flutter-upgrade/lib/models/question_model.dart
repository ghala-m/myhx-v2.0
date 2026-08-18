// Enhanced Question Model with Priority System
// نموذج الأسئلة المحسن مع نظام الأولوية

enum QuestionPriority {
  critical,    // أسئلة حيوية - تظهر دائماً
  important,   // أسئلة مهمة - تظهر بناءً على الشروط
  detailed,    // أسئلة تفصيلية - تظهر للحالات المعقدة
  optional     // أسئلة اختيارية - تظهر عند الطلب
}

enum QuestionVisibility {
  always,      // دائماً مرئية
  conditional, // مرئية بشروط
  onDemand     // عند الطلب فقط
}

class EnhancedQuestion {
  final String id;
  final String question;
  final String type;
  final bool required;
  final List<String>? options;
  final String? subcategory;
  
  // Enhanced dependency system
  final String? dependsOnQuestionId;
  final dynamic dependsOnAnswerValue;
  final String? operator;
  final String? dependsOnQuestionId2;
  final dynamic dependsOnAnswerValue2;
  
  // New priority and visibility system
  final QuestionPriority priority;
  final QuestionVisibility visibility;
  final int displayOrder;
  final String? department;
  
  // Conditional display rules
  final List<String>? showIfSymptoms;
  final List<String>? hideIfSymptoms;
  final int? minAge;
  final int? maxAge;
  final List<String>? genderRestriction;
  
  // Grouping and categorization
  final String? parentQuestionId;
  final bool isFollowUp;
  final String? triggerCondition;
  
  // UI hints
  final String? helpText;
  final String? placeholder;
  final bool allowSkip;
  
  // NEW: Support for additional text field when specific option is selected
  final bool hasOtherOption;  // هل يحتوي على خيار "أخرى"
  final List<String>? triggerTextFieldOptions;  // الخيارات التي تُظهر حقل نصي إضافي
  final String? additionalTextFieldLabel;  // عنوان الحقل النصي الإضافي

  EnhancedQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.required = false,
    this.options,
    this.subcategory,
    this.dependsOnQuestionId,
    this.dependsOnAnswerValue,
    this.operator,
    this.dependsOnQuestionId2,
    this.dependsOnAnswerValue2,
    this.priority = QuestionPriority.optional,
    this.visibility = QuestionVisibility.always,
    this.displayOrder = 999,
    this.department,
    this.showIfSymptoms,
    this.hideIfSymptoms,
    this.minAge,
    this.maxAge,
    this.genderRestriction,
    this.parentQuestionId,
    this.isFollowUp = false,
    this.triggerCondition,
    this.helpText,
    this.placeholder,
    this.allowSkip = true,
    this.hasOtherOption = false,
    this.triggerTextFieldOptions,
    this.additionalTextFieldLabel,
  });

  factory EnhancedQuestion.fromJson(Map<String, dynamic> json) {
    return EnhancedQuestion(
      id: json["id"] as String,
      question: json["question"] as String,
      type: json["type"] as String,
      required: json["required"] as bool? ?? false,
      options: (json["options"] as List<dynamic>?)?.cast<String>(),
      subcategory: json["subcategory"] as String?,
      dependsOnQuestionId: json["dependsOn"] as String?,
      dependsOnAnswerValue: json["dependsOnValue"],
      operator: json["operator"] as String?,
      dependsOnQuestionId2: json["dependsOn2"] as String?,
      dependsOnAnswerValue2: json["dependsOnValue2"],
      priority: _parsePriority(json["priority"] as String?),
      visibility: _parseVisibility(json["visibility"] as String?),
      displayOrder: json["displayOrder"] as int? ?? 999,
      department: json["department"] as String?,
      showIfSymptoms: (json["showIfSymptoms"] as List<dynamic>?)?.cast<String>(),
      hideIfSymptoms: (json["hideIfSymptoms"] as List<dynamic>?)?.cast<String>(),
      minAge: json["minAge"] as int?,
      maxAge: json["maxAge"] as int?,
      genderRestriction: (json["genderRestriction"] as List<dynamic>?)?.cast<String>(),
      parentQuestionId: json["parentQuestionId"] as String?,
      isFollowUp: json["isFollowUp"] as bool? ?? false,
      triggerCondition: json["triggerCondition"] as String?,
      helpText: json["helpText"] as String?,
      placeholder: json["placeholder"] as String?,
      allowSkip: json["allowSkip"] as bool? ?? true,
      hasOtherOption: json["hasOtherOption"] as bool? ?? false,
      triggerTextFieldOptions: (json["triggerTextFieldOptions"] as List<dynamic>?)?.cast<String>(),
      additionalTextFieldLabel: json["additionalTextFieldLabel"] as String?,
    );
  }

  get groupId => null;

  static QuestionPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return QuestionPriority.critical;
      case 'important':
        return QuestionPriority.important;
      case 'detailed':
        return QuestionPriority.detailed;
      default:
        return QuestionPriority.optional;
    }
  }

  static QuestionVisibility _parseVisibility(String? visibility) {
    switch (visibility?.toLowerCase()) {
      case 'always':
        return QuestionVisibility.always;
      case 'conditional':
        return QuestionVisibility.conditional;
      case 'ondemand':
        return QuestionVisibility.onDemand;
      default:
        return QuestionVisibility.always;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'required': required,
      'options': options,
      'subcategory': subcategory,
      'dependsOn': dependsOnQuestionId,
      'dependsOnValue': dependsOnAnswerValue,
      'operator': operator,
      'dependsOn2': dependsOnQuestionId2,
      'dependsOnValue2': dependsOnAnswerValue2,
      'priority': priority.toString().split('.').last,
      'visibility': visibility.toString().split('.').last,
      'displayOrder': displayOrder,
      'department': department,
      'showIfSymptoms': showIfSymptoms,
      'hideIfSymptoms': hideIfSymptoms,
      'minAge': minAge,
      'maxAge': maxAge,
      'genderRestriction': genderRestriction,
      'parentQuestionId': parentQuestionId,
      'isFollowUp': isFollowUp,
      'triggerCondition': triggerCondition,
      'helpText': helpText,
      'placeholder': placeholder,
      'allowSkip': allowSkip,
      'hasOtherOption': hasOtherOption,
      'triggerTextFieldOptions': triggerTextFieldOptions,
      'additionalTextFieldLabel': additionalTextFieldLabel,
    };
  }

  // Helper methods for question evaluation
  bool shouldShowForPatient({
    required int? patientAge,
    required String? patientGender,
    required List<String> currentSymptoms,
  }) {
    // Age restrictions
    if (minAge != null && (patientAge == null || patientAge < minAge!)) {
      return false;
    }
    if (maxAge != null && (patientAge == null || patientAge > maxAge!)) {
      return false;
    }

    // Gender restrictions
    if (genderRestriction != null && 
        patientGender != null && 
        !genderRestriction!.contains(patientGender)) {
      return false;
    }

    // Symptom-based visibility
    if (showIfSymptoms != null) {
      bool hasRequiredSymptom = showIfSymptoms!.any((symptom) => 
        currentSymptoms.any((current) => 
          current.toLowerCase().contains(symptom.toLowerCase())));
      if (!hasRequiredSymptom) return false;
    }

    if (hideIfSymptoms != null) {
      bool hasExcludingSymptom = hideIfSymptoms!.any((symptom) => 
        currentSymptoms.any((current) => 
          current.toLowerCase().contains(symptom.toLowerCase())));
      if (hasExcludingSymptom) return false;
    }

    return true;
  }

  bool isCritical() => priority == QuestionPriority.critical;
  bool isImportant() => priority == QuestionPriority.important;
  bool isDetailed() => priority == QuestionPriority.detailed;
  bool isOptional() => priority == QuestionPriority.optional;

  bool isAlwaysVisible() => visibility == QuestionVisibility.always;
  bool isConditionallyVisible() => visibility == QuestionVisibility.conditional;
  bool isOnDemandOnly() => visibility == QuestionVisibility.onDemand;
}

// Question Group for organizing related questions
class QuestionGroup {
  final String id;
  final String title;
  final String description;
  final QuestionPriority priority;
  final List<EnhancedQuestion> questions;
  final int displayOrder;
  final String? iconName;
  final bool isCollapsible;
  final bool isExpandedByDefault;

  QuestionGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.questions,
    this.displayOrder = 999,
    this.iconName,
    this.isCollapsible = true,
    this.isExpandedByDefault = true,
  });

  List<EnhancedQuestion> getVisibleQuestions({
    required Map<String, dynamic> currentAnswers,
    required int? patientAge,
    required String? patientGender,
    required List<String> currentSymptoms,
  }) {
    return questions.where((question) {
      // Check basic patient criteria
      if (!question.shouldShowForPatient(
        patientAge: patientAge,
        patientGender: patientGender,
        currentSymptoms: currentSymptoms,
      )) {
        return false;
      }

      // Check dependencies
      if (question.dependsOnQuestionId != null) {
        return _checkDependency(question, currentAnswers);
      }

      return true;
    }).toList()..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  bool _checkDependency(EnhancedQuestion question, Map<String, dynamic> answers) {
    if (question.dependsOnQuestionId == null) return true;

    dynamic answer1 = answers[question.dependsOnQuestionId];
    bool condition1Met = false;

    if (question.dependsOnAnswerValue is bool && question.dependsOnAnswerValue == true) {
      condition1Met = (answer1 != null && answer1.toString().isNotEmpty);
    } else if (question.dependsOnAnswerValue is bool && question.dependsOnAnswerValue == false) {
      condition1Met = (answer1 == null || answer1.toString().isEmpty);
    } else {
      condition1Met = (answer1 == question.dependsOnAnswerValue);
    }

    if (question.operator == 'or' && question.dependsOnQuestionId2 != null) {
      dynamic answer2 = answers[question.dependsOnQuestionId2];
      bool condition2Met = false;

      if (question.dependsOnAnswerValue2 is bool && question.dependsOnAnswerValue2 == true) {
        condition2Met = (answer2 != null && answer2.toString().isNotEmpty);
      } else if (question.dependsOnAnswerValue2 is bool && question.dependsOnAnswerValue2 == false) {
        condition2Met = (answer2 == null || answer2.toString().isEmpty);
      } else {
        condition2Met = (answer2 == question.dependsOnAnswerValue2);
      }
      return condition1Met || condition2Met;
    } else if (question.operator == 'and' && question.dependsOnQuestionId2 != null) {
      dynamic answer2 = answers[question.dependsOnQuestionId2];
      bool condition2Met = false;

      if (question.dependsOnAnswerValue2 is bool && question.dependsOnAnswerValue2 == true) {
        condition2Met = (answer2 != null && answer2.toString().isNotEmpty);
      } else if (question.dependsOnAnswerValue2 is bool && question.dependsOnAnswerValue2 == false) {
        condition2Met = (answer2 == null || answer2.toString().isEmpty);
      } else {
        condition2Met = (answer2 == question.dependsOnAnswerValue2);
      }
      return condition1Met && condition2Met;
    }

    return condition1Met;
  }
}
