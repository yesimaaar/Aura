import 'dart:io';

class AuraImage {
  final String id;
  final String path;
  final DateTime timestamp;
  final bool isFavorite;

  AuraImage({
    required this.id,
    required this.path,
    required this.timestamp,
    this.isFavorite = false,
  });

  File get file => File(path);
}
