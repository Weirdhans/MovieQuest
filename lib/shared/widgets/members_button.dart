import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/session_member.dart';
import '../../core/utils/dev_log.dart';

/// Members Button Widget - Shows session members with swipe counts
class MembersButton extends ConsumerWidget {
  const MembersButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(sessionMembersProvider);
    final sessionId = ref.watch(currentSessionIdProvider);

    devLog('MembersButton: sessionId=$sessionId, membersAsync state: ${membersAsync.toString()}');

    return membersAsync.when(
      data: (membersData) {
        devLog('MembersButton: received ${membersData.length} members');
        devLog('MembersButton: raw data: $membersData');

        // Convert to SessionMember objects and sort by swipe count
        try {
          final members = membersData
              .map((data) {
                devLog('Converting member data: $data');
                return SessionMember.fromJson(data);
              })
              .toList()
            ..sort((a, b) => b.swipeCount.compareTo(a.swipeCount));

          final memberCount = members.length;
          devLog('MembersButton: successfully converted $memberCount members');

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
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    memberCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
        } catch (e, stackTrace) {
          devLogError('Failed to convert members', e, stackTrace: stackTrace);
          return const IconButton(
            icon: Icon(Icons.group),
            onPressed: null,
          );
        }
      },
      loading: () => const IconButton(
        icon: Icon(Icons.group),
        onPressed: null,
      ),
      error: (error, stack) {
        devLogError('Failed to load members', error, stackTrace: stack);
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

          // Members list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 24,
                endIndent: 24,
                color: AppTheme.neutralGray,
              ),
              itemBuilder: (context, index) {
                final member = members[index];
                return _MemberListItem(member: member, rank: index + 1);
              },
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceDark,
                  foregroundColor: AppTheme.primaryGold,
                  side: const BorderSide(color: AppTheme.primaryGold, width: 2),
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

/// Member List Item - Individual member tile
class _MemberListItem extends StatelessWidget {
  final SessionMember member;
  final int rank;

  const _MemberListItem({
    required this.member,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: _getRankColor(rank),
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
                color: AppTheme.primaryGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGold, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '👑',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Host',
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Swipes: ${member.swipeCount}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryOrange, width: 1.5),
        ),
        child: Text(
          '${member.swipeCount}',
          style: const TextStyle(
            color: AppTheme.primaryOrange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
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
}
