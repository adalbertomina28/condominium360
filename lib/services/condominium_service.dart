import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class CondominiumService {
  final SupabaseClient _supabaseClient;

  CondominiumService(this._supabaseClient);

  Future<List<Condominium>> getAllCondominiums() async {
    final response = await _supabaseClient.from('condominios').select();
    return response.map<Condominium>((json) => Condominium.fromJson(json)).toList();
  }

  Future<Condominium> getCondominiumById(String id) async {
    final response = await _supabaseClient
        .from('condominios')
        .select()
        .eq('id', id)
        .single();
    return Condominium.fromJson(response);
  }

  Future<Condominium> createCondominium(Condominium condominium) async {
    final response = await _supabaseClient
        .from('condominios')
        .insert(condominium.toJson())
        .select()
        .single();
    return Condominium.fromJson(response);
  }

  Future<Condominium> updateCondominium(Condominium condominium) async {
    final response = await _supabaseClient
        .from('condominios')
        .update(condominium.toJson())
        .eq('id', condominium.id)
        .select()
        .single();
    return Condominium.fromJson(response);
  }

  Future<void> deleteCondominium(String id) async {
    await _supabaseClient.from('condominios').delete().eq('id', id);
  }
}
