import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/aura_image.dart';

/// Service for image enhancement and processing
class ImageEnhancementService {
  /// Apply automatic enhancement to an image
  Future<Uint8List> autoEnhance(File imageFile) async {
    return compute(_autoEnhanceImage, imageFile.path);
  }
  
  /// Apply specific enhancements to an image
  Future<Uint8List> applyEnhancements(
    File imageFile,
    ImageEnhancements enhancements,
  ) async {
    final params = _EnhancementParams(
      imagePath: imageFile.path,
      enhancements: enhancements,
    );
    return compute(_applyEnhancements, params);
  }
  
  /// Apply a preset filter to an image
  Future<Uint8List> applyFilter(File imageFile, ImageFilter filter) async {
    return applyEnhancements(imageFile, filter.enhancements);
  }
  
  /// Get image preview with enhancements (faster, lower quality)
  Future<Uint8List> getEnhancedPreview(
    File imageFile,
    ImageEnhancements enhancements, {
    int maxSize = 512,
  }) async {
    final params = _EnhancementParams(
      imagePath: imageFile.path,
      enhancements: enhancements,
      previewSize: maxSize,
    );
    return compute(_applyEnhancements, params);
  }
  
  /// Crop image to specified rectangle
  Future<Uint8List> cropImage(
    File imageFile,
    int x,
    int y,
    int width,
    int height,
  ) async {
    final params = _CropParams(
      imagePath: imageFile.path,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    return compute(_cropImage, params);
  }
  
  /// Rotate image by degrees
  Future<Uint8List> rotateImage(File imageFile, int degrees) async {
    final params = _RotateParams(
      imagePath: imageFile.path,
      degrees: degrees,
    );
    return compute(_rotateImage, params);
  }
  
  /// Flip image horizontally or vertically
  Future<Uint8List> flipImage(File imageFile, {bool horizontal = true}) async {
    final params = _FlipParams(
      imagePath: imageFile.path,
      horizontal: horizontal,
    );
    return compute(_flipImage, params);
  }
}

// Parameter classes for isolate functions
class _EnhancementParams {
  final String imagePath;
  final ImageEnhancements enhancements;
  final int? previewSize;
  
  _EnhancementParams({
    required this.imagePath,
    required this.enhancements,
    this.previewSize,
  });
}

class _CropParams {
  final String imagePath;
  final int x, y, width, height;
  
  _CropParams({
    required this.imagePath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class _RotateParams {
  final String imagePath;
  final int degrees;
  
  _RotateParams({required this.imagePath, required this.degrees});
}

class _FlipParams {
  final String imagePath;
  final bool horizontal;
  
  _FlipParams({required this.imagePath, required this.horizontal});
}

// Isolate functions for heavy processing
Uint8List _autoEnhanceImage(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  var image = img.decodeImage(bytes);
  
  if (image == null) return bytes;
  
  // Auto-adjust contrast
  image = img.contrast(image, contrast: 110);
  
  // Auto-adjust brightness (normalize)
  image = img.normalize(image, min: 0, max: 255);
  
  // Apply subtle sharpening
  image = img.convolution(image, filter: [
    0, -0.5, 0,
    -0.5, 3, -0.5,
    0, -0.5, 0,
  ]);
  
  // Adjust saturation slightly
  image = img.adjustColor(image, saturation: 1.1);
  
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

Uint8List _applyEnhancements(dynamic params) {
  final p = params as _EnhancementParams;
  final bytes = File(p.imagePath).readAsBytesSync();
  var image = img.decodeImage(bytes);
  
  if (image == null) return bytes;
  
  // Resize for preview if needed
  if (p.previewSize != null) {
    final scale = p.previewSize! / (image.width > image.height ? image.width : image.height);
    if (scale < 1) {
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }
  }
  
  final e = p.enhancements;
  
  // Apply brightness
  if (e.brightness != 0) {
    final brightnessValue = (e.brightness * 100).round();
    image = img.adjustColor(image, brightness: 1 + (brightnessValue / 100));
  }
  
  // Apply contrast
  if (e.contrast != 1.0) {
    image = img.contrast(image, contrast: (e.contrast * 100).round());
  }
  
  // Apply saturation
  if (e.saturation != 1.0) {
    image = img.adjustColor(image, saturation: e.saturation);
  }
  
  // Apply warmth (color temperature)
  if (e.warmth != 0) {
    // Positive = warmer (more orange), negative = cooler (more blue)
    if (e.warmth > 0) {
      image = img.colorOffset(
        image,
        red: (e.warmth * 30).round(),
        blue: -(e.warmth * 20).round(),
      );
    } else {
      image = img.colorOffset(
        image,
        red: (e.warmth * 20).round(),
        blue: -(e.warmth * 30).round(),
      );
    }
  }
  
  // Apply sharpening
  if (e.sharpness > 0) {
    final strength = e.sharpness * 2;
    image = img.convolution(image, filter: [
      0, -strength, 0,
      -strength, 1 + 4 * strength, -strength,
      0, -strength, 0,
    ]);
  }
  
  // Apply exposure
  if (e.exposure != 0) {
    final gamma = 1 / (1 + e.exposure);
    image = img.adjustColor(image, gamma: gamma);
  }
  
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

Uint8List _cropImage(_CropParams params) {
  final bytes = File(params.imagePath).readAsBytesSync();
  var image = img.decodeImage(bytes);
  
  if (image == null) return bytes;
  
  image = img.copyCrop(
    image,
    x: params.x,
    y: params.y,
    width: params.width,
    height: params.height,
  );
  
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

Uint8List _rotateImage(_RotateParams params) {
  final bytes = File(params.imagePath).readAsBytesSync();
  var image = img.decodeImage(bytes);
  
  if (image == null) return bytes;
  
  image = img.copyRotate(image, angle: params.degrees.toDouble());
  
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

Uint8List _flipImage(_FlipParams params) {
  final bytes = File(params.imagePath).readAsBytesSync();
  var image = img.decodeImage(bytes);
  
  if (image == null) return bytes;
  
  if (params.horizontal) {
    image = img.flipHorizontal(image);
  } else {
    image = img.flipVertical(image);
  }
  
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}
