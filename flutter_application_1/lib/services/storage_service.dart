import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/aura_image.dart';

/// Service for managing image storage and retrieval
class StorageService {
  final ImagePicker _picker = ImagePicker();
  
  /// Get the app's document directory
  Future<Directory> get appDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    final auraDir = Directory('${dir.path}/Aura');
    if (!await auraDir.exists()) {
      await auraDir.create(recursive: true);
    }
    return auraDir;
  }
  
  /// Get the images directory
  Future<Directory> get imagesDirectory async {
    final appDir = await appDirectory;
    final imagesDir = Directory('${appDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }
  
  /// Get the edited images directory
  Future<Directory> get editedDirectory async {
    final appDir = await appDirectory;
    final editedDir = Directory('${appDir.path}/edited');
    if (!await editedDir.exists()) {
      await editedDir.create(recursive: true);
    }
    return editedDir;
  }
  
  /// Save a captured image
  Future<AuraImage> saveImage(XFile xFile) async {
    final imagesDir = await imagesDirectory;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'aura_$timestamp';
    final newPath = '${imagesDir.path}/$id.jpg';
    
    final file = File(xFile.path);
    await file.copy(newPath);
    
    final metadata = await _getImageMetadata(newPath);
    
    return AuraImage(
      id: id,
      path: newPath,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }
  
  /// Save edited image
  Future<String> saveEditedImage(String originalId, List<int> bytes) async {
    final editedDir = await editedDirectory;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '${editedDir.path}/${originalId}_edited_$timestamp.jpg';
    
    final file = File(newPath);
    await file.writeAsBytes(bytes);
    
    return newPath;
  }
  
  /// Pick image from gallery
  Future<AuraImage?> pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );
      
      if (pickedFile != null) {
        return saveImage(pickedFile);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }
  
  /// Pick multiple images from gallery
  Future<List<AuraImage>> pickMultipleFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );
      
      final images = <AuraImage>[];
      for (final file in pickedFiles) {
        final image = await saveImage(file);
        images.add(image);
      }
      return images;
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
    return [];
  }
  
  /// Get all saved images
  Future<List<AuraImage>> getAllImages() async {
    final imagesDir = await imagesDirectory;
    final files = await imagesDir.list().toList();
    
    final images = <AuraImage>[];
    for (final file in files) {
      if (file is File && file.path.endsWith('.jpg')) {
        final name = file.path.split('/').last.replaceAll('.jpg', '');
        final stat = await file.stat();
        final metadata = await _getImageMetadata(file.path);
        
        images.add(AuraImage(
          id: name,
          path: file.path,
          createdAt: stat.modified,
          metadata: metadata,
        ));
      }
    }
    
    // Sort by date, newest first
    images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return images;
  }
  
  /// Delete an image
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
    return false;
  }
  
  /// Get image metadata
  Future<ImageMetadata?> _getImageMetadata(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final stat = await file.stat();
      
      // Decode image to get dimensions
      final decodedImage = await decodeImageFromList(bytes);
      
      return ImageMetadata(
        width: decodedImage.width,
        height: decodedImage.height,
        fileSize: stat.size,
        mimeType: 'image/jpeg',
      );
    } catch (e) {
      debugPrint('Error getting metadata: $e');
      return null;
    }
  }
  
  /// Clear all app data
  Future<void> clearAllData() async {
    try {
      final appDir = await appDirectory;
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
  
  /// Get storage usage
  Future<int> getStorageUsage() async {
    int totalSize = 0;
    try {
      final appDir = await appDirectory;
      await for (final entity in appDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating storage: $e');
    }
    return totalSize;
  }
}

// Helper function to decode image
Future<ImageInfo> decodeImageFromList(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  final frame = await codec.getNextFrame();
  return ImageInfo(width: frame.image.width, height: frame.image.height);
}

class ImageInfo {
  final int width;
  final int height;
  ImageInfo({required this.width, required this.height});
}
