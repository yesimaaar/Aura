import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../providers/aura_provider.dart';
import '../widgets/enhancement_slider.dart';
import '../widgets/filter_selector.dart';
import '../widgets/analysis_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AuraProvider>(
        builder: (context, provider, child) {
          if (provider.currentImage == null) {
            return const Center(
              child: Text('No image selected'),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, provider),
                Expanded(child: _buildImagePreview(provider)),
                _buildToolbar(provider),
                _buildEditingPanel(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuraProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              provider.resetEditing();
              Navigator.pop(context);
            },
          ),
          const Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: provider.currentEnhancements.hasChanges ||
                    provider.enhancedPreview != null
                ? () => _saveImage(context, provider)
                : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: provider.currentEnhancements.hasChanges ||
                        provider.enhancedPreview != null
                    ? AuraColors.primaryPurple
                    : AuraColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(AuraProvider provider) {
    final image = provider.currentImage!;
    final preview = provider.enhancedPreview;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        Hero(
          tag: 'image_${image.id}',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: preview != null
                ? Image.memory(
                    preview,
                    fit: BoxFit.contain,
                  )
                : Image.file(
                    File(image.path),
                    fit: BoxFit.contain,
                  ),
          ),
        ),

        // Processing indicator
        if (provider.isProcessing)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AuraColors.primaryPurple,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        // Analyzing indicator
        if (provider.isAnalyzing)
          Container(
            color: Colors.black45,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AuraColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1500.ms),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Analyzing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar(AuraProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.auto_fix_high_rounded,
            label: 'Auto',
            isActive: false,
            onTap: () => provider.autoEnhance(),
          ),
          _ToolbarButton(
            icon: Icons.search_rounded,
            label: 'Analyze',
            isActive: provider.analysisResult != null,
            onTap: () => provider.analyzeImage(),
          ),
          _ToolbarButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            isActive: false,
            onTap: () => provider.resetEditing(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingPanel(AuraProvider provider) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AuraColors.backgroundCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AuraColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AuraColors.primaryPurple,
            labelColor: Colors.white,
            unselectedLabelColor: AuraColors.textMuted,
            tabs: const [
              Tab(text: 'Filters'),
              Tab(text: 'Adjust'),
              Tab(text: 'Analysis'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FilterSelector(
                  currentFilter: provider.currentEnhancements.filterName,
                  onFilterSelected: (filter) => provider.applyFilter(filter),
                ),
                _buildAdjustPanel(provider),
                AnalysisPanel(result: provider.analysisResult),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildAdjustPanel(AuraProvider provider) {
    final enhancements = provider.currentEnhancements;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EnhancementSlider(
            label: 'Brightness',
            icon: Icons.brightness_6_rounded,
            value: enhancements.brightness,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => provider.updateEnhancements(
              enhancements.copyWith(brightness: v),
            ),
          ),
          const SizedBox(height: 16),
          EnhancementSlider(
            label: 'Contrast',
            icon: Icons.contrast_rounded,
            value: enhancements.contrast,
            min: 0.5,
            max: 2.0,
            onChanged: (v) => provider.updateEnhancements(
              enhancements.copyWith(contrast: v),
            ),
          ),
          const SizedBox(height: 16),
          EnhancementSlider(
            label: 'Saturation',
            icon: Icons.palette_rounded,
            value: enhancements.saturation,
            min: 0.0,
            max: 2.0,
            onChanged: (v) => provider.updateEnhancements(
              enhancements.copyWith(saturation: v),
            ),
          ),
          const SizedBox(height: 16),
          EnhancementSlider(
            label: 'Warmth',
            icon: Icons.wb_sunny_rounded,
            value: enhancements.warmth,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => provider.updateEnhancements(
              enhancements.copyWith(warmth: v),
            ),
          ),
          const SizedBox(height: 16),
          EnhancementSlider(
            label: 'Sharpness',
            icon: Icons.deblur_rounded,
            value: enhancements.sharpness,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => provider.updateEnhancements(
              enhancements.copyWith(sharpness: v),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage(BuildContext context, AuraProvider provider) async {
    final savedPath = await provider.saveEnhancedImage();
    if (savedPath != null && mounted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image saved successfully'),
            backgroundColor: AuraColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AuraColors.textPrimary : AuraColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AuraColors.backgroundDark : AuraColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AuraColors.backgroundDark : AuraColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
