import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../providers/aura_provider.dart';
import '../services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<AuraProvider>();
    if (!provider.camera.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      provider.camera.controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      provider.camera.initialize();
    }
  }

  Future<void> _takePhoto() async {
    if (_isCapturing) return;
    
    setState(() => _isCapturing = true);
    
    try {
      final provider = context.read<AuraProvider>();
      final image = await provider.takePhoto();
      
      if (image != null && mounted) {
        Navigator.pushNamed(context, '/editor');
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AuraProvider>(
        builder: (context, provider, child) {
          final camera = provider.camera;
          
          if (!camera.isInitialized || camera.controller == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AuraColors.primaryPurple),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              _buildCameraPreview(camera),
              
              // Top Controls
              _buildTopControls(camera),
              
              // Bottom Controls
              _buildBottomControls(provider),
              
              // Capture Animation
              if (_isCapturing)
                Container(
                  color: Colors.white.withValues(alpha: 0.3),
                ).animate().fadeIn(duration: 100.ms).fadeOut(duration: 200.ms),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview(CameraService camera) {
    return GestureDetector(
      onScaleUpdate: (details) {
        final zoom = camera.zoomLevel * details.scale;
        camera.setZoomLevel(zoom);
      },
      onTapDown: (details) {
        final size = MediaQuery.of(context).size;
        final point = Offset(
          details.localPosition.dx / size.width,
          details.localPosition.dy / size.height,
        );
        camera.setFocusPoint(point);
      },
      child: ClipRRect(
        child: CameraPreview(camera.controller!),
      ),
    );
  }

  Widget _buildTopControls(CameraService camera) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flash Button
              _ControlButton(
                icon: _getFlashIcon(camera.flashMode),
                onTap: () => camera.cycleFlashMode(),
              ),
              
              // AI Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AuraColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings
              _ControlButton(
                icon: Icons.settings,
                onTap: () {
                  // Show camera settings
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2);
  }

  Widget _buildBottomControls(AuraProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom Indicator
              if (provider.camera.zoomLevel > 1.0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${provider.camera.zoomLevel.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Button
                  _ControlButton(
                    icon: Icons.photo_library_rounded,
                    size: 48,
                    onTap: () async {
                      await provider.pickFromGallery();
                      if (provider.currentImage != null && mounted) {
                        Navigator.pushNamed(context, '/editor');
                      }
                    },
                  ),
                  
                  // Capture Button
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        color: _isCapturing ? AuraColors.textMuted : null,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ),
                  ).animate(
                    target: _isCapturing ? 1 : 0,
                  ).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(0.9, 0.9),
                    duration: 100.ms,
                  ),
                  
                  // Switch Camera Button
                  _ControlButton(
                    icon: Icons.flip_camera_ios_rounded,
                    size: 48,
                    onTap: () => provider.camera.switchCamera(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
