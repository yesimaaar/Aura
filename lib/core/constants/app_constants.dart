class AppConstants {
  // App Info
  static const String appName = 'Aura';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'AI-Powered Visual Enhancement';
  
  // Routes
  static const String routeHome = '/';
  static const String routeCamera = '/camera';
  static const String routeGallery = '/gallery';
  static const String routeEditor = '/editor';
  static const String routeSettings = '/settings';
  static const String routeOnboarding = '/onboarding';
  
  // Camera Settings
  static const double defaultZoom = 1.0;
  static const double maxZoom = 8.0;
  static const double minZoom = 1.0;
  
  // Image Processing
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int thumbnailSize = 256;
  static const double defaultBrightness = 0.0;
  static const double defaultContrast = 1.0;
  static const double defaultSaturation = 1.0;
  static const double defaultSharpness = 0.0;
  
  // AI Analysis
  static const int maxObjectsDetected = 10;
  static const double confidenceThreshold = 0.5;
  
  // Animation Durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Storage Keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyDarkMode = 'dark_mode';
  static const String keyAutoEnhance = 'auto_enhance';
  static const String keySaveOriginal = 'save_original';
  static const String keyImageQuality = 'image_quality';
}

class AuraStrings {
  // Home Screen
  static const String homeTitle = 'Aura';
  static const String homeWelcome = 'Welcome to Aura';
  static const String homeSubtitle = 'Transform your photos with AI';
  
  // Camera Screen
  static const String cameraTitle = 'Capture';
  static const String cameraTakePhoto = 'Take Photo';
  static const String cameraFlash = 'Flash';
  static const String cameraFlip = 'Flip Camera';
  static const String cameraGallery = 'Gallery';
  
  // Editor Screen
  static const String editorTitle = 'Edit';
  static const String editorAnalyze = 'Analyze';
  static const String editorEnhance = 'Enhance';
  static const String editorFilters = 'Filters';
  static const String editorAdjust = 'Adjust';
  static const String editorSave = 'Save';
  static const String editorShare = 'Share';
  
  // Analysis
  static const String analysisTitle = 'AI Analysis';
  static const String analysisDetecting = 'Detecting objects...';
  static const String analysisComplete = 'Analysis complete';
  static const String analysisNoObjects = 'No objects detected';
  
  // Enhancement
  static const String enhanceTitle = 'Enhancement';
  static const String enhanceAuto = 'Auto Enhance';
  static const String enhanceBrightness = 'Brightness';
  static const String enhanceContrast = 'Contrast';
  static const String enhanceSaturation = 'Saturation';
  static const String enhanceSharpness = 'Sharpness';
  
  // Settings
  static const String settingsTitle = 'Settings';
  static const String settingsGeneral = 'General';
  static const String settingsCamera = 'Camera';
  static const String settingsStorage = 'Storage';
  static const String settingsAbout = 'About';
  
  // Errors
  static const String errorGeneric = 'Something went wrong';
  static const String errorCameraPermission = 'Camera permission required';
  static const String errorStoragePermission = 'Storage permission required';
  static const String errorNoCamera = 'No camera available';
  static const String errorImageLoad = 'Failed to load image';
  static const String errorImageSave = 'Failed to save image';
  
  // Success
  static const String successImageSaved = 'Image saved successfully';
  static const String successEnhanced = 'Enhancement applied';
}
