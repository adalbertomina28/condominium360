import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role; // admin, residente
  final String phone;
  final int? unitId;

  User({
    String? id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.unitId,
  }) : id = id ?? const Uuid().v4();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['nombre'],
      email: json['email'],
      role: json['rol'],
      phone: json['telefono'],
      unitId: json['unidad_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'rol': role,
      'telefono': phone,
      'unidad_id': unitId,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    int? unitId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      unitId: unitId ?? this.unitId,
    );
  }
}
