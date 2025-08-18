import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/survey_repository.dart';
import '../../domain/entities/survey.dart';
import '../models/survey_model.dart';

class FirebaseSurveyRepositoryImpl implements SurveyRepository {
  final FirebaseFirestore _firestore;

  FirebaseSurveyRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Survey> submitSurvey({
    required String patientId,
    required String doctorId,
    required SurveyData surveyData,
  }) async {
    try {
      // Create a unique ID for the survey
      final surveyId = _firestore
          .collection('surveys')
          .doc(doctorId)
          .collection(patientId)
          .doc()
          .id;

      final surveyModel = SurveyModel(
        id: surveyId,
        patientId: patientId,
        doctorId: doctorId,
        timestamp: DateTime.now(),
        data: SurveyDataModel(
          hasChronicDiseases: surveyData.hasChronicDiseases,
          chronicDiseasesDetails: surveyData.chronicDiseasesDetails,
          isTakingMedications: surveyData.isTakingMedications,
          medicationsDetails: surveyData.medicationsDetails,
          hasAllergies: surveyData.hasAllergies,
          allergiesDetails: surveyData.allergiesDetails,
          symptoms: surveyData.symptoms,
          symptomsDuration: surveyData.symptomsDuration,
        ),
      );

      // Save to Firestore under the specified collection structure
      await _firestore
          .collection('surveys')
          .doc(doctorId)
          .collection(patientId)
          .doc(surveyId)
          .set(surveyModel.toJson());

      return surveyModel;
    } on FirebaseException catch (e) {
      throw SurveyException(
        'فشل في حفظ الاستبيان: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      throw SurveyException('فشل في حفظ الاستبيان: $e');
    }
  }

  @override
  Future<Survey?> getSurveyResponse({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('surveys')
          .doc(doctorId)
          .collection(patientId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return SurveyModel.fromJson({'id': doc.id, ...doc.data()});
    } on FirebaseException catch (e) {
      throw SurveyException(
        'فشل في جلب الاستبيان: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      throw SurveyException('فشل في جلب الاستبيان: $e');
    }
  }

  @override
  Future<List<Survey>> getPatientSurveys(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup(patientId)
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SurveyModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } on FirebaseException catch (e) {
      throw SurveyException(
        'فشل في جلب استبيانات المريض: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      throw SurveyException('فشل في جلب استبيانات المريض: $e');
    }
  }

  @override
  Future<List<Survey>> getDoctorSurveys(String doctorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('surveys')
          .doc(doctorId)
          .collection('all_surveys')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SurveyModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } on FirebaseException catch (e) {
      throw SurveyException(
        'فشل في جلب استبيانات الطبيب: ${_getFirebaseErrorMessage(e.code)}',
        code: e.code,
      );
    } catch (e) {
      throw SurveyException('فشل في جلب استبيانات الطبيب: $e');
    }
  }

  @override
  Future<bool> hasCompletedSurvey({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final survey = await getSurveyResponse(
        patientId: patientId,
        doctorId: doctorId,
      );
      return survey != null;
    } catch (e) {
      // If there's an error checking, assume no survey exists
      return false;
    }
  }

  /// Convert Firebase error codes to Arabic error messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية للوصول إلى هذه البيانات';
      case 'not-found':
        return 'البيانات غير موجودة';
      case 'already-exists':
        return 'البيانات موجودة بالفعل';
      case 'resource-exhausted':
        return 'تم استنفاد الموارد، يرجى المحاولة لاحقاً';
      case 'failed-precondition':
        return 'فشل في الشرط المسبق';
      case 'aborted':
        return 'تم إلغاء العملية';
      case 'out-of-range':
        return 'القيمة خارج النطاق المسموح';
      case 'unimplemented':
        return 'الميزة غير مطبقة';
      case 'internal':
        return 'خطأ داخلي في الخادم';
      case 'unavailable':
        return 'الخدمة غير متاحة حالياً';
      case 'data-loss':
        return 'فقدان البيانات';
      case 'unauthenticated':
        return 'غير مصادق عليه';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}
