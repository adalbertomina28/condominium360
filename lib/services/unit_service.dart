import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class UnitService {
  final SupabaseClient _supabaseClient;

  UnitService(this._supabaseClient);

  Future<List<Unit>> getUnitsByCondominiumId(String condominiumId) async {
    final response = await _supabaseClient
        .from('unidades')
        .select()
        .eq('condominio_id', condominiumId);
    return response.map<Unit>((json) => Unit.fromJson(json)).toList();
  }

  Future<Unit> getUnitById(String id) async {
    final response = await _supabaseClient
        .from('unidades')
        .select()
        .eq('id', id)
        .single();
    return Unit.fromJson(response);
  }

  Future<Unit> createUnit(Unit unit) async {
    final response = await _supabaseClient
        .from('unidades')
        .insert(unit.toJson())
        .select()
        .single();
    return Unit.fromJson(response);
  }

  Future<Unit> updateUnit(Unit unit) async {
    final response = await _supabaseClient
        .from('unidades')
        .update(unit.toJson())
        .eq('id', unit.id)
        .select()
        .single();
    return Unit.fromJson(response);
  }

  Future<void> deleteUnit(String id) async {
    await _supabaseClient.from('unidades').delete().eq('id', id);
  }
}
