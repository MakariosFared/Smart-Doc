import 'package:equatable/equatable.dart';

class Survey extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime timestamp;
  final SurveyData data;

  const Survey({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.timestamp,
    required this.data,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: SurveyData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'timestamp': timestamp.toIso8601String(),
      'data': data.toJson(),
    };
  }

  Survey copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? timestamp,
    SurveyData? data,
  }) {
    return Survey(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [id, patientId, doctorId, timestamp, data];
}

class SurveyData extends Equatable {
  final bool hasChronicDiseases;
  final String? chronicDiseasesDetails;
  final bool isTakingMedications;
  final String? medicationsDetails;
  final bool hasAllergies;
  final String? allergiesDetails;
  final String symptoms;
  final String symptomsDuration;

  const SurveyData({
    required this.hasChronicDiseases,
    this.chronicDiseasesDetails,
    required this.isTakingMedications,
    this.medicationsDetails,
    required this.hasAllergies,
    this.allergiesDetails,
    required this.symptoms,
    required this.symptomsDuration,
  });

  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
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

  SurveyData copyWith({
    bool? hasChronicDiseases,
    String? chronicDiseasesDetails,
    bool? isTakingMedications,
    String? medicationsDetails,
    bool? hasAllergies,
    String? allergiesDetails,
    String? symptoms,
    String? symptomsDuration,
  }) {
    return SurveyData(
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

  @override
  List<Object?> get props => [
    hasChronicDiseases,
    chronicDiseasesDetails,
    isTakingMedications,
    medicationsDetails,
    hasAllergies,
    allergiesDetails,
    symptoms,
    symptomsDuration,
  ];
}
