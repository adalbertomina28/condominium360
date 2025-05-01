class SupportTicket {
  final String id;
  final String unitId;
  final String title;
  final String description;
  final String? imageUrl;
  final String status; // nuevo, en proceso, resuelto
  final DateTime creationDate;

  SupportTicket({
    required this.id,
    required this.unitId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.creationDate,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      unitId: json['unidad_id'],
      title: json['titulo'],
      description: json['descripcion'],
      imageUrl: json['imagen_url'],
      status: json['estado'],
      creationDate: DateTime.parse(json['fecha_creacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unidad_id': unitId,
      'titulo': title,
      'descripcion': description,
      'imagen_url': imageUrl,
      'estado': status,
      'fecha_creacion': creationDate.toIso8601String(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? unitId,
    String? title,
    String? description,
    String? imageUrl,
    String? status,
    DateTime? creationDate,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      creationDate: creationDate ?? this.creationDate,
    );
  }
}
