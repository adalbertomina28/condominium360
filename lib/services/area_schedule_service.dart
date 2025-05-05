import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/area_schedule_model.dart';
import '../models/area_capacity_model.dart';

class AreaScheduleService {
  final SupabaseClient _supabaseClient;

  AreaScheduleService(this._supabaseClient);

  // Obtener todos los horarios disponibles para un área común
  Future<List<AreaSchedule>> getSchedulesByAreaId(int areaId) async {
    final response = await _supabaseClient
        .from('area_horarios_disponibles')
        .select()
        .eq('area_comun_id', areaId)
        .order('dia_semana')
        .order('hora_inicio');
    
    return response.map<AreaSchedule>((json) => AreaSchedule.fromJson(json)).toList();
  }

  // Obtener la capacidad de un área común
  Future<AreaCapacity?> getAreaCapacity(int areaId) async {
    try {
      final response = await _supabaseClient
          .from('area_capacidad')
          .select()
          .eq('area_comun_id', areaId)
          .single();
      
      return AreaCapacity.fromJson(response);
    } catch (e) {
      // Si no hay capacidad definida, retornamos null
      return null;
    }
  }

  // Obtener los horarios disponibles para un día específico de la semana
  Future<List<AreaSchedule>> getSchedulesForWeekday(int areaId, String weekday) async {
    final response = await _supabaseClient
        .from('area_horarios_disponibles')
        .select()
        .eq('area_comun_id', areaId)
        .eq('dia_semana', weekday)
        .order('hora_inicio');
    
    return response.map<AreaSchedule>((json) => AreaSchedule.fromJson(json)).toList();
  }

  // Verificar si un horario está disponible (no hay reservas que lo ocupen)
  Future<bool> isTimeSlotAvailable(
    int areaId, 
    DateTime date, 
    String startTime, 
    String endTime,
    {int? excludeReservationId}
  ) async {
    // Convertir las horas de string a DateTime
    final startDateTime = DateTime(
      date.year, 
      date.month, 
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    
    final endDateTime = DateTime(
      date.year, 
      date.month, 
      date.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1]),
    );

    // Consultar reservas que se solapan con el horario solicitado
    var query = _supabaseClient
        .from('reservas')
        .select()
        .eq('area_comun_id', areaId)
        .lte('fecha_inicio', endDateTime.toIso8601String())
        .gte('fecha_fin', startDateTime.toIso8601String());
    
    // Si estamos actualizando una reserva, excluimos la reserva actual
    if (excludeReservationId != null) {
      query = query.neq('id', excludeReservationId);
    }
    
    final overlappingReservations = await query;
    
    // Si no hay reservas solapadas, el horario está disponible
    return overlappingReservations.isEmpty;
  }
}
