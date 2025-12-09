import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing app permissions
class PermissionService {
  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    if (await Permission.photos.isGranted) return true;
    
    // For Android 13+ (API 33+), we need photo library permission
    if (await Permission.photos.request().isGranted) return true;
    
    // Fallback for older Android versions
    if (await Permission.storage.request().isGranted) return true;
    
    return false;
  }
  
  /// Request all required permissions
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }
  
  /// Check if camera permission is granted
  Future<bool> get hasCameraPermission async {
    return await Permission.camera.isGranted;
  }
  
  /// Check if storage permission is granted
  Future<bool> get hasStoragePermission async {
    return await Permission.photos.isGranted || 
           await Permission.storage.isGranted;
  }
  
  /// Check if all required permissions are granted
  Future<bool> get hasAllPermissions async {
    final camera = await hasCameraPermission;
    final storage = await hasStoragePermission;
    return camera && storage;
  }
  
  /// Open app settings if permission permanently denied
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
  
  /// Show permission denied dialog
  static Future<bool?> showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
