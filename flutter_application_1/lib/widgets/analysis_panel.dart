import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/aura_theme.dart';
import '../models/analysis_result.dart';

class AnalysisPanel extends StatelessWidget {
  final AnalysisResult? result;

  const AnalysisPanel({
    super.key,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 48,
              color: AuraColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Tap "Analyze" to scan this image',
              style: TextStyle(
                color: AuraColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quality Score
          _buildQualitySection(result!.qualityScore),
          const SizedBox(height: 20),

          // Scene Labels
          if (result!.sceneLabels.isNotEmpty) ...[
            _buildSectionTitle('Scene Detection'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result!.sceneLabels.map((label) {
                return _buildChip(
                  label.label,
                  '${(label.confidence * 100).round()}%',
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Detected Objects
          if (result!.objects.isNotEmpty) ...[
            _buildSectionTitle('Detected Objects'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result!.objects.map((obj) {
                return _buildChip(
                  obj.label,
                  '${(obj.confidence * 100).round()}%',
                  color: AuraColors.primaryBlue,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Color Analysis
          _buildSectionTitle('Dominant Colors'),
          const SizedBox(height: 8),
          Row(
            children: result!.colorAnalysis.dominantColors.take(5).map((color) {
              return Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(color.red, color.green, color.blue, 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Suggestions
          if (result!.suggestedEnhancements.isNotEmpty) ...[
            _buildSectionTitle('AI Suggestions'),
            const SizedBox(height: 8),
            ...result!.suggestedEnhancements.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: AuraColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: AuraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AuraColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildQualitySection(QualityScore score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AuraColors.primaryPurple.withValues(alpha: 0.2),
            AuraColors.primaryBlue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Score Circle
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.surfaceLight,
            ),
            child: Center(
              child: Text(
                '${(score.overall * 100).round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quality: ${score.overallLabel}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniScore('Sharp', score.sharpness),
                    const SizedBox(width: 12),
                    _buildMiniScore('Exposure', score.exposure),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value > 0.7
                ? AuraColors.success
                : value > 0.4
                    ? AuraColors.warning
                    : AuraColors.error,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AuraColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AuraColors.primaryPurple).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? AuraColors.primaryPurple).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? AuraColors.primaryPurple,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: (color ?? AuraColors.primaryPurple).withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
