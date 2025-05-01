import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupportTicketService {
  final SupabaseClient _supabaseClient;

  SupportTicketService(this._supabaseClient);

  Future<List<SupportTicket>> getTicketsByUnitId(String unitId) async {
    final response = await _supabaseClient
        .from('tickets_soporte')
        .select()
        .eq('unidad_id', unitId);
    return response.map<SupportTicket>((json) => SupportTicket.fromJson(json)).toList();
  }

  Future<List<SupportTicket>> getTicketsByStatus(String status) async {
    final response = await _supabaseClient
        .from('tickets_soporte')
        .select()
        .eq('estado', status);
    return response.map<SupportTicket>((json) => SupportTicket.fromJson(json)).toList();
  }

  Future<SupportTicket> getTicketById(String id) async {
    final response = await _supabaseClient
        .from('tickets_soporte')
        .select()
        .eq('id', id)
        .single();
    return SupportTicket.fromJson(response);
  }

  Future<SupportTicket> createTicket(SupportTicket ticket) async {
    final response = await _supabaseClient
        .from('tickets_soporte')
        .insert(ticket.toJson())
        .select()
        .single();
    return SupportTicket.fromJson(response);
  }

  Future<SupportTicket> updateTicketStatus(String id, String status) async {
    final response = await _supabaseClient
        .from('tickets_soporte')
        .update({'estado': status})
        .eq('id', id)
        .select()
        .single();
    return SupportTicket.fromJson(response);
  }

  Future<String> uploadImage(String filePath, String fileName) async {
    // Convertir el filePath a un objeto File de dart:io
    final file = File(filePath);
    
    final response = await _supabaseClient
        .storage
        .from('ticket_images')
        .upload(fileName, file);
    
    return _supabaseClient
        .storage
        .from('ticket_images')
        .getPublicUrl(response);
  }

  Future<void> deleteTicket(String id) async {
    await _supabaseClient.from('tickets_soporte').delete().eq('id', id);
  }
}
