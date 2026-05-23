// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      phone: json['contact_number'] as String?,
      role: json['role'] as String,
      status: json['status'] as String?,
      emailVerified: json['email_verified'] as bool?,
      verificationTokenExpiry: json['verification_token_expiry'] as String?,
      resetTokenExpiry: json['reset_token_expiry'] as String?,
      approvedBy: (json['approved_by'] as num?)?.toInt(),
      approvedAt: json['approved_at'] as String?,
      lastLogin: json['last_login'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      fullName: json['full_name'] as String?,
      barangays: json['barangays'] as List<dynamic>?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'middle_name': instance.middleName,
      'last_name': instance.lastName,
      'username': instance.username,
      'email': instance.email,
      'contact_number': instance.phone,
      'role': instance.role,
      'status': instance.status,
      'email_verified': instance.emailVerified,
      'verification_token_expiry': instance.verificationTokenExpiry,
      'reset_token_expiry': instance.resetTokenExpiry,
      'approved_by': instance.approvedBy,
      'approved_at': instance.approvedAt,
      'last_login': instance.lastLogin,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'full_name': instance.fullName,
      'barangays': instance.barangays,
    };
