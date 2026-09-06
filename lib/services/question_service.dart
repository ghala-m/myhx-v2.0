// Enhanced Question Service with Hardcoded Questions
// This service manages a list of hardcoded medical questions.
// (The JSON-schema files this could optionally load from were unused dead
// weight and have been removed — see loadMedicalHistorySchema below.)

import '../models/question_model.dart';
import '../utils/app_logger.dart';

class EnhancedQuestionService {
  List<EnhancedQuestion> _allQuestions = [];
  final Map<String, dynamic> _answers = {};
  
  int? _patientAge;
  String? _patientGender;
  String? _patientDepartment;
  List<String> _currentSymptoms = [];

  Future<void> loadMedicalHistorySchema() async {
    try {
      // Instead of loading from a JSON file, we will use hardcoded questions
      _allQuestions = _getHardcodedQuestions();
      
      _allQuestions.sort((a, b) {
        int priorityComparison = _getPriorityWeight(a.priority).compareTo(_getPriorityWeight(b.priority));
        if (priorityComparison != 0) return priorityComparison;
        return a.displayOrder.compareTo(b.displayOrder);
      });
      
      AppLogger.d('Loaded ${_allQuestions.length} questions successfully from hardcoded data');
    } catch (e) {
      AppLogger.d("Error loading medical history schema: $e");
      // In case of error, use hardcoded questions
      _allQuestions = _getHardcodedQuestions();
    }
  }

