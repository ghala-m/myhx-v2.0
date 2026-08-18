import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/patient.dart';
import 'pdf_service.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final PdfService _pdfService = PdfService();

Future<File?> _generatePdfWithLoading(
    BuildContext context, {
    required Patient patient,
    required List<Map<String, dynamic>> medicalHistory,
    Map<String, dynamic>? aiAnalysis,
  }) async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfFile = await _pdfService.generatePatientReport(
        patient: patient,
        medicalHistory: medicalHistory,
        aiAnalysis: aiAnalysis,
      );
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل
      return pdfFile;
    } catch (e) {
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل في حالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء التقرير: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
  /// مشاركة تقرير المريض كملف PDF
  Future<void> sharePatientReport({
    required BuildContext context,
    required Patient patient,
    required List<Map<String, dynamic>> medicalHistory,
    Map<String, dynamic>? aiAnalysis,
  }) async {
    final pdfFile = await _generatePdfWithLoading(context, patient: patient, medicalHistory: medicalHistory, aiAnalysis: aiAnalysis);
    if (pdfFile == null) return; // الخروج إذا فشل إنشاء الملف

    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'Medical Report for ${patient.name}',
      subject: 'Patient Medical Report - ${patient.name}',
    );
  }

  /// طباعة تقرير المريض
  Future<void> printPatientReport({
    required BuildContext context,
    required Patient patient,
    required List<Map<String, dynamic>> medicalHistory,
    Map<String, dynamic>? aiAnalysis,
  }) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // إنشاء ملف PDF
      final pdfFile = await _pdfService.generatePatientReport(
        patient: patient,
        medicalHistory: medicalHistory,
        aiAnalysis: aiAnalysis,
      );

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // طباعة الملف
      await Printing.layoutPdf(
        onLayout: (format) => pdfFile.readAsBytes(),
        name: 'Medical_Report_${patient.name}_${DateTime.now().millisecondsSinceEpoch}',
      );

    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();
      
      // عرض رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في طباعة التقرير: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// حفظ تقرير المريض في التخزين المحلي
  Future<File?> savePatientReport({
    required BuildContext context,
    required Patient patient,
    required List<Map<String, dynamic>> medicalHistory,
    Map<String, dynamic>? aiAnalysis,
  }) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // إنشاء ملف PDF
      final pdfFile = await _pdfService.generatePatientReport(
        patient: patient,
        medicalHistory: medicalHistory,
        aiAnalysis: aiAnalysis,
      );

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ التقرير بنجاح في: ${pdfFile.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'مشاركة',
            onPressed: () async {
              await Share.shareXFiles([XFile(pdfFile.path)]);
            },
          ),
        ),
      );

      return pdfFile;

    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();
      
      // عرض رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ التقرير: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      return null;
    }
  }

  /// عرض خيارات المشاركة والطباعة
  Future<void> showShareOptions({
    required BuildContext context,
    required Patient patient,
    required List<Map<String, dynamic>> medicalHistory,
    Map<String, dynamic>? aiAnalysis,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'خيارات التقرير',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // خيار المشاركة
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share, color: Colors.blue),
              ),
              title: const Text('مشاركة التقرير'),
              subtitle: const Text('مشاركة التقرير كملف PDF'),
              onTap: () {
                Navigator.pop(context);
                sharePatientReport(
                  context: context,
                  patient: patient,
                  medicalHistory: medicalHistory,
                  aiAnalysis: aiAnalysis,
                );
              },
            ),
            
            // خيار الطباعة
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.print, color: Colors.green),
              ),
              title: const Text('طباعة التقرير'),
              subtitle: const Text('طباعة التقرير مباشرة'),
              onTap: () {
                Navigator.pop(context);
                printPatientReport(
                  context: context,
                  patient: patient,
                  medicalHistory: medicalHistory,
                  aiAnalysis: aiAnalysis,
                );
              },
            ),
            
            // خيار الحفظ
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.save, color: Colors.orange),
              ),
              title: const Text('حفظ التقرير'),
              subtitle: const Text('حفظ التقرير في الجهاز'),
              onTap: () {
                Navigator.pop(context);
                savePatientReport(
                  context: context,
                  patient: patient,
                  medicalHistory: medicalHistory,
                  aiAnalysis: aiAnalysis,
                );
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// التحقق من صحة البيانات قبل إنشاء التقرير
  bool validateReportData({
    required Patient patient,
    required List<Map<String, dynamic>> medicalHistory,
  }) {
    if (patient.name.isEmpty) return false;
    if (patient.age <= 0) return false;
    if (medicalHistory.isEmpty) return false;
    
    return true;
  }

  /// الحصول على مسار مجلد التقارير
  Future<Directory> getReportsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${appDir.path}/medical_reports');
    
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    
    return reportsDir;
  }

  /// حذف التقارير القديمة (أكثر من 30 يوم)
  Future<void> cleanupOldReports() async {
    try {
      final reportsDir = await getReportsDirectory();
      final files = reportsDir.listSync();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(thirtyDaysAgo)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old reports: $e');
    }
  }
}

