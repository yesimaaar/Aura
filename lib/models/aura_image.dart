import 'dart:io';

/// Represents an image being processed in the app
class AuraImage {
  final String id;
  final String path;
  final DateTime createdAt;
  final ImageMetadata? metadata;
  final List<DetectedObject> detectedObjects;
  final ImageEnhancements enhancements;
  
  AuraImage({
    required this.id,
    required this.path,
    required this.createdAt,
    this.metadata,
    this.detectedObjects = const [],
    ImageEnhancements? enhancements,
  }) : enhancements = enhancements ?? ImageEnhancements();
  
  File get file => File(path);
  
  bool get hasAnalysis => detectedObjects.isNotEmpty;
  
  AuraImage copyWith({
    String? id,
    String? path,
    DateTime? createdAt,
    ImageMetadata? metadata,
    List<DetectedObject>? detectedObjects,
    ImageEnhancements? enhancements,
  }) {
    return AuraImage(
      id: id ?? this.id,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      enhancements: enhancements ?? this.enhancements,
    );
  }
}

/// Metadata for an image
class ImageMetadata {
  final int width;
  final int height;
  final int fileSize;
  final String? mimeType;
  final Map<String, dynamic>? exifData;
  
  const ImageMetadata({
    required this.width,
    required this.height,
    required this.fileSize,
    this.mimeType,
    this.exifData,
  });
  
  double get aspectRatio => width / height;
  
  String get resolution => '${width}x$height';
  
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Represents a detected object in an image
class DetectedObject {
  final String label;
  final double confidence;
  final BoundingBox boundingBox;
  final String? category;
  
  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.category,
  });
  
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}

/// Bounding box for detected objects
class BoundingBox {
  final double left;
  final double top;
  final double width;
  final double height;
  
  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  
  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
}

/// Image enhancement parameters
class ImageEnhancements {
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;
  final double warmth;
  final double exposure;
  final double highlights;
  final double shadows;
  final String? filterName;
  
  const ImageEnhancements({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.sharpness = 0.0,
    this.warmth = 0.0,
    this.exposure = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.filterName,
  });
  
  bool get hasChanges =>
      brightness != 0.0 ||
      contrast != 1.0 ||
      saturation != 1.0 ||
      sharpness != 0.0 ||
      warmth != 0.0 ||
      exposure != 0.0 ||
      highlights != 0.0 ||
      shadows != 0.0 ||
      filterName != null;
  
  ImageEnhancements copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
    double? warmth,
    double? exposure,
    double? highlights,
    double? shadows,
    String? filterName,
  }) {
    return ImageEnhancements(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      sharpness: sharpness ?? this.sharpness,
      warmth: warmth ?? this.warmth,
      exposure: exposure ?? this.exposure,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      filterName: filterName ?? this.filterName,
    );
  }
  
  ImageEnhancements reset() => const ImageEnhancements();
}

/// Filter preset for quick image styling
class ImageFilter {
  final String id;
  final String name;
  final String iconPath;
  final ImageEnhancements enhancements;
  
  const ImageFilter({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.enhancements,
  });
  
  static const List<ImageFilter> presets = [
    ImageFilter(
      id: 'original',
      name: 'Original',
      iconPath: '',
      enhancements: ImageEnhancements(),
    ),
    ImageFilter(
      id: 'vivid',
      name: 'Vivid',
      iconPath: '',
      enhancements: ImageEnhancements(
        saturation: 1.3,
        contrast: 1.1,
      ),
    ),
    ImageFilter(
      id: 'warm',
      name: 'Warm',
      iconPath: '',
      enhancements: ImageEnhancements(
        warmth: 0.3,
        saturation: 1.1,
      ),
    ),
    ImageFilter(
      id: 'cool',
      name: 'Cool',
      iconPath: '',
      enhancements: ImageEnhancements(
        warmth: -0.2,
        contrast: 1.05,
      ),
    ),
    ImageFilter(
      id: 'dramatic',
      name: 'Dramatic',
      iconPath: '',
      enhancements: ImageEnhancements(
        contrast: 1.3,
        shadows: -0.2,
        highlights: 0.1,
      ),
    ),
    ImageFilter(
      id: 'noir',
      name: 'Noir',
      iconPath: '',
      enhancements: ImageEnhancements(
        saturation: 0.0,
        contrast: 1.2,
      ),
    ),
  ];
}
