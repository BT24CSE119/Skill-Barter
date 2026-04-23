import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String skill;
  final String status;

  final String? subtitle;
  final String? time;

  final VoidCallback? onJoin;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  final VoidCallback? onLeave;
  final VoidCallback? onVideoCall;
  final VoidCallback? onOpenRoom;

  final String? timerText;

  const SessionCard({
    super.key,
    required this.title,
    required this.skill,
    required this.status,
    this.subtitle,
    this.time,
    this.onJoin,
    this.onComplete,
    this.onDelete,
    this.onLeave,
    this.onVideoCall,
    this.onOpenRoom,
    this.timerText,
  });

  bool get isCompleted => status == "completed";
  bool get isOngoing => status == "ongoing";
  bool get isUpcoming => status == "upcoming";

  Color get statusColor {
    if (isCompleted) return Colors.green;
    if (isOngoing) return Colors.redAccent;
    return Colors.blueAccent;
  }

  IconData get statusIcon {
    if (isCompleted) return Icons.check_circle;
    if (isOngoing) return Icons.play_circle_fill;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔥 HEADER
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 30),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),

                  _statusBadge(),
                ],
              ),

              const SizedBox(height: 12),

              /// 🔥 SKILL CHIP
              Row(
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    skill,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],

              if (time != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      time!,
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ],

              /// 🔥 TIMER
              if (isOngoing && timerText != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      timerText!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              /// 🔥 ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: _buildLeftActions()),
                  Row(children: _buildRightActions()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= STATUS BADGE =================
  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  /// ================= LEFT ACTIONS =================
  List<Widget> _buildLeftActions() {
    return [
      if (isUpcoming && onJoin != null)
        _icon(Icons.play_arrow, Colors.blue, onJoin),

      if (isOngoing && onOpenRoom != null)
        _icon(Icons.meeting_room, Colors.indigo, onOpenRoom),

      if (isOngoing && onComplete != null)
        _icon(Icons.check_circle, Colors.green, onComplete),

      if (isOngoing && onLeave != null)
        _icon(Icons.exit_to_app, Colors.orange, onLeave),
    ];
  }

  /// ================= RIGHT ACTIONS =================
  List<Widget> _buildRightActions() {
    return [
      if (isOngoing && onVideoCall != null)
        _icon(Icons.video_call, Colors.purple, onVideoCall),

      if (onDelete != null)
        _icon(Icons.delete_outline, Colors.red, onDelete),
    ];
  }

  /// ================= ICON BUTTON =================
  Widget _icon(IconData icon, Color color, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onTap,
      splashRadius: 22,
    );
  }
}