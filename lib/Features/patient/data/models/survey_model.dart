import '../../domain/entities/survey.dart';

class SurveyModel extends Survey {
  const SurveyModel({
    required super.id,
    required super.patientId,
    required super.doctorId,
    required super.timestamp,
    required super.data,
  });

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: SurveyDataModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'timestamp': timestamp.toIso8601String(),
      'data': (data as SurveyDataModel).toJson(),
    };
  }

  SurveyModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? timestamp,
    SurveyData? data,
  }) {
    return SurveyModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }
}

class SurveyDataModel extends SurveyData {
  const SurveyDataModel({
    required super.hasChronicDiseases,
    super.chronicDiseasesDetails,
    required super.isTakingMedications,
    super.medicationsDetails,
    required super.hasAllergies,
    super.allergiesDetails,
    required super.symptoms,
    required super.symptomsDuration,
  });

  factory SurveyDataModel.fromJson(Map<String, dynamic> json) {
    return SurveyDataModel(
      hasChronicDiseases: json['hasChronicDiseases'] as bool,
      chronicDiseasesDetails: json['chronicDiseasesDetails'] as String?,
      isTakingMedications: json['isTakingMedications'] as bool,
      medicationsDetails: json['medicationsDetails'] as String?,
      hasAllergies: json['hasAllergies'] as bool,
      allergiesDetails: json['allergiesDetails'] as String?,
      symptoms: json['symptoms'] as String,
      symptomsDuration: json['symptomsDuration'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasChronicDiseases': hasChronicDiseases,
      'chronicDiseasesDetails': chronicDiseasesDetails,
      'isTakingMedications': isTakingMedications,
      'medicationsDetails': medicationsDetails,
      'hasAllergies': hasAllergies,
      'allergiesDetails': allergiesDetails,
      'symptoms': symptoms,
      'symptomsDuration': symptomsDuration,
    };
  }

  SurveyDataModel copyWith({
    bool? hasChronicDiseases,
    String? chronicDiseasesDetails,
    bool? isTakingMedications,
    String? medicationsDetails,
    bool? hasAllergies,
    String? allergiesDetails,
    String? symptoms,
    String? symptomsDuration,
  }) {
    return SurveyDataModel(
      hasChronicDiseases: hasChronicDiseases ?? this.hasChronicDiseases,
      chronicDiseasesDetails:
          chronicDiseasesDetails ?? this.chronicDiseasesDetails,
      isTakingMedications: isTakingMedications ?? this.isTakingMedications,
      medicationsDetails: medicationsDetails ?? this.medicationsDetails,
      hasAllergies: hasAllergies ?? this.hasAllergies,
      allergiesDetails: allergiesDetails ?? this.allergiesDetails,
      symptoms: symptoms ?? this.symptoms,
      symptomsDuration: symptomsDuration ?? this.symptomsDuration,
    );
  }
}
