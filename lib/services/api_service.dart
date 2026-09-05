import 'dart:convert';
import 'package:http/http.dart' as http;

// نموذج البيانات لمطابقة استجابة JSON من الواجهة الخلفية
class AnalysisResult {
  final String summary;
  final List<Diagnosis> diagnoses;
  final List<String> purposes; // حقل جديد للأغراض/النوايا
  final Map<String, String> recommendations;

  AnalysisResult({
    required this.summary,
    required this.diagnoses,
    required this.purposes,
    required this.recommendations,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    var diagnosesList = json['diagnoses'] as List;
    List<Diagnosis> diagnoses = diagnosesList.map((i) => Diagnosis.fromJson(i)).toList();
    
    // معالجة حقل purposes الجديد
    List<String> purposes = [];
    if (json['purposes'] != null) {
      purposes = List<String>.from(json['purposes']);
    }

    return AnalysisResult(
      summary: json['summary'],
      diagnoses: diagnoses,
      purposes: purposes,
      recommendations: Map<String, String>.from(json['recommendations']),
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'diagnoses': diagnoses.map((d) => d.toJson()).toList(),
        'purposes': purposes, // إضافة purposes إلى التحويل لـ JSON
        'recommendations': recommendations,
      };
}

class Diagnosis {
  final String entity;
  final double score;
  final String word;

  Diagnosis({required this.entity, required this.score, required this.word});

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      entity: json['entity'],
      score: (json['score'] as num).toDouble(),
      word: json['word'],
    );
  }

  Map<String, dynamic> toJson() => {
        'entity': entity,
        'score': score,
        'word': word,
      };
}


class ApiService {
  // استخدم عنوان IP المحلي لجهازك إذا كنت تختبر على جهاز حقيقي
  // أو 10.0.2.2 لمحاكي أندرويد
  final String _baseUrl = "http://10.0.2.2:8000"; 

  Future<AnalysisResult> analyzeMedicalHistory(String medicalText) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': medicalText}),
    );

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      // التعامل مع الأخطاء بشكل أفضل في تطبيق حقيقي
      throw Exception('Failed to analyze medical history: ${response.body}');
    }
  }
}
