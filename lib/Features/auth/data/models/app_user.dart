import 'package:equatable/equatable.dart';

enum UserRole { patient, doctor }

class AppUser extends Equatable {
  final String id; // Firebase uid
  final String name; // stored in Firestore
  final String emailOrPhone; // email for now
  final UserRole role; // from Firestore

  const AppUser({
    required this.id,
    required this.name,
    required this.emailOrPhone,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      emailOrPhone: json['emailOrPhone'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.patient,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emailOrPhone': emailOrPhone,
      'role': role.name,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? emailOrPhone,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, name, emailOrPhone, role];

  @override
  String toString() {
    return 'AppUser(id: $id, name: $name, emailOrPhone: $emailOrPhone, role: $role)';
  }

  // Helper methods for role checking
  bool get isPatient => role == UserRole.patient;
  bool get isDoctor => role == UserRole.doctor;

  // Convert to string for display
  String get roleDisplayName {
    switch (role) {
      case UserRole.patient:
        return 'مريض';
      case UserRole.doctor:
        return 'دكتور';
    }
  }
}
