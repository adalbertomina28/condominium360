import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class CommonAreaService {
  final SupabaseClient _supabaseClient;

  CommonAreaService(this._supabaseClient);

  Future<List<CommonArea>> getCommonAreasByCondominiumId(
      int condominiumId) async {
    final response = await _supabaseClient
        .from('areas_comunes')
        .select()
        .eq('condominio_id', condominiumId);
    return response
        .map<CommonArea>((json) => CommonArea.fromJson(json))
        .toList();
  }

  Future<CommonArea> getCommonAreaById(int id) async {
    final response = await _supabaseClient
        .from('areas_comunes')
        .select()
        .eq('id', id)
        .single();
    return CommonArea.fromJson(response);
  }

  Future<CommonArea> createCommonArea(CommonArea commonArea) async {
    final response = await _supabaseClient
        .from('areas_comunes')
        .insert(commonArea.toJson())
        .select()
        .single();
    return CommonArea.fromJson(response);
  }

  Future<CommonArea> updateCommonArea(CommonArea commonArea) async {
    final response = await _supabaseClient
        .from('areas_comunes')
        .update(commonArea.toJson())
        .eq('id', commonArea.id)
        .select()
        .single();
    return CommonArea.fromJson(response);
  }

  Future<void> deleteCommonArea(String id) async {
    await _supabaseClient.from('areas_comunes').delete().eq('id', id);
  }
}
