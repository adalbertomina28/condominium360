class CommonArea {
  final int id;
  final String name;
  final String description;
  final int condominiumId;

  CommonArea({
    required this.id,
    required this.name,
    required this.description,
    required this.condominiumId,
  });

  factory CommonArea.fromJson(Map<String, dynamic> json) {
    return CommonArea(
      id: json['id'],
      name: json['nombre'],
      description: json['descripcion'],
      condominiumId: json['condominio_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'descripcion': description,
      'condominio_id': condominiumId,
    };
  }

  CommonArea copyWith({
    int? id,
    String? name,
    String? description,
    int? condominiumId,
  }) {
    return CommonArea(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      condominiumId: condominiumId ?? this.condominiumId,
    );
  }
}
