class Post {
  final int id;
  final String title;
  final String content;
  final String authorId;
  final DateTime date;
  final String type; // aviso, foro

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.date,
    required this.type,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['titulo'],
      content: json['contenido'],
      authorId: json['autor_id'],
      date: DateTime.parse(json['fecha']),
      type: json['tipo'],
    );
  }

  Map<String, dynamic> toJson() {
    // Si el ID es 0, lo omitimos para que la base de datos lo genere automáticamente
    final json = <String, dynamic>{
      'titulo': title,
      'contenido': content,
      'autor_id': authorId,
      'fecha': date.toIso8601String(),
      'tipo': type,
    };

    // Solo incluimos el ID si no es 0 (es decir, si estamos actualizando un post existente)
    if (id != 0) {
      json['id'] = id;
    }

    return json;
  }

  Post copyWith({
    int? id,
    String? title,
    String? content,
    String? authorId,
    DateTime? date,
    String? type,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }
}
