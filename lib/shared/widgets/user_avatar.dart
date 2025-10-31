import 'package:flutter/material.dart';
import 'dart:math';

/// UserAvatar - Displays a circular avatar with initials and color based on name
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 20,
  });

  /// Get initials from name (first 2 characters or first letter of first/last name)
  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      // First name + Last name: "Hans Weebers" → "HW"
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else {
      // Single name: "Hans" → "HA" or "H" if only 1 char
      return trimmed.length >= 2
          ? trimmed.substring(0, 2).toUpperCase()
          : trimmed[0].toUpperCase();
    }
  }

  /// Generate a consistent color based on name hash
  Color _getColorFromName(String name) {
    // Predefined color palette with good contrast on dark backgrounds
    final colors = [
      const Color(0xFF4A90E2), // Blue
      const Color(0xFF50C878), // Emerald
      const Color(0xFFE85D75), // Pink
      const Color(0xFFF39C12), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF1ABC9C), // Turquoise
      const Color(0xFFE74C3C), // Red
      const Color(0xFF3498DB), // Light Blue
      const Color(0xFF2ECC71), // Green
      const Color(0xFFF1C40F), // Yellow
    ];

    // Hash the name to get consistent color
    final hash = name.toLowerCase().codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final color = _getColorFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.45, // Font size is 45% of avatar size
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// VoterAvatars - Display a row of voter avatars with optional overflow
class VoterAvatars extends StatelessWidget {
  final List<String> voterNames;
  final double avatarSize;
  final int maxVisible;

  const VoterAvatars({
    super.key,
    required this.voterNames,
    this.avatarSize = 20,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (voterNames.isEmpty) return const SizedBox.shrink();

    final visibleNames = voterNames.take(maxVisible).toList();
    final overflowCount = max(0, voterNames.length - maxVisible);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show visible avatars
          ...visibleNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            return Padding(
              padding: EdgeInsets.only(right: index < visibleNames.length - 1 || overflowCount > 0 ? 4 : 0),
              child: UserAvatar(name: name, size: avatarSize),
            );
          }),
          // Show overflow indicator if needed
          if (overflowCount > 0) ...[
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '+$overflowCount',
                  style: TextStyle(
                    fontSize: avatarSize * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
