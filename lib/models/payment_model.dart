class Payment {
  final String id;
  final String unitId;
  final String description;
  final double amount;
  final String status; // pendiente/pagado
  final DateTime date;

  Payment({
    required this.id,
    required this.unitId,
    required this.description,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      unitId: json['unidad_id'],
      description: json['descripcion'],
      amount: json['monto'].toDouble(),
      status: json['estado'],
      date: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unidad_id': unitId,
      'descripcion': description,
      'monto': amount,
      'estado': status,
      'fecha': date.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? unitId,
    String? description,
    double? amount,
    String? status,
    DateTime? date,
  }) {
    return Payment(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }
}
