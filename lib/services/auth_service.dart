import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/models.dart';

class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  Future<User?> getCurrentUser() async {
    final authUser = _supabaseClient.auth.currentUser;
    if (authUser == null) return null;

    final response = await _supabaseClient
        .from('usuarios')
        .select()
        .eq('id', authUser.id)
        .single();

    return User.fromJson(response);
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'residente',
    String? unitId,
  }) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Error al registrar el usuario');
    }

    final userData = {
      'id': response.user!.id,
      'nombre': name,
      'email': email,
      'rol': role,
      'telefono': phone,
      'unidad_id': unitId,
    };

    await _supabaseClient.from('usuarios').insert(userData);

    return User.fromJson(userData);
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Error al iniciar sesión');
    }

    final userData = await _supabaseClient
        .from('usuarios')
        .select()
        .eq('id', response.user!.id)
        .single();

    return User.fromJson(userData);
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
