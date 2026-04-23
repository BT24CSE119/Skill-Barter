import 'package:flutter/material.dart';
import '../../models/skill_model.dart';

class SkillCard extends StatefulWidget {
  final SkillModel skill;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SkillCard({
    super.key,
    required this.skill,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> {
  bool _showActions = false;

  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: _toggleActions, // ✅ show/hide actions on long press
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ prevents forced overflow
            children: [
              // Icon + Category badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.star, color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.skill.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Skill name
              Text(
                widget.skill.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                widget.skill.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Owner info
              Text(
                "Owner: ${widget.skill.ownerId.isNotEmpty ? widget.skill.ownerId : "Unknown"}",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              // ✅ Edit/Delete actions appear only when long pressed
              if (_showActions) ...[
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: widget.onEdit, // ✅ callback wired
                      tooltip: "Edit Skill",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: widget.onDelete, // ✅ callback wired
                      tooltip: "Delete Skill",
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}