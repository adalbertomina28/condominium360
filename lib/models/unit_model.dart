class Unit {
  final int id;
  final String apartmentNumber;
  final String floor;
  final int condominiumId;

  Unit({
    required this.id,
    required this.apartmentNumber,
    required this.floor,
    required this.condominiumId,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      apartmentNumber: json['numero_apto'],
      floor: json['piso'],
      condominiumId: json['condominio_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_apto': apartmentNumber,
      'piso': floor,
      'condominio_id': condominiumId,
    };
  }

  Unit copyWith({
    int? id,
    String? apartmentNumber,
    String? floor,
    int? condominiumId,
  }) {
    return Unit(
      id: id ?? this.id,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      floor: floor ?? this.floor,
      condominiumId: condominiumId ?? this.condominiumId,
    );
  }
}
