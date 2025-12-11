import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'habit_detail_bottom_sheet.dart';
import 'habit_note_icon_button.dart';
import 'multi_completion_button.dart';

class HabitProgressCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onPressed;

  const HabitProgressCard({
    super.key,
    required this.habit,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity( 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed ?? () => HabitDetailBottomSheet.show(context, habit),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: habit.color.withOpacity( 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      habit.icon,
                      color: habit.color,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? theme.colorScheme.onSurface.withOpacity( 0.45)
                                  : theme.colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Habit Type Indicator (Linear Design)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: habit.habitType == HabitType.build 
                                  ? Colors.green 
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            habit.habitType == HabitType.build ? 'Build' : 'Break',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: habit.habitType == HabitType.build 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Streak Badge
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              final primary = theme.colorScheme.primary;
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  primary.withOpacity(0.55),
                                  primary,
                                ],
                              ).createShader(bounds);
                            },
                            child: const Icon(
                              Icons.local_fire_department,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} day streak',
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity( 0.6),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                    Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HabitNoteIconButton(habit: habit, size: 36),
                    const SizedBox(width: 8),
                    MultiCompletionButton(habit: habit, size: 36),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
