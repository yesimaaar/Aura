import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../providers/aura_provider.dart';
import '../models/aura_image.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildGalleryGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Gallery',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Consumer<AuraProvider>(
            builder: (context, provider, _) {
              return Text(
                '${provider.galleryImages.length} photos',
                style: TextStyle(
                  color: AuraColors.textSecondary,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildGalleryGrid(BuildContext context) {
    return Consumer<AuraProvider>(
      builder: (context, provider, child) {
        final images = provider.galleryImages;

        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AuraColors.backgroundCard,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    size: 48,
                    color: AuraColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No photos yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo or import from gallery',
                  style: TextStyle(color: AuraColors.textMuted),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await provider.pickFromGallery();
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Import Photo'),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms);
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return _GalleryTile(
              image: image,
              index: index,
              onTap: () {
                provider.setCurrentImage(image);
                Navigator.pushNamed(context, '/editor');
              },
              onLongPress: () => _showImageOptions(context, provider, image),
            );
          },
        );
      },
    );
  }

  void _showImageOptions(
    BuildContext context,
    AuraProvider provider,
    AuraImage image,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AuraColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                provider.setCurrentImage(image);
                Navigator.pushNamed(context, '/editor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing not implemented yet')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AuraColors.error),
              title: Text('Delete', style: TextStyle(color: AuraColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AuraColors.backgroundCard,
                    title: const Text('Delete Photo?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AuraColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.deleteImage(image);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final AuraImage image;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GalleryTile({
    required this.image,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Hero(
        tag: 'image_${image.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              cacheWidth: 300,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AuraColors.backgroundCard,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AuraColors.textMuted,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }
}
