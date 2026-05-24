// Risk Badge Widget — Severity level badge (low/medium/high)
import 'package:flutter/material.dart';
import '../core/theme.dart';

enum RiskLevel { low, medium, high }

class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final String? customLabel;

  const RiskBadge({
    super.key,
    required this.level,
    this.customLabel,
  });

  factory RiskBadge.fromScore(int score) {
    final level = score >= 70
        ? RiskLevel.low
        : score >= 40
            ? RiskLevel.medium
            : RiskLevel.high;
    return RiskBadge(level: level);
  }

  @override
  Widget build(BuildContext context) {
    final label = customLabel ?? _label;
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (level) {
      case RiskLevel.low:
        return ZzenTheme.scoreGreen;
      case RiskLevel.medium:
        return ZzenTheme.scoreYellow;
      case RiskLevel.high:
        return ZzenTheme.scoreRed;
    }
  }

  String get _label {
    switch (level) {
      case RiskLevel.low:
        return 'GOOD';
      case RiskLevel.medium:
        return 'FAIR';
      case RiskLevel.high:
        return 'POOR';
    }
  }
}
