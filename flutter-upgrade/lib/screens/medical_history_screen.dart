// Simple Medical History Screen with Smart Question System
// One question per page + sub-questions appearing based on answers

import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../widgets/dynamic_question_widget.dart';
import 'patient_record_screen.dart';
import 'login_screen.dart';

class SimpleSmartMedicalHistoryScreen extends StatefulWidget {
  final Patient patient;
  final String department;

  const SimpleSmartMedicalHistoryScreen({
    Key? key,
    required this.patient,
    required this.department,
  }) : super(key: key);

  @override
  State<SimpleSmartMedicalHistoryScreen> createState() => _SimpleSmartMedicalHistoryScreenState();
}

class _SimpleSmartMedicalHistoryScreenState extends State<SimpleSmartMedicalHistoryScreen> {
  final EnhancedQuestionService _questionService = EnhancedQuestionService();
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();

  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, dynamic> _personalInfoAnswers = {};
  List<EnhancedQuestion> _visibleQuestions = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndInitializeQuestions();
    _initializePersonalInfo();
  }

  void _initializePersonalInfo() {
    _personalInfoAnswers['id'] = widget.patient.id;
    _personalInfoAnswers['name'] = widget.patient.name;
    _personalInfoAnswers['age'] = widget.patient.age;
    _personalInfoAnswers['gender'] = widget.patient.gender;
    _personalInfoAnswers['ward_number'] = widget.patient.wardNumber;
    _personalInfoAnswers['room_number'] = widget.patient.roomNumber;
    _personalInfoAnswers['department'] = widget.patient.department;
  }

  Future<void> _checkAuthAndInitializeQuestions() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
      return;
    }

    try {
      await _questionService.loadMedicalHistorySchema();
      
      // Set patient context for smart filtering
      _questionService.setPatientContext(
        age: widget.patient.age,
        gender: widget.patient.gender,
        department: widget.patient.department,
      );

      // Load initial essential questions
      _updateVisibleQuestions();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update visible questions based on current answers
  void _updateVisibleQuestions() {
    // Start with essential questions
    List<EnhancedQuestion> essentialQuestions = _questionService.getEssentialQuestions(widget.department);
    
    // Add follow-up questions based on answers
    List<EnhancedQuestion> followUpQuestions = _questionService.getFollowUpQuestions(widget.department);
    
    // Combine and remove duplicates
    Set<String> addedIds = {};
    _visibleQuestions = [];
    
    // Add essential questions first
    for (var q in essentialQuestions) {
      if (!addedIds.contains(q.id)) {
        _visibleQuestions.add(q);
        addedIds.add(q.id);
      }
    }
    
    // Add follow-up questions that meet dependencies
    for (var q in followUpQuestions) {
      if (!addedIds.contains(q.id) && _questionService.checkDependency(q)) {
        // Insert follow-up question after its parent question
        if (q.dependsOnQuestionId != null) {
          int parentIndex = _visibleQuestions.indexWhere((vq) => vq.id == q.dependsOnQuestionId);
          if (parentIndex != -1) {
            _visibleQuestions.insert(parentIndex + 1, q);
            addedIds.add(q.id);
          }
        } else {
          _visibleQuestions.add(q);
          addedIds.add(q.id);
        }
      }
    }
    
    // Sort by display order
    _visibleQuestions.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    
    // Adjust current index if needed
    if (_currentQuestionIndex >= _visibleQuestions.length && _visibleQuestions.isNotEmpty) {
      _currentQuestionIndex = _visibleQuestions.length - 1;
    }
  }

  void _onAnswerChanged(String questionId, dynamic answer) {
    _questionService.setAnswer(questionId, answer);
    
    // Update visible questions to show/hide conditional questions
    setState(() {
      int previousCount = _visibleQuestions.length;
      _updateVisibleQuestions();
      
      // If new questions appeared, stay on current question
      // If questions were removed and we're beyond the list, go back
      if (_currentQuestionIndex >= _visibleQuestions.length && _visibleQuestions.isNotEmpty) {
        _currentQuestionIndex = _visibleQuestions.length - 1;
      }
    });
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _visibleQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Last question, save the medical history
      _saveMedicalHistory();
    }
  }

  bool _canGoNext() {
    if (_visibleQuestions.isEmpty) return false;
    
    EnhancedQuestion currentQuestion = _visibleQuestions[_currentQuestionIndex];
    
    // If question is required, check if answered
    if (currentQuestion.required) {
      dynamic answer = _questionService.getAnswer(currentQuestion.id);
      if (answer == null || answer.toString().trim().isEmpty) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> _saveMedicalHistory() async {
    if (mounted) setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User not logged in");

      final allAnswers = Map<String, dynamic>.from(_personalInfoAnswers);
      allAnswers.addAll(_questionService.getAllAnswers());

      // Extract symptoms for AI analysis
      List<String> symptoms = [];
      allAnswers.forEach((key, value) {
        if (value is String && value.isNotEmpty && value.length > 3) {
          symptoms.add(value);
        }
      });

      final analysisResult = await _aiService.analyzeSymptoms(
        symptoms.where((s) => s.isNotEmpty).toList(),
        {
          'age': (_personalInfoAnswers['age'] ?? 0).toString(),
          'gender': _personalInfoAnswers['gender'] ?? 'Unknown'
        },
      );

      final reportId = await _dbService.createReport(
        doctorId: user.uid,
        patient: widget.patient.copyWith(
          id: _personalInfoAnswers['id'] as String,
          name: _personalInfoAnswers['name'] as String,
          age: _personalInfoAnswers['age'] as int?,
          gender: _personalInfoAnswers['gender'] as String?,
          wardNumber: _personalInfoAnswers['ward_number'] as String?,
          roomNumber: _personalInfoAnswers['room_number'] as String?,
          department: _personalInfoAnswers['department'] as String?,
        ),
        medicalHistory: allAnswers,
        aiAnalysis: analysisResult,
        patientId: widget.patient.id,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PatientRecordScreen(
              reportId: reportId,
              patient: widget.patient,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medical history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Medical History: ${widget.patient.name}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_visibleQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Medical History: ${widget.patient.name}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                'No questions available',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    EnhancedQuestion currentQuestion = _visibleQuestions[_currentQuestionIndex];
    int totalQuestions = _visibleQuestions.length;
    double progress = (_currentQuestionIndex + 1) / totalQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Medical History: ${widget.patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveMedicalHistory,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  minHeight: 8.0,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question text
                  Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  
                  if (currentQuestion.required)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Required *',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.red,
                        ),
                      ),
                    ),

                  // Show if this is a follow-up question
                  if (currentQuestion.isFollowUp || currentQuestion.dependsOnQuestionId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Follow-up Question',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.blue[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24.0),

                  // Question input widget
                  EnhancedQuestionWidget(
                    question: currentQuestion,
                    currentAnswer: _questionService.getAnswer(currentQuestion.id),
                    onAnswerChanged: (answer) => _onAnswerChanged(currentQuestion.id, answer),
                    showHelpText: true,
                  ),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                ElevatedButton.icon(
                  onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                ),

                // Next/Finish button
                ElevatedButton.icon(
                  onPressed: (_canGoNext() && !_isSaving) 
                    ? _goToNextQuestion 
                    : null,
                  icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _currentQuestionIndex < _visibleQuestions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                      ),
                  label: Text(
                    _currentQuestionIndex < _visibleQuestions.length - 1
                      ? 'Next'
                      : 'Finish',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

EnhancedQuestionWidget({required EnhancedQuestion question, required currentAnswer, required void Function(dynamic answer) onAnswerChanged, required bool showHelpText}) {
}

