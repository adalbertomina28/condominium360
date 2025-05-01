import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ReservationService {
  final SupabaseClient _supabaseClient;

  ReservationService(this._supabaseClient);

  Future<List<Reservation>> getReservationsByUnitId(String unitId) async {
    final response = await _supabaseClient
        .from('reservas')
        .select()
        .eq('unidad_id', unitId);
    return response.map<Reservation>((json) => Reservation.fromJson(json)).toList();
  }

  Future<List<Reservation>> getReservationsByCommonAreaId(String commonAreaId) async {
    final response = await _supabaseClient
        .from('reservas')
        .select()
        .eq('area_comun_id', commonAreaId);
    return response.map<Reservation>((json) => Reservation.fromJson(json)).toList();
  }

  Future<List<Reservation>> getReservationsByDateRange(DateTime startDate, DateTime endDate) async {
    final response = await _supabaseClient
        .from('reservas')
        .select()
        .gte('fecha_inicio', startDate.toIso8601String())
        .lte('fecha_fin', endDate.toIso8601String());
    return response.map<Reservation>((json) => Reservation.fromJson(json)).toList();
  }

  Future<Reservation> createReservation(Reservation reservation) async {
    // Verificar si hay conflictos con otras reservas
    final conflicts = await _supabaseClient
        .from('reservas')
        .select()
        .eq('area_comun_id', reservation.commonAreaId)
        .or('fecha_inicio.lte.${reservation.endDate.toIso8601String()},fecha_fin.gte.${reservation.startDate.toIso8601String()}')
        .eq('estado', 'aprobada');

    if (conflicts.isNotEmpty) {
      throw Exception('Ya existe una reserva para esta área común en el horario seleccionado');
    }

    final response = await _supabaseClient
        .from('reservas')
        .insert(reservation.toJson())
        .select()
        .single();
    return Reservation.fromJson(response);
  }

  Future<Reservation> updateReservationStatus(String id, String status) async {
    final response = await _supabaseClient
        .from('reservas')
        .update({'estado': status})
        .eq('id', id)
        .select()
        .single();
    return Reservation.fromJson(response);
  }

  Future<void> deleteReservation(String id) async {
    await _supabaseClient.from('reservas').delete().eq('id', id);
  }
}
