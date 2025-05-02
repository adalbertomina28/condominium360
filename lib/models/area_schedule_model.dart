import 'package:flutter/material.dart';

class AreaSchedule {
  final int id;
  final int areaId;
  final String weekday;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  AreaSchedule({
    required this.id,
    required this.areaId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  factory AreaSchedule.fromJson(Map<String, dynamic> json) {
    // Convertir hora_inicio y hora_fin de formato "HH:MM:SS" a TimeOfDay
    final startTimeParts = json['hora_inicio'].toString().split(':');
    final endTimeParts = json['hora_fin'].toString().split(':');

    return AreaSchedule(
      id: json['id'],
      areaId: json['area_comun_id'],
      weekday: json['dia_semana'],
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area_comun_id': areaId,
      'dia_semana': weekday,
      'hora_inicio': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'hora_fin': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
    };
  }

  // Método para convertir el nombre del día en español al índice de día de la semana (1-7, lunes-domingo)
  static int weekdayToIndex(String weekday) {
    const Map<String, int> weekdayMap = {
      'lunes': 1,
      'martes': 2,
      'miércoles': 3,
      'jueves': 4,
      'viernes': 5,
      'sábado': 6,
      'domingo': 7,
    };
    return weekdayMap[weekday] ?? 1;
  }

  // Método para convertir el índice de día de la semana al nombre en español
  static String indexToWeekday(int index) {
    const Map<int, String> weekdayMap = {
      1: 'lunes',
      2: 'martes',
      3: 'miércoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sábado',
      7: 'domingo',
    };
    return weekdayMap[index] ?? 'lunes';
  }

  // Método para obtener el nombre del día en español formateado con mayúscula inicial
  String get formattedWeekday {
    return weekday.substring(0, 1).toUpperCase() + weekday.substring(1);
  }

  // Método para formatear la hora de inicio y fin
  String get timeRange {
    final startFormatted = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endFormatted = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startFormatted - $endFormatted';
  }
}
