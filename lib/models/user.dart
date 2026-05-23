import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true)
class User {
  final int id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'middle_name')
  final String? middleName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String? username;
  final String email;
  @JsonKey(name: 'contact_number')
  final String? phone;
  final String role;
  final String? status;
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;
  @JsonKey(name: 'verification_token_expiry')
  final String? verificationTokenExpiry;
  @JsonKey(name: 'reset_token_expiry')
  final String? resetTokenExpiry;
  @JsonKey(name: 'approved_by')
  final int? approvedBy;
  @JsonKey(name: 'approved_at')
  final String? approvedAt;
  @JsonKey(name: 'last_login')
  final String? lastLogin;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final List<dynamic>? barangays;

  User({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.username,
    required this.email,
    this.phone,
    required this.role,
    this.status,
    this.emailVerified,
    this.verificationTokenExpiry,
    this.resetTokenExpiry,
    this.approvedBy,
    this.approvedAt,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.fullName,
    this.barangays,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get name => middleName != null && middleName!.isNotEmpty
      ? '$firstName $middleName $lastName'
      : '$firstName $lastName';

  User copyWith({
    int? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? role,
    String? status,
    bool? emailVerified,
    String? verificationTokenExpiry,
    String? resetTokenExpiry,
    int? approvedBy,
    String? approvedAt,
    String? lastLogin,
    String? createdAt,
    String? updatedAt,
    String? fullName,
    List<dynamic>? barangays,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      verificationTokenExpiry: verificationTokenExpiry ?? this.verificationTokenExpiry,
      resetTokenExpiry: resetTokenExpiry ?? this.resetTokenExpiry,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      barangays: barangays ?? this.barangays,
    );
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isMidwife => role.toLowerCase() == 'midwife';

  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();
}
