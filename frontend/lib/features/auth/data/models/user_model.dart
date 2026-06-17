class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final bool isVerified;
  final String? avatarUrl;
  final String? plan;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    required this.isVerified,
    this.avatarUrl,
    this.plan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      plan: json['plan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'avatarUrl': avatarUrl,
      'plan': plan,
    };
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts[0][0];
    return '${parts[0][0]}${parts[1][0]}';
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isVerified,
    String? avatarUrl,
    String? plan,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      plan: plan ?? this.plan,
    );
  }
}
