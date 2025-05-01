class Condominium {
  final String id;
  final String name;
  final String address;
  final String accessCode;

  Condominium({
    required this.id,
    required this.name,
    required this.address,
    required this.accessCode,
  });

  factory Condominium.fromJson(Map<String, dynamic> json) {
    return Condominium(
      id: json['id'],
      name: json['nombre'],
      address: json['direccion'],
      accessCode: json['codigo_acceso'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'direccion': address,
      'codigo_acceso': accessCode,
    };
  }

  Condominium copyWith({
    String? id,
    String? name,
    String? address,
    String? accessCode,
  }) {
    return Condominium(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      accessCode: accessCode ?? this.accessCode,
    );
  }
}
