import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final String id;
  final String name;
  final String specialization;
  final double rating;
  final String availability;
  final String imageUrl;
  final String description;
  final List<String> availableTimeSlots;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.availability,
    this.imageUrl = '',
    this.description = '',
    this.availableTimeSlots = const [],
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: json['name'] as String,
      specialization: json['specialization'] as String,
      rating: (json['rating'] as num).toDouble(),
      availability: json['availability'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      availableTimeSlots: List<String>.from(json['availableTimeSlots'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'rating': rating,
      'availability': availability,
      'imageUrl': imageUrl,
      'description': description,
      'availableTimeSlots': availableTimeSlots,
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? specialization,
    double? rating,
    String? availability,
    String? imageUrl,
    String? description,
    List<String>? availableTimeSlots,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      rating: rating ?? this.rating,
      availability: availability ?? this.availability,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    specialization,
    rating,
    availability,
    imageUrl,
    description,
    availableTimeSlots,
  ];
}
