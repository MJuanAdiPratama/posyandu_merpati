class ProfileModel {
  final String id;
  final String nama;
  final String email;
  final String? noHp;
  final String? alamat;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.nama,
    required this.email,
    this.noHp,
    this.alamat,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      email: json['email'] as String,
      noHp: json['no_hp'] as String?,
      alamat: json['alamat'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'no_hp': noHp,
      'alamat': alamat,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? nama,
    String? noHp,
    String? alamat,
    String? role,
    bool? isActive,
  }) {
    return ProfileModel(
      id: id,
      nama: nama ?? this.nama,
      email: email,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
