import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class PaymentService {
  final SupabaseClient _supabaseClient;

  PaymentService(this._supabaseClient);

  Future<List<Payment>> getPaymentsByUnitId(String unitId) async {
    final response = await _supabaseClient
        .from('pagos')
        .select()
        .eq('unidad_id', unitId);
    return response.map<Payment>((json) => Payment.fromJson(json)).toList();
  }

  Future<List<Payment>> getPaymentsByStatus(String status) async {
    final response = await _supabaseClient
        .from('pagos')
        .select()
        .eq('estado', status);
    return response.map<Payment>((json) => Payment.fromJson(json)).toList();
  }

  Future<Payment> getPaymentById(String id) async {
    final response = await _supabaseClient
        .from('pagos')
        .select()
        .eq('id', id)
        .single();
    return Payment.fromJson(response);
  }

  Future<Payment> createPayment(Payment payment) async {
    final response = await _supabaseClient
        .from('pagos')
        .insert(payment.toJson())
        .select()
        .single();
    return Payment.fromJson(response);
  }

  Future<Payment> updatePaymentStatus(String id, String status) async {
    final response = await _supabaseClient
        .from('pagos')
        .update({'estado': status})
        .eq('id', id)
        .select()
        .single();
    return Payment.fromJson(response);
  }

  Future<void> deletePayment(String id) async {
    await _supabaseClient.from('pagos').delete().eq('id', id);
  }
}
