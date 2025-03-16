enum UserRole {
  innovator,
  investor,
}

class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final UserRole role;
  final String? profileImage;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    this.profileImage,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.toString() == json['role'],
        orElse: () => UserRole.investor,
      ),
      profileImage: json['profileImage'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'role': role.toString(),
      'profileImage': profileImage,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    UserRole? role,
    String? profileImage,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      preferences: preferences ?? this.preferences,
    );
  }
}
