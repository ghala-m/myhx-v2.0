// Fixed Dynamic Medical History Screen
// lib/screens/dynamic_medical_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/question_model.dart';
import '../models/patient.dart';
import '../services/question_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';
import '../widgets/dynamic_question_widget.dart';
import 'patient_record_screen.dart';

class DynamicMedicalHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final String department;

  const DynamicMedicalHistoryScreen({
    super.key,
    required this.patient,
    required this.department,
  });

  @override
  State<DynamicMedicalHistoryScreen> createState() => _DynamicMedicalHistoryScreenState();
}

class _DynamicMedicalHistoryScreenState extends State<DynamicMedicalHistoryScreen> {
  final EnhancedQuestionService _questionService = EnhancedQuestionService();
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final AIService _aiService = AIService();
  final PageController _pageController = PageController();
  
  List<EnhancedQuestion> _allCurrentVisibleQuestions = []; // قائمة جميع الأسئلة المرئية حالياً بالترتيب
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _questionService.loadMedicalHistorySchema();
      
      _questionService.setPatientContext(
        age: widget.patient['age'],
        gender: widget.patient['gender'],
        department: widget.department,
      );
      
      _updateVisibleQuestions(); // تحميل الأسئلة الأولية
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading screen: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateVisibleQuestions() {
    // إعادة حساب جميع الأسئلة المرئية بناءً على الإجابات الحالية
    List<EnhancedQuestion> newVisibleQuestions = _questionService.getQuestionsForDisplay(
      department: widget.department,
      currentAnswers: _answers,
      patientAge: widget.patient['age'],
      patientGender: widget.patient['gender'],
    );

    setState(() {
      _allCurrentVisibleQuestions = newVisibleQuestions;
      // ضبط الفهرس إذا لم يعد السؤال الحالي مرئياً أو تجاوز العدد
      if (_currentQuestionIndex >= _allCurrentVisibleQuestions.length) {
        _currentQuestionIndex = _allCurrentVisibleQuestions.isEmpty ? 0 : _allCurrentVisibleQuestions.length - 1;
      }
      if (_currentQuestionIndex < 0 && _allCurrentVisibleQuestions.isNotEmpty) {
        _currentQuestionIndex = 0;
      }
    });
    
    // FIX: نقل jumpToPage خارج setState واستخدام post frame callback
    // هذا يضمن أن PageView يتم إعادة بنائه قبل القفز إلى الصفحة
    if (_allCurrentVisibleQuestions.isNotEmpty && _pageController.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          // التحقق من أن الفهرس الحالي صالح
          if (_currentQuestionIndex < _allCurrentVisibleQuestions.length) {
            _pageController.jumpToPage(_currentQuestionIndex);
          }
        }
      });
    }
  }

  void _onAnswerChanged(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
      _questionService.setAnswer(questionId, answer);
    });
    
    // FIX: تحديث الأسئلة المرئية بعد تأخير قصير لضمان انتقال سلس
    // هذا يسمح للواجهة بتحديث الإجابة الحالية قبل إعادة حساب الأسئلة
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _updateVisibleQuestions();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _allCurrentVisibleQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndExit(); // إذا كان هذا آخر سؤال مرئي، احفظ واخرج
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndExit() async {
    print("=== _saveAndExit START ===");
    
    if (_isSaving) {
      print("Already saving, ignoring duplicate call");
      return;
    }
    
    setState(() {
      _isSaving = true;
    });

    try {
      // التحقق من حالة تسجيل الدخول
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      print("User authenticated: ${user.uid}");

      // جمع جميع الإجابات
      final allAnswers = _questionService.getAllAnswers();
      print("Collected ${allAnswers.length} answers");

      // استخراج الأعراض لتحليل الذكاء الاصطناعي
      List<String> symptoms = [];
      allAnswers.forEach((key, value) {
        if (value != null) {
          if (value is Map && value.containsKey('mainAnswer')) {
            symptoms.add(value['mainAnswer'].toString());
            if (value.containsKey('additionalText') && value['additionalText'] != null) {
              symptoms.add(value['additionalText'].toString());
            }
          } else if (value is String && value.isNotEmpty && value.length > 2) {
            symptoms.add(value);
          } else if (value is List) {
            symptoms.addAll(value.map((e) => e.toString()));
          }
        }
      });
      print("Extracted ${symptoms.length} symptoms for AI analysis");

      // تحليل الذكاء الاصطناعي
      print("Calling AI service...");
      final analysisResult = await _aiService.analyzeSymptoms(
        symptoms.where((s) => s.isNotEmpty).toList(),
        {
          'age': (widget.patient['age'] ?? 0).toString(),
          'gender': widget.patient['gender'] ?? 'Unknown',
          'department': widget.department,
        },
      );
      print("AI analysis completed");

      // إنشاء كائن المريض
      final patientObj = Patient(
        id: widget.patient['id'] as String,
        name: widget.patient['name'] as String,
        age: widget.patient['age'] as int? ?? 0,
        gender: widget.patient['gender'] as String? ?? 'Unknown',
        dateOfBirth: DateTime.now().subtract(Duration(days: (widget.patient['age'] as int? ?? 0) * 365)),
        createdAt: DateTime.now(),
        department: widget.patient['department'] as String? ?? widget.department,
        wardNumber: widget.patient['wardNumber'] as String? ?? 'N/A',
        roomNumber: widget.patient['roomNumber'] as String? ?? 'N/A',
        doctorId: user.uid,
      );

      // حفظ التقرير في Firestore
      print("Creating report in Firestore...");
      final reportId = await _dbService.createReport(
        doctorId: user.uid,
        patientId: widget.patient['id'] as String,
        patient: patientObj,
        medicalHistory: allAnswers,
        aiAnalysis: analysisResult,
      );
      print("Report created successfully with ID: $reportId");
      print("=== _saveAndExit END (SUCCESS) ===");

      // الانتقال إلى شاشة سجل المريض
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PatientRecordScreen(
              reportId: reportId,
              patient: patientObj,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("ERROR in _saveAndExit: $e");
      print("Stack trace: $stackTrace");
      print("=== _saveAndExit END (ERROR) ===");
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveAndExit,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Medical History'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Medical History: ${widget.patient['name']}'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAndExit,
              tooltip: 'Save Report',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildQuestionProgressIndicator(),
          
          Expanded(
            child: _allCurrentVisibleQuestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'All questions completed',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can now save the data',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveAndExit,
                          child: const Text('Save and Exit'),
                        ),
                      ],
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // FIX: تعطيل السحب لمنع التعارضات
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemCount: _allCurrentVisibleQuestions.length,
                    itemBuilder: (context, index) {
                      EnhancedQuestion question = _allCurrentVisibleQuestions[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: DynamicQuestionWidget(
                          question: question,
                          answer: _answers[question.id],
                          onAnswerChanged: (answer) => _onAnswerChanged(question.id, answer), 
                          currentAnswer: _answers[question.id],
                        ),
                      );
                    },
                  ),
          ),
          
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildQuestionProgressIndicator() {
    if (_allCurrentVisibleQuestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_allCurrentVisibleQuestions.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _allCurrentVisibleQuestions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _isSaving || _currentQuestionIndex <= 0 ? null : _previousQuestion,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving 
                ? null 
                : (_allCurrentVisibleQuestions.isEmpty || _currentQuestionIndex == _allCurrentVisibleQuestions.length - 1
                    ? _saveAndExit
                    : _nextQuestion),
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _allCurrentVisibleQuestions.isEmpty || _currentQuestionIndex == _allCurrentVisibleQuestions.length - 1
                        ? Icons.save
                        : Icons.arrow_forward,
                  ),
            label: Text(
              _isSaving 
                  ? 'Saving...'
                  : (_allCurrentVisibleQuestions.isEmpty || _currentQuestionIndex == _allCurrentVisibleQuestions.length - 1
                      ? 'Save and Exit'
                      : 'Next'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
