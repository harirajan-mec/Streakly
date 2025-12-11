import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';

class HabitNoteIconButton extends StatelessWidget {
  final Habit habit;
  final double size;
  final bool isSquare;

  const HabitNoteIconButton({
    super.key,
    required this.habit,
    this.size = 44,
    this.isSquare = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = habit.color;
    final iconColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () => _showAddNoteDialog(context),
      child: Tooltip(
        message: 'Add note',
          child: Container(
          width: size,
          height: size,
          decoration: isSquare
              ? BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
          child: Center(
            child: Icon(
              Icons.sticky_note_2,
              color: iconColor,
              size: size * (isSquare ? 0.55 : 0.58),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) {
                return;
              }
              await _saveNote(context, title, content);
              if (context.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote(
    BuildContext context,
    String title,
    String content,
  ) async {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      habitId: habit.id,
      habitName: habit.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: const [],
    );
    await noteProvider.addNote(note);
  }
}
