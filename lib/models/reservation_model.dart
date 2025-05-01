class Reservation {
  final String id;
  final String unitId;
  final String commonAreaId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // pendiente/aprobada

  Reservation({
    required this.id,
    required this.unitId,
    required this.commonAreaId,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      unitId: json['unidad_id'],
      commonAreaId: json['area_comun_id'],
      startDate: DateTime.parse(json['fecha_inicio']),
      endDate: DateTime.parse(json['fecha_fin']),
      status: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unidad_id': unitId,
      'area_comun_id': commonAreaId,
      'fecha_inicio': startDate.toIso8601String(),
      'fecha_fin': endDate.toIso8601String(),
      'estado': status,
    };
  }

  Reservation copyWith({
    String? id,
    String? unitId,
    String? commonAreaId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return Reservation(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      commonAreaId: commonAreaId ?? this.commonAreaId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }
}
