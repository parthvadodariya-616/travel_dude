// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool isVerifiedStudent;
  final int countriesVisited;
  final int upcomingTrips;
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.isVerifiedStudent = false,
    this.countriesVisited = 0,
    this.upcomingTrips = 0,
    this.points = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON (Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
      isVerifiedStudent: json['isVerifiedStudent'] ?? false,
      countriesVisited: json['countriesVisited'] ?? 0,
      upcomingTrips: json['upcomingTrips'] ?? 0,
      points: json['points'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isVerifiedStudent': isVerifiedStudent,
      'countriesVisited': countriesVisited,
      'upcomingTrips': upcomingTrips,
      'points': points,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isVerifiedStudent,
    int? countriesVisited,
    int? upcomingTrips,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isVerifiedStudent: isVerifiedStudent ?? this.isVerifiedStudent,
      countriesVisited: countriesVisited ?? this.countriesVisited,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }
}