  // Hardcoded questions
  List<EnhancedQuestion> _getHardcodedQuestions() {
    return [
      // Chief Complaint
      EnhancedQuestion(
        id: "chief_complaint",
        question: "What is the chief complaint?",
        type: "textarea",
        required: true,
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.always,
        displayOrder: 1,
        department: "General",
        helpText: "Mention up to 3 main symptoms",
        placeholder: "Example: Fever, cough, difficulty breathing",
      ),

      // Conditional Pain Questions
      EnhancedQuestion(
        id: "has_pain",
        question: "Does the patient have pain?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.always,
        displayOrder: 5,
        department: "General",
        helpText: "Basic question about the presence of pain",
      ),

      EnhancedQuestion(
        id: "pain_location",
        question: "What is the location of the pain?",
        type: "text",
        required: true,
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.conditional,
        displayOrder: 6,
        department: "General",
        dependsOnQuestionId: "has_pain",
        dependsOnAnswerValue: "Yes",
        placeholder: "Example: Abdomen, chest, head",
        helpText: "Specify where the patient feels pain",
      ),

      EnhancedQuestion(
        id: "pain_severity",
        question: "What is the severity of the pain (1 to 10)?",
        type: "radio",
        required: true,
        options: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"],
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.conditional,
        displayOrder: 7,
        department: "General",
        dependsOnQuestionId: "has_pain",
        dependsOnAnswerValue: "Yes",
        helpText: "1 = very mild pain, 10 = very severe pain",
      ),

      EnhancedQuestion(
        id: "pain_type",
        question: "What type of pain?",
        type: "radio",
        required: true,
        options: ["Sharp", "Throbbing", "Burning", "Cramping", "Heavy"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 8,
        department: "General",
        dependsOnQuestionId: "has_pain",
        dependsOnAnswerValue: "Yes",
        helpText: "Choose the type that best describes the pain",
      ),

      // Conditional Cough Questions
      EnhancedQuestion(
        id: "has_cough",
        question: "Does the patient have a cough?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.always,
        displayOrder: 10,
        department: "General",
        helpText: "Basic question about the presence of cough",
      ),

      EnhancedQuestion(
        id: "cough_type",
        question: "What type of cough?",
        type: "radio",
        required: true,
        options: ["Dry", "With phlegm"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 11,
        department: "General",
        dependsOnQuestionId: "has_cough",
        dependsOnAnswerValue: "Yes",
        helpText: "This question appears only if the previous answer was 'Yes'",
      ),

      EnhancedQuestion(
        id: "sputum_color",
        question: "What is the color of the sputum?",
        type: "radio",
        required: true,
        options: ["White", "Yellow", "Green", "Bloody", "Brown"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 12,
        department: "General",
        dependsOnQuestionId: "cough_type",
        dependsOnAnswerValue: "With phlegm",
        helpText: "This question appears only if the cough is with phlegm",
      ),

      EnhancedQuestion(
        id: "cough_duration",
        question: "How long has the cough been present?",
        type: "text",
        required: false,
        priority: QuestionPriority.detailed,
        visibility: QuestionVisibility.conditional,
        displayOrder: 13,
        department: "General",
        dependsOnQuestionId: "has_cough",
        dependsOnAnswerValue: "Yes",
        placeholder: "Example: 3 days, 1 week",
      ),

      // Remaining Basic Questions - Fever
      EnhancedQuestion(
        id: "has_fever",
        question: "Does the patient have a fever?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.always,
        displayOrder: 20,
        department: "General",
      ),

      EnhancedQuestion(
        id: "fever_temperature",
        question: "What is the temperature?",
        type: "number",
        required: false,
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 21,
        department: "General",
        dependsOnQuestionId: "has_fever",
        dependsOnAnswerValue: "Yes",
        placeholder: "Example: 38.5",
      ),

      EnhancedQuestion(
        id: "fever_duration",
        question: "How long has the fever been present?",
        type: "text",
        required: false,
        priority: QuestionPriority.detailed,
        visibility: QuestionVisibility.conditional,
        displayOrder: 22,
        department: "General",
        dependsOnQuestionId: "has_fever",
        dependsOnAnswerValue: "Yes",
        placeholder: "Example: 2 days",
      ),

      EnhancedQuestion(
        id: "has_breathing_difficulty",
        question: "Does the patient have difficulty breathing?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.always,
        displayOrder: 30,
        department: "General",
      ),

      EnhancedQuestion(
        id: "breathing_severity",
        question: "What is the severity of breathing difficulty?",
        type: "radio",
        required: true,
        options: ["Mild", "Moderate", "Severe"],
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.conditional,
        displayOrder: 31,
        department: "General",
        dependsOnQuestionId: "has_breathing_difficulty",
        dependsOnAnswerValue: "Yes",
      ),

      EnhancedQuestion(
        id: "has_vomiting",
        question: "Does the patient have vomiting?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.always,
        displayOrder: 40,
        department: "General",
      ),

      EnhancedQuestion(
        id: "vomiting_frequency",
        question: "How many times has vomiting occurred today?",
        type: "number",
        required: false,
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 41,
        department: "General",
        dependsOnQuestionId: "has_vomiting",
        dependsOnAnswerValue: "Yes",
        placeholder: "Number of times",
      ),

      EnhancedQuestion(
        id: "vomiting_content",
        question: "What is the content of the vomit?",
        type: "checkbox",
        required: false,
        options: ["Food", "Liquid", "Blood", "Bile (yellow/green)"],
        priority: QuestionPriority.detailed,
        visibility: QuestionVisibility.conditional,
        displayOrder: 42,
        department: "General",
        dependsOnQuestionId: "has_vomiting",
        dependsOnAnswerValue: "Yes",
      ),

      EnhancedQuestion(
        id: "has_diarrhea",
        question: "Does the patient have diarrhea?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.always,
        displayOrder: 50,
        department: "General",
      ),

      EnhancedQuestion(
        id: "diarrhea_frequency",
        question: "How many times has diarrhea occurred today?",
        type: "number",
        required: false,
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 51,
        department: "General",
        dependsOnQuestionId: "has_diarrhea",
        dependsOnAnswerValue: "Yes",
        placeholder: "Number of times",
      ),

      EnhancedQuestion(
        id: "stool_appearance",
        question: "What is the appearance of the stool?",
        type: "checkbox",
        required: false,
        options: ["Watery", "Loose", "Bloody", "Mucus", "Black"],
        priority: QuestionPriority.detailed,
        visibility: QuestionVisibility.conditional,
        displayOrder: 52,
        department: "General",
        dependsOnQuestionId: "has_diarrhea",
        dependsOnAnswerValue: "Yes",
      ),

      EnhancedQuestion(
        id: "appetite_status",
        question: "What is the appetite status?",
        type: "radio",
        required: true,
        options: ["Normal", "Reduced", "Not eating at all"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.always,
        displayOrder: 60,
        department: "General",
      ),

      EnhancedQuestion(
        id: "fluid_intake",
        question: "Is the patient drinking enough fluids?",
        type: "radio",
        required: true,
        options: ["Yes", "Little", "Not drinking"],
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.always,
        displayOrder: 70,
        department: "General",
      ),

      EnhancedQuestion(
        id: "urine_output",
        question: "Is urination normal?",
        type: "radio",
        required: true,
        options: ["Normal", "Reduced", "No urination for hours"],
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.always,
        displayOrder: 80,
        department: "General",
      ),

      EnhancedQuestion(
        id: "activity_level",
        question: "What is the child's activity level?",
        type: "radio",
        required: true,
        options: ["Active", "Slightly lethargic", "Very lethargic"],
        priority: QuestionPriority.critical,
        visibility: QuestionVisibility.always,
        displayOrder: 90,
        department: "General",
      ),

      EnhancedQuestion(
        id: "previous_medications",
        question: "Has any medication been given?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.always,
        displayOrder: 100,
        department: "General",
      ),

      EnhancedQuestion(
        id: "medication_details",
        question: "What medications were given?",
        type: "textarea",
        required: false,
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 101,
        department: "General",
        dependsOnQuestionId: "previous_medications",
        dependsOnAnswerValue: "Yes",
        placeholder: "Mention medication name and dosage",
      ),

      EnhancedQuestion(
        id: "chronic_diseases",
        question: "Does the patient have any chronic diseases?",
        type: "radio",
        required: true,
        options: ["Yes", "No"],
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.always,
        displayOrder: 110,
        department: "General",
      ),

      EnhancedQuestion(
        id: "chronic_disease_details",
        question: "What are the chronic diseases?",
        type: "textarea",
        required: false,
        priority: QuestionPriority.important,
        visibility: QuestionVisibility.conditional,
        displayOrder: 111,
        department: "General",
        dependsOnQuestionId: "chronic_diseases",
        dependsOnAnswerValue: "Yes",
        placeholder: "Mention chronic diseases",
      ),
    ];
  }

  int _getPriorityWeight(QuestionPriority priority) {
    switch (priority) {
      case QuestionPriority.critical:
        return 1;
      case QuestionPriority.important:
        return 2;
      case QuestionPriority.detailed:
        return 3;
      case QuestionPriority.optional:
        return 4;
    }
  }

  void setPatientContext({
    int? age,
    String? gender,
    String? department,
    List<String>? symptoms,
  }) {
    _patientAge = age;
    _patientGender = gender;
    _patientDepartment = department;
    if (symptoms != null) {
      _currentSymptoms = symptoms;
    }
  }

  void updateCurrentSymptoms() {
    _currentSymptoms.clear();
    _answers.forEach((questionId, answer) {
      if (answer != null && answer.toString().isNotEmpty) {
        if (questionId.contains('complaint') || questionId.contains('symptom')) {
          _currentSymptoms.add(answer.toString());
        }
        // Add specific symptoms based on answers
        if (questionId == 'has_cough' && (answer == 'Yes' || answer == 'yes')) {
          _currentSymptoms.add('cough');
        }
      }
    });
  }

  List<EnhancedQuestion> getQuestionsForDisplay({
    required String department,
    required Map<String, dynamic> currentAnswers,
    int? patientAge,
    String? patientGender,
  }) {
    List<EnhancedQuestion> questionsToDisplay = [];
    updateCurrentSymptoms();

    for (var question in _allQuestions) {
      bool departmentMatch = (question.department == department || 
                              question.department == 'General' || 
                              question.department == null);
      
      if (!departmentMatch) continue;

      if (!question.shouldShowForPatient(
        patientAge: patientAge ?? _patientAge,
        patientGender: patientGender ?? _patientGender,
        currentSymptoms: _currentSymptoms,
      )) {
        continue;
      }

      if (!checkDependency(question)) {
        continue;
      }

      questionsToDisplay.add(question);
    }

    questionsToDisplay.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return questionsToDisplay;
  }

  // FIX: Improve dependency checking with correct boolean value handling
  bool checkDependency(EnhancedQuestion question) {
    if (question.dependsOnQuestionId == null) return true;

    // Check the first condition
    dynamic answer1 = _answers[question.dependsOnQuestionId];
    bool condition1Met = _evaluateCondition(answer1, question.dependsOnAnswerValue);

    // If there is no second condition, return the result of the first condition
    if (question.dependsOnQuestionId2 == null) {
      return condition1Met;
    }

    // Check the second condition
    dynamic answer2 = _answers[question.dependsOnQuestionId2];
    bool condition2Met = _evaluateCondition(answer2, question.dependsOnAnswerValue2);

    // Apply the logical operator
    if (question.operator == 'or') {
      return condition1Met || condition2Met;
    } else if (question.operator == 'and') {
      return condition1Met && condition2Met;
    }

    // Default: return the first condition if no operator is specified
    return condition1Met;
  }

  // FIX: New helper function to correctly evaluate conditions
  bool _evaluateCondition(dynamic actualAnswer, dynamic expectedValue) {
    // Handle null expected value
    if (expectedValue == null) {
      return actualAnswer == null || actualAnswer.toString().isEmpty;
    }

    // Handle boolean expected values
    if (expectedValue is bool) {
      if (expectedValue == true) {
        // Check if an answer exists and is not empty
        if (actualAnswer == null) return false;
        if (actualAnswer is bool) return actualAnswer;
        if (actualAnswer is String) {
          String normalized = actualAnswer.toLowerCase().trim();
          return normalized.isNotEmpty && 
                 normalized != 'false' && 
                 normalized != 'no' &&
                 normalized != '0';
        }
        return actualAnswer.toString().isNotEmpty;
      } else {
        // expectedValue == false: Check if the answer is empty or false
        if (actualAnswer == null) return true;
        if (actualAnswer is bool) return !actualAnswer;
        if (actualAnswer is String) {
          String normalized = actualAnswer.toLowerCase().trim();
          return normalized.isEmpty || 
                 normalized == 'false' || 
                 normalized == 'no' ||
                 normalized == '0';
        }
        return actualAnswer.toString().isEmpty;
      }
    }

    // Handle text comparison (case-insensitive) 
    if (expectedValue is String && actualAnswer is String) {
      return actualAnswer.toLowerCase().trim() == expectedValue.toLowerCase().trim();
    }

    // Handle list membership
    if (expectedValue is List) {
      if (actualAnswer is List) {
        return actualAnswer.any((item) => expectedValue.contains(item));
      }
      return expectedValue.contains(actualAnswer);
    }

    // Direct comparison for other types
    return actualAnswer == expectedValue;
  }

  void setAnswer(String questionId, dynamic answer) {
    _answers[questionId] = answer;
    updateCurrentSymptoms();
  }

  Map<String, dynamic> getAllAnswers() {
    return Map.from(_answers);
  }

  // دوال إضافية
  List<EnhancedQuestion> getEssentialQuestions(String department) {
    return _allQuestions.where((q) {
      bool departmentMatch = (q.department == department || 
                             q.department == 'General' || 
                             q.department == null);
      return departmentMatch && q.priority == QuestionPriority.critical;
    }).toList();
  }

  List<EnhancedQuestion> getFollowUpQuestions(String department) {
    updateCurrentSymptoms();
    return _allQuestions.where((q) {
      bool departmentMatch = (q.department == department || 
                             q.department == 'General' || 
                             q.department == null);
      bool isFollowUp = q.isFollowUp || q.visibility == QuestionVisibility.conditional;
      bool dependencyMet = checkDependency(q);
      bool contextMatch = q.shouldShowForPatient(
        patientAge: _patientAge,
        patientGender: _patientGender,
        currentSymptoms: _currentSymptoms,
      );
      return departmentMatch && isFollowUp && dependencyMet && contextMatch;
    }).toList();
  }

  EnhancedQuestion? getQuestionById(String id) {
    try {
      return _allQuestions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  EnhancedQuestion? getNextQuestion({
    required String department,
    required Map<String, dynamic> currentAnswers,
    int? patientAge,
    String? patientGender,
    String? lastQuestionId,
  }) {
    List<EnhancedQuestion> visibleQuestions = getQuestionsForDisplay(
      department: department,
      currentAnswers: currentAnswers,
      patientAge: patientAge,
      patientGender: patientGender,
    );

    if (lastQuestionId == null) {
      return visibleQuestions.isNotEmpty ? visibleQuestions.first : null;
    }

    int lastIndex = visibleQuestions.indexWhere((q) => q.id == lastQuestionId);
    if (lastIndex != -1 && lastIndex < visibleQuestions.length - 1) {
      return visibleQuestions[lastIndex + 1];
    }
    return null;
  }

  EnhancedQuestion? getPreviousQuestion({
    required String department,
    required Map<String, dynamic> currentAnswers,
    int? patientAge,
    String? patientGender,
    String? currentQuestionId,
  }) {
    List<EnhancedQuestion> visibleQuestions = getQuestionsForDisplay(
      department: department,
      currentAnswers: currentAnswers,
      patientAge: patientAge,
      patientGender: patientGender,
    );

    if (currentQuestionId == null) {
      return null;
    }

    int currentIndex = visibleQuestions.indexWhere((q) => q.id == currentQuestionId);
    if (currentIndex > 0) {
      return visibleQuestions[currentIndex - 1];
    }
    return null;
  }

  getAnswer(String id) {
    return _answers[id];
  }
}
