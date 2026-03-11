import 'package:flutter/material.dart';
import '../models/scan_model.dart';
import '../utils/theme.dart';

class VitaShadeGuideWidget extends StatelessWidget {
  final String predictedShade;
  final double confidence;

  const VitaShadeGuideWidget({
    super.key,
    required this.predictedShade,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.premiumGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.format_paint_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VITA SHADE GUIDE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary, fontSize: 12)),
                  Text('Detected: $predictedShade · ${(confidence * 100).toStringAsFixed(0)}% confident', style: AppTheme.subHeading.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Predicted shade swatch (large)
          _buildPredictedSwatch(),
          const SizedBox(height: 20),

          // Confidence meter
          _buildConfidenceMeter(),
          const SizedBox(height: 20),

          // Full shade guide grid
          const Text('CLASSICAL VITA SCALE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.secondaryText)),
          const SizedBox(height: 12),
          _buildShadeGrid(),
          const SizedBox(height: 14),

          // Group legend
          _buildGroupLegend(),
        ],
      ),
    );
  }

  Widget _buildPredictedSwatch() {
    final shade = vitaShadeGuide.firstWhere(
      (s) => s.shade == predictedShade,
      orElse: () => vitaShadeGuide.first,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.premiumGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // Color swatch
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Color.fromRGBO(shade.r, shade.g, shade.b, 1.0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shade.shade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  'Group ${shade.group}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  shade.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceMeter() {
    Color meterColor;
    String label;
    if (confidence >= 0.9) {
      meterColor = const Color(0xFF2DD4BF);
      label = 'High Confidence';
    } else if (confidence >= 0.75) {
      meterColor = const Color(0xFF3B82F6);
      label = 'Good Confidence';
    } else if (confidence >= 0.5) {
      meterColor = const Color(0xFFF59E0B);
      label = 'Low — Consider Retake';
    } else {
      meterColor = const Color(0xFFEF4444);
      label = 'Very Low — Retake Required';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('CONFIDENCE SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.secondaryText)),
            Text(
              '${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: meterColor, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: confidence,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: meterColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: meterColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildShadeGrid() {
    // Group shades A, B, C, D
    final groups = ['A', 'B', 'C', 'D'];
    return Column(
      children: groups.map((group) {
        final groupShades = vitaShadeGuide.where((s) => s.group == group).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(group, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.secondaryText, fontSize: 12)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: groupShades.map((shade) {
                    final isPredicted = shade.shade == predictedShade;
                    return Expanded(
                      child: Tooltip(
                        message: '${shade.shade}\n${shade.description}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: isPredicted ? 42 : 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(shade.r, shade.g, shade.b, 1.0),
                            borderRadius: BorderRadius.circular(isPredicted ? 10 : 6),
                            border: isPredicted
                                ? Border.all(color: AppTheme.primary, width: 2.5)
                                : null,
                            boxShadow: isPredicted
                                ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : null,
                          ),
                          child: isPredicted
                              ? Center(
                                  child: Text(
                                    shade.shade,
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primary),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupLegend() {
    final descriptions = {
      'A': 'Reddish-brown tones',
      'B': 'Reddish-yellow tones',
      'C': 'Grey tones',
      'D': 'Reddish-grey tones',
    };

    return Row(
      children: descriptions.entries.map((e) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(e.value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppTheme.secondaryText)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
