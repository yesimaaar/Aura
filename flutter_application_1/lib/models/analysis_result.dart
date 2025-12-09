/// Result of AI analysis on an image
class AnalysisResult {
  final String imageId;
  final DateTime analyzedAt;
  final List<SceneLabel> sceneLabels;
  final List<DetectedObjectResult> objects;
  final ColorAnalysis colorAnalysis;
  final QualityScore qualityScore;
  final List<String> suggestedEnhancements;
  
  const AnalysisResult({
    required this.imageId,
    required this.analyzedAt,
    this.sceneLabels = const [],
    this.objects = const [],
    required this.colorAnalysis,
    required this.qualityScore,
    this.suggestedEnhancements = const [],
  });
  
  bool get isEmpty => sceneLabels.isEmpty && objects.isEmpty;
  
  String get primaryScene => sceneLabels.isNotEmpty 
      ? sceneLabels.first.label 
      : 'Unknown';
}

/// Scene classification label
class SceneLabel {
  final String label;
  final double confidence;
  
  const SceneLabel({
    required this.label,
    required this.confidence,
  });
}

/// Detected object with detailed info
class DetectedObjectResult {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;
  final Map<String, dynamic>? attributes;
  
  const DetectedObjectResult({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.attributes,
  });
}

/// Color analysis results
class ColorAnalysis {
  final List<DominantColor> dominantColors;
  final double averageBrightness;
  final double colorfulness;
  final String colorTemperature;
  
  const ColorAnalysis({
    this.dominantColors = const [],
    this.averageBrightness = 0.5,
    this.colorfulness = 0.5,
    this.colorTemperature = 'neutral',
  });
}

/// Dominant color in image
class DominantColor {
  final int red;
  final int green;
  final int blue;
  final double percentage;
  
  const DominantColor({
    required this.red,
    required this.green,
    required this.blue,
    required this.percentage,
  });
  
  String get hexCode => '#${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

/// Image quality assessment
class QualityScore {
  final double overall;
  final double sharpness;
  final double exposure;
  final double noise;
  final double composition;
  
  const QualityScore({
    this.overall = 0.0,
    this.sharpness = 0.0,
    this.exposure = 0.0,
    this.noise = 0.0,
    this.composition = 0.0,
  });
  
  String get overallLabel {
    if (overall >= 0.8) return 'Excellent';
    if (overall >= 0.6) return 'Good';
    if (overall >= 0.4) return 'Fair';
    return 'Poor';
  }
}
