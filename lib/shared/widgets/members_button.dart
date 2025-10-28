import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/session_member.dart';
import '../../core/utils/dev_log.dart';

/// Members Button Widget - Shows session members with swipe counts
///
/// Displays a group icon with a badge showing the member count.
/// When clicked, opens a bottom sheet showing all session members
/// with detailed stats including:
/// - Swipe counts and like counts
/// - Progress bars relative to the most active member
/// - Medal rankings (🥇🥈🥉) for top 3
/// - Host indicator
///
/// The button subscribes to [sessionMembersProvider] for real-time updates.
class MembersButton extends ConsumerWidget {
  const MembersButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(sessionMembersProvider);
    final sessionId = ref.watch(currentSessionIdProvider);

    devLog('🔘 [MembersButton] Building widget - sessionId=$sessionId');
    devLog('🔘 [MembersButton] membersAsync state: ${membersAsync.runtimeType}');

    return membersAsync.when(
      data: (membersData) {
        devLog('📥 [MembersButton] Received data with ${membersData.length} members');
        if (membersData.isEmpty) {
          devLog('⚠️ [MembersButton] WARNING: membersData is EMPTY!');
        } else {
          devLog('📋 [MembersButton] Raw data received:');
          for (var i = 0; i < membersData.length; i++) {
            devLog('  Member ${i + 1}: ${membersData[i]}');
          }
        }

        // Convert to SessionMember objects and sort by swipe count
        try {
          final members = membersData
              .map((data) {
                devLog('🔄 [MembersButton] Converting member: ${data['user_name'] ?? 'Unknown'}');
                return SessionMember.fromJson(data);
              })
              .toList()
            ..sort((a, b) => b.swipeCount.compareTo(a.swipeCount));

          final memberCount = members.length;
          devLogSuccess('✅ [MembersButton] Successfully converted $memberCount members');

          if (memberCount == 0) {
            devLog('⚠️ [MembersButton] No members to display - showing empty icon');
          } else {
            devLog('👥 [MembersButton] Displaying $memberCount members in UI');
          }

          return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () => _showMembersBottomSheet(context, members),
              tooltip: 'Bekijk Leden',
            ),
            if (memberCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      memberCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
        } catch (e, stackTrace) {
          devLogError('❌ [MembersButton] Failed to convert members', e, stackTrace: stackTrace);
          devLog('❌ [MembersButton] Raw data that failed: $membersData');
          return const IconButton(
            icon: Icon(Icons.group),
            onPressed: null,
          );
        }
      },
      loading: () {
        devLog('⏳ [MembersButton] Loading state...');
        return const IconButton(
          icon: Icon(Icons.group),
          onPressed: null,
        );
      },
      error: (error, stack) {
        devLogError('❌ [MembersButton] Error state', error, stackTrace: stack);
        return const IconButton(
          icon: Icon(Icons.group),
          onPressed: null,
        );
      },
    );
  }

  void _showMembersBottomSheet(BuildContext context, List<SessionMember> members) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MembersBottomSheet(members: members),
    );
  }
}

/// Members Bottom Sheet - Shows list of members with swipe counts
class _MembersBottomSheet extends StatelessWidget {
  final List<SessionMember> members;

  const _MembersBottomSheet({required this.members});

  @override
  Widget build(BuildContext context) {
    // Get max swipe count for progress bar calculation
    final maxSwipes = members.isEmpty ? 1 : members.map((m) => m.swipeCount).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutralGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.group, color: AppTheme.primaryGold, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Sessie Leden (${members.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.neutralGray),

          // Members cards list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return _MemberCard(
                  member: member,
                  rank: index + 1,
                  maxSwipes: maxSwipes,
                );
              },
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceDark,
                  foregroundColor: AppTheme.primaryGold,
                  side: const BorderSide(color: AppTheme.primaryGold, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Sluiten'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Member Card - Beautiful card layout for member display
///
/// Displays a single member's stats in a visually appealing card with:
/// - Gradient background (gold/silver/bronze for top 3)
/// - Medal emoji (🥇🥈🥉) based on rank
/// - Progress bar showing activity relative to [maxSwipes]
/// - Swipe count and likes count with icons
/// - Host badge with crown icon if applicable
///
/// The card design includes shadows, rounded corners, and color-coded
/// borders that match the member's rank.
class _MemberCard extends StatelessWidget {
  final SessionMember member;
  final int rank;
  final int maxSwipes;

  const _MemberCard({
    required this.member,
    required this.rank,
    required this.maxSwipes,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxSwipes > 0 ? member.swipeCount / maxSwipes : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: _getCardGradient(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Medal/Rank + Name + Host badge
            Row(
              children: [
                // Medal emoji for top 3
                Text(
                  _getMedalEmoji(),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (member.isHost) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGold, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👑', style: TextStyle(fontSize: 10)),
                        SizedBox(width: 4),
                        Text(
                          'Host',
                          style: TextStyle(
                            color: AppTheme.primaryGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 2),

            // Progress percentage
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Stats row: Swipes + Likes
            Row(
              children: [
                // Swipes
                const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primaryOrange),
                const SizedBox(width: 4),
                Text(
                  '${member.swipeCount} swipes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                // Likes
                const Text('💚', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${member.likesCount} likes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMedalEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🎬';
    }
  }

  LinearGradient _getCardGradient() {
    if (rank == 1) {
      // Gold gradient for #1
      return LinearGradient(
        colors: [
          AppTheme.primaryGold.withValues(alpha: 0.15),
          AppTheme.surfaceDark,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (rank == 2) {
      // Silver gradient for #2
      return LinearGradient(
        colors: [
          Colors.grey.shade400.withValues(alpha: 0.1),
          AppTheme.surfaceDark,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (rank == 3) {
      // Bronze gradient for #3
      return LinearGradient(
        colors: [
          Colors.brown.shade400.withValues(alpha: 0.1),
          AppTheme.surfaceDark,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Default gradient
    return const LinearGradient(
      colors: [AppTheme.surfaceDark, AppTheme.surfaceDark],
    );
  }

  Color _getBorderColor() {
    switch (rank) {
      case 1:
        return AppTheme.primaryGold;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return AppTheme.neutralGray;
    }
  }

  Color _getProgressColor() {
    switch (rank) {
      case 1:
        return AppTheme.primaryGold;
      case 2:
        return Colors.grey.shade300;
      case 3:
        return Colors.brown.shade300;
      default:
        return AppTheme.primaryOrange;
    }
  }
}
