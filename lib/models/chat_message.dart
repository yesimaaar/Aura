class ChatMessage {
  final String? id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? imageBase64;

  ChatMessage({
    this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'imageBase64': imageBase64,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        content: json['content'] ?? '',
        isUser: json['isUser'] ?? true,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        imageBase64: json['imageBase64'],
      );
}
