import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Service for managing camera operations
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  final bool _isRecording = false;
  FlashMode _flashMode = FlashMode.auto;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _exposureOffset = 0.0;
  double _minExposure = 0.0;
  double _maxExposure = 0.0;
  
  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  FlashMode get flashMode => _flashMode;
  double get zoomLevel => _zoomLevel;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  double get exposureOffset => _exposureOffset;
  double get minExposure => _minExposure;
  double get maxExposure => _maxExposure;
  bool get hasFrontCamera => _cameras.any((c) => c.lensDirection == CameraLensDirection.front);
  bool get hasBackCamera => _cameras.any((c) => c.lensDirection == CameraLensDirection.back);
  bool get isUsingFrontCamera => _cameras.isNotEmpty && 
      _cameras[_currentCameraIndex].lensDirection == CameraLensDirection.front;
  
  /// Initialize the camera service
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('NO_CAMERAS', 'No cameras available on device');
      }
      
      // Default to back camera if available
      _currentCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_currentCameraIndex < 0) _currentCameraIndex = 0;
      
      await _initController(_cameras[_currentCameraIndex]);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      rethrow;
    }
  }
  
  /// Initialize camera controller
  Future<void> _initController(CameraDescription camera) async {
    _controller?.dispose();
    
    _controller = CameraController(
      camera,
      ResolutionPreset.max, // Cambiado de high a max para mejor calidad
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    try {
      await _controller!.initialize();
      
      // Get zoom limits
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _zoomLevel = _minZoom;
      
      // Get exposure limits
      _minExposure = await _controller!.getMinExposureOffset();
      _maxExposure = await _controller!.getMaxExposureOffset();
      _exposureOffset = 0.0;
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Controller initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// Take a photo
  Future<XFile?> takePhoto() async {
    if (!_isInitialized || _controller == null) return null;
    
    try {
      final XFile file = await _controller!.takePicture();
      return file;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }
  
  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    _isInitialized = false;
    notifyListeners();
    
    await _initController(_cameras[_currentCameraIndex]);
  }
  
  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (!_isInitialized || _controller == null) return;
    
    try {
      await _controller!.setFlashMode(mode);
      _flashMode = mode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }
  
  /// Cycle through flash modes
  Future<void> cycleFlashMode() async {
    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off, FlashMode.torch];
    final currentIndex = modes.indexOf(_flashMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setFlashMode(modes[nextIndex]);
  }
  
  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (!_isInitialized || _controller == null) return;
    
    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    try {
      await _controller!.setZoomLevel(clampedZoom);
      _zoomLevel = clampedZoom;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }
  
  /// Set exposure offset
  Future<void> setExposureOffset(double offset) async {
    if (!_isInitialized || _controller == null) return;
    
    final clampedOffset = offset.clamp(_minExposure, _maxExposure);
    try {
      await _controller!.setExposureOffset(clampedOffset);
      _exposureOffset = clampedOffset;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting exposure: $e');
    }
  }
  
  /// Set focus point
  Future<void> setFocusPoint(Offset point) async {
    if (!_isInitialized || _controller == null) return;
    
    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setExposurePoint(point);
    } catch (e) {
      debugPrint('Error setting focus point: $e');
    }
  }
  
  /// Lock/unlock focus and exposure
  Future<void> lockCaptureOrientation(bool lock) async {
    if (!_isInitialized || _controller == null) return;
    
    try {
      if (lock) {
        await _controller!.lockCaptureOrientation();
      } else {
        await _controller!.unlockCaptureOrientation();
      }
    } catch (e) {
      debugPrint('Error locking orientation: $e');
    }
  }
  
  /// Get flash mode icon
  String getFlashModeIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return 'flash_auto';
      case FlashMode.always:
        return 'flash_on';
      case FlashMode.off:
        return 'flash_off';
      case FlashMode.torch:
        return 'flashlight_on';
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
