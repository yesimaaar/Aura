import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../models/aura_image.dart';

/// Main state provider for the Aura app
class AuraProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final StorageService _storageService = StorageService();
  
  // Gemini service
  GeminiService get gemini => _geminiService;
  bool get isGeminiReady => _geminiService.isInitialized;
  
  // Image state
  List<AuraImage> _images = [];
  List<AuraImage> get images => _images;
  
  AuraImage? _selectedImage;
  AuraImage? get selectedImage => _selectedImage;
  
  // UI state
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔧 AuraProvider: Starting initialization...');
    
    // Initialize Gemini
    try {
      print('🔧 AuraProvider: Initializing Gemini...');
      await _geminiService.initialize();
      print('✅ AuraProvider: Gemini done');
    } catch (e) {
      print('⚠️ AuraProvider: Gemini initialization failed: $e');
    }
    
    // Load images
    try {
      await loadImages();
    } catch (e) {
      print('⚠️ AuraProvider: Failed to load images: $e');
    }
    
    _isInitialized = true;
    notifyListeners();
    print('✅ AuraProvider: Initialization complete');
  }
  
  /// Load images from storage
  Future<void> loadImages() async {
    _images = await _storageService.getAllImages();
    notifyListeners();
  }
  
  /// Add a new image
  void addImage(AuraImage image) {
    _images.insert(0, image);
    notifyListeners();
  }
  
  /// Delete an image
  Future<void> deleteImage(AuraImage image) async {
    final success = await _storageService.deleteImage(image.path);
    if (success) {
      _images.removeWhere((img) => img.id == image.id);
      if (_selectedImage?.id == image.id) {
        _selectedImage = null;
      }
      notifyListeners();
    }
  }
  
  /// Select an image for analysis
  void selectImage(AuraImage? image) {
    _selectedImage = image;
    notifyListeners();
  }
  
  /// Clear selected image
  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }
  
  /// Pick image from gallery
  Future<void> pickFromGallery() async {
    final image = await _storageService.pickFromGallery();
    if (image != null) {
      addImage(image);
      selectImage(image);
    }
  }
  
  /// Chat with Aura (text or multimodal)
  Future<String> chatWithAura(String message) async {
    if (_selectedImage != null) {
      // Multimodal chat
      final File imageFile = File(_selectedImage!.path);
      if (await imageFile.exists()) {
        return await _geminiService.analyzeImage(imageFile, prompt: message);
      } else {
        return "Error: La imagen seleccionada no se encuentra.";
      }
    } else {
      // Text only chat
      return await _geminiService.sendMessage(message);
    }
  }
  
  /// Set selected tab
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }
}
