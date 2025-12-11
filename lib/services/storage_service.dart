import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/aura_image.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  Future<Directory> get _imagesDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<AuraImage> saveImage(XFile xFile) async {
    final dir = await _imagesDir;
    final timestamp = DateTime.now();
    final id = timestamp.millisecondsSinceEpoch.toString();
    final newPath = '${dir.path}/$id.jpg';
    
    await File(xFile.path).copy(newPath);
    
    return AuraImage(
      id: id,
      path: newPath,
      timestamp: timestamp,
    );
  }

  Future<AuraImage?> pickFromGallery() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      return saveImage(xFile);
    }
    return null;
  }
  
  Future<List<AuraImage>> getAllImages() async {
    final dir = await _imagesDir;
    final List<AuraImage> images = [];
    
    if (await dir.exists()) {
      final files = dir.listSync()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        
      for (var file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          final stat = await file.stat();
          final id = file.uri.pathSegments.last.split('.').first;
          images.add(AuraImage(
            id: id,
            path: file.path,
            timestamp: stat.modified,
          ));
        }
      }
    }
    return images;
  }

  Future<bool> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
    return false;
  }
}
