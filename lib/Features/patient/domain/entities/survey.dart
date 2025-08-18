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
