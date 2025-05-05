class Reservation {
  final int id;
  final int unitId;
  final int commonAreaId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // pendiente/aprobada
  final int people; // Número de personas

  Reservation({
    required this.id,
    required this.unitId,
    required this.commonAreaId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.people = 1,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      unitId: json['unidad_id'],
      commonAreaId: json['area_comun_id'],
      startDate: DateTime.parse(json['fecha_inicio']),
      endDate: DateTime.parse(json['fecha_fin']),
      status: json['estado'],
      people: json['personas'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    // Crear un mapa base sin el ID
    final Map<String, dynamic> json = {
      'unidad_id': unitId,
      'area_comun_id': commonAreaId,
      'fecha_inicio': startDate.toIso8601String(),
      'fecha_fin': endDate.toIso8601String(),
      'estado': status,
      'personas': people,
    };

    // Solo incluir el ID si no es 0 (para actualizaciones)
    if (id != 0) {
      json['id'] = id;
    }

    return json;
  }

  Reservation copyWith({
    int? id,
    int? unitId,
    int? commonAreaId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? people,
  }) {
    return Reservation(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      commonAreaId: commonAreaId ?? this.commonAreaId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      people: people ?? this.people,
    );
  }
}
