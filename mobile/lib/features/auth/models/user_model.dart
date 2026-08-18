class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final String? avatarUrl;

  UserModel({required this.id, required this.name, required this.phone, this.email, required this.role, this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar_url'] as String? ?? json['avatarUrl'] as String?;
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'customer',
      avatarUrl: avatar,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'email': email, 'role': role, 'avatar_url': avatarUrl};
}
