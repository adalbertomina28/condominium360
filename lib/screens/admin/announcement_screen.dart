import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({Key? key}) : super(key: key);

  @override
  _AdminAnnouncementScreenState createState() =>
      _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  List<Post> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final postService = PostService(SupabaseService.client);
      _announcements = await postService.getPostsByType('aviso');

      // Ordenar por fecha más reciente
      _announcements.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar anuncios: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService(SupabaseService.client);
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null) {
        throw Exception('Debes iniciar sesión para publicar anuncios');
      }

      if (currentUser.role != 'admin') {
        throw Exception('Solo los administradores pueden publicar anuncios');
      }

      final post = Post(
        id: 0, // ID será asignado por la base de datos
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: currentUser.id,
        date: DateTime.now(),
        type: 'aviso',
      );

      final postService = PostService(SupabaseService.client);
      await postService.createPost(post);

      // Limpiar formulario
      _titleController.clear();
      _contentController.clear();

      // Recargar anuncios
      await _loadAnnouncements();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anuncio publicado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar anuncio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final postService = PostService(SupabaseService.client);
      await postService.deletePost(id);

      // Recargar anuncios
      await _loadAnnouncements();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anuncio eliminado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar anuncio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Anuncios'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulario para crear anuncios
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nuevo Anuncio',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _titleController,
                              label: 'Título',
                              hint: 'Ingresa el título del anuncio',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa un título';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _contentController,
                              label: 'Contenido',
                              hint: 'Ingresa el contenido del anuncio',
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa el contenido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Publicar Anuncio',
                              icon: Icons.send,
                              onPressed: _createAnnouncement,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lista de anuncios existentes
                  const Text(
                    'Anuncios Publicados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _announcements.isEmpty
                      ? const Center(
                          child: Text('No hay anuncios publicados'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = _announcements[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            announcement.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteAnnouncement(
                                              announcement.id),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(announcement.content),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Publicado el ${_formatDate(announcement.date)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
