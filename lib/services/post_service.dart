import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class PostService {
  final SupabaseClient _supabaseClient;

  PostService(this._supabaseClient);

  Future<List<Post>> getAllPosts() async {
    final response = await _supabaseClient
        .from('publicaciones')
        .select()
        .order('fecha', ascending: false);
    return response.map<Post>((json) => Post.fromJson(json)).toList();
  }

  Future<List<Post>> getPostsByType(String type) async {
    final response = await _supabaseClient
        .from('publicaciones')
        .select()
        .eq('tipo', type)
        .order('fecha', ascending: false);
    return response.map<Post>((json) => Post.fromJson(json)).toList();
  }

  Future<Post> getPostById(String id) async {
    final response = await _supabaseClient
        .from('publicaciones')
        .select()
        .eq('id', id)
        .single();
    return Post.fromJson(response);
  }

  Future<Post> createPost(Post post) async {
    final response = await _supabaseClient
        .from('publicaciones')
        .insert(post.toJson())
        .select()
        .single();
    return Post.fromJson(response);
  }

  Future<Post> updatePost(Post post) async {
    final response = await _supabaseClient
        .from('publicaciones')
        .update(post.toJson())
        .eq('id', post.id)
        .select()
        .single();
    return Post.fromJson(response);
  }

  Future<void> deletePost(String id) async {
    await _supabaseClient.from('publicaciones').delete().eq('id', id);
  }
}
