class Post {
  final String id;
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
    return {
      'id': id,
      'titulo': title,
      'contenido': content,
      'autor_id': authorId,
      'fecha': date.toIso8601String(),
      'tipo': type,
    };
  }

  Post copyWith({
    String? id,
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
