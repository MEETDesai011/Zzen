// Habit Tile Widget — Checkable habit item with animation
// SDG 3 Impact: Encouraging healthy pre-sleep habits directly improves
// sleep quality and mental wellbeing (SDG 3.4).
import 'package:flutter/material.dart';
import '../core/theme.dart';

class HabitTile extends StatelessWidget {
  final String habit;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  const HabitTile({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? ZzenTheme.primary.withOpacity(0.1)
            : ZzenTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? ZzenTheme.primary.withOpacity(0.4)
              : ZzenTheme.border,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: GestureDetector(
          onTap: () => onToggle(!isCompleted),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? ZzenTheme.primary : Colors.transparent,
              border: Border.all(
                color: isCompleted ? ZzenTheme.primary : ZzenTheme.textMuted,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          habit,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isCompleted ? ZzenTheme.textPrimary : ZzenTheme.textSecondary,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: ZzenTheme.textMuted,
          ),
        ),
        trailing: isCompleted
            ? const Icon(Icons.star_rounded, color: ZzenTheme.warning, size: 18)
            : null,
        onTap: () => onToggle(!isCompleted),
      ),
    );
  }
}
