import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/aura_image.dart';
import '../models/analysis_result.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';
import '../services/image_analysis_service.dart';
import '../services/image_enhancement_service.dart';
import '../services/gemini_service.dart';

/// Main state provider for the Aura app
class AuraProvider extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final StorageService _storageService = StorageService();
  final ImageAnalysisService _analysisService = ImageAnalysisService();
  final ImageEnhancementService _enhancementService = ImageEnhancementService();
  final GeminiService _geminiService = GeminiService();
  
  // Camera state
  CameraService get camera => _cameraService;
  
  // Gemini service
  GeminiService get gemini => _geminiService;
  bool get isGeminiReady => _geminiService.isInitialized;
  
  /// Chat with Aura (text only)
  Future<String> chatWithAura(String message) async {
    return await _geminiService.sendMessage(message);
  }
  
  /// Chat with Aura including an image
  Future<String> chatWithAuraAndImage(String message, File image) async {
    return await _geminiService.analyzeImage(image, prompt: message);
  }
  
  /// Analyze live view frame
  Future<List<String>> analyzeLiveFrame(Uint8List imageBytes, String context) async {
    return await _geminiService.analyzeLiveView(imageBytes, context);
  }
  
  // Current image state
  AuraImage? _currentImage;
  AuraImage? get currentImage => _currentImage;
  
  // Gallery state
  List<AuraImage> _galleryImages = [];
  List<AuraImage> get galleryImages => _galleryImages;
  
  // Analysis state
  AnalysisResult? _analysisResult;
  AnalysisResult? get analysisResult => _analysisResult;
  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;
  
  // Enhancement state
  ImageEnhancements _currentEnhancements = const ImageEnhancements();
  ImageEnhancements get currentEnhancements => _currentEnhancements;
  Uint8List? _enhancedPreview;
  Uint8List? get enhancedPreview => _enhancedPreview;
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  
  // UI state
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _cameraService.initialize();
      await _analysisService.loadModels();
      await _geminiService.initialize();
      await loadGallery();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AuraProvider: $e');
      rethrow;
    }
  }
  
  /// Take a photo
  Future<AuraImage?> takePhoto() async {
    try {
      final xFile = await _cameraService.takePhoto();
      if (xFile != null) {
        final image = await _storageService.saveImage(xFile);
        _currentImage = image;
        _galleryImages.insert(0, image);
        _resetEnhancements();
        notifyListeners();
        return image;
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
    return null;
  }
  
  /// Pick image from gallery
  Future<AuraImage?> pickFromGallery() async {
    try {
      final image = await _storageService.pickFromGallery();
      if (image != null) {
        _currentImage = image;
        _galleryImages.insert(0, image);
        _resetEnhancements();
        notifyListeners();
        return image;
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
    }
    return null;
  }
  
  /// Load gallery images
  Future<void> loadGallery() async {
    try {
      _galleryImages = await _storageService.getAllImages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading gallery: $e');
    }
  }
  
  /// Set current image for editing
  void setCurrentImage(AuraImage image) {
    _currentImage = image;
    _resetEnhancements();
    notifyListeners();
  }
  
  /// Analyze current image
  Future<void> analyzeImage() async {
    if (_currentImage == null || _isAnalyzing) return;
    
    _isAnalyzing = true;
    notifyListeners();
    
    try {
      _analysisResult = await _analysisService.analyzeImage(_currentImage!);
    } catch (e) {
      debugPrint('Error analyzing image: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
  
  /// Apply auto enhancement
  Future<void> autoEnhance() async {
    if (_currentImage == null || _isProcessing) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      _enhancedPreview = await _enhancementService.autoEnhance(
        File(_currentImage!.path),
      );
      _currentEnhancements = const ImageEnhancements(
        contrast: 1.1,
        saturation: 1.1,
        sharpness: 0.2,
      );
    } catch (e) {
      debugPrint('Error auto enhancing: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// Update enhancements
  Future<void> updateEnhancements(ImageEnhancements enhancements) async {
    _currentEnhancements = enhancements;
    notifyListeners();
    
    // Generate preview
    await _generatePreview();
  }
  
  /// Generate enhanced preview
  Future<void> _generatePreview() async {
    if (_currentImage == null || _isProcessing) return;
    
    _isProcessing = true;
    
    try {
      _enhancedPreview = await _enhancementService.getEnhancedPreview(
        File(_currentImage!.path),
        _currentEnhancements,
      );
    } catch (e) {
      debugPrint('Error generating preview: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// Apply a filter
  Future<void> applyFilter(ImageFilter filter) async {
    _currentEnhancements = filter.enhancements;
    notifyListeners();
    await _generatePreview();
  }
  
  /// Save enhanced image
  Future<String?> saveEnhancedImage() async {
    if (_currentImage == null || _enhancedPreview == null) return null;
    
    try {
      // Apply full quality enhancements
      final fullQualityBytes = await _enhancementService.applyEnhancements(
        File(_currentImage!.path),
        _currentEnhancements,
      );
      
      return await _storageService.saveEditedImage(
        _currentImage!.id,
        fullQualityBytes,
      );
    } catch (e) {
      debugPrint('Error saving enhanced image: $e');
      return null;
    }
  }
  
  /// Reset enhancements
  void _resetEnhancements() {
    _currentEnhancements = const ImageEnhancements();
    _enhancedPreview = null;
    _analysisResult = null;
  }
  
  /// Reset current editing session
  void resetEditing() {
    _resetEnhancements();
    notifyListeners();
  }
  
  /// Delete image
  Future<bool> deleteImage(AuraImage image) async {
    final success = await _storageService.deleteImage(image.path);
    if (success) {
      _galleryImages.removeWhere((i) => i.id == image.id);
      if (_currentImage?.id == image.id) {
        _currentImage = null;
        _resetEnhancements();
      }
      notifyListeners();
    }
    return success;
  }
  
  /// Set selected tab
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _cameraService.dispose();
    _analysisService.dispose();
    super.dispose();
  }
}
