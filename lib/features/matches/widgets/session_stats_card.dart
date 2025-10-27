import 'package:flutter/material.dart';
import '../../../core/models/session_stats.dart';
import '../../../core/theme/app_theme.dart';

/// SessionStatsCard - Displays session statistics in a collapsible card
class SessionStatsCard extends StatefulWidget {
  final SessionStats stats;

  const SessionStatsCard({
    super.key,
    required this.stats,
  });

  @override
  State<SessionStatsCard> createState() => _SessionStatsCardState();
}

class _SessionStatsCardState extends State<SessionStatsCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: AppTheme.surfaceDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '📊',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sessie Statistieken',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
          ),

          // Stats Grid (collapsible)
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppTheme.neutralGray),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // First row: Total Swipes and Active Members
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: '📊',
                          label: 'Totaal Swipes',
                          value: widget.stats.totalSwipes.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: '👥',
                          label: 'Actieve Leden',
                          value: widget.stats.memberCount.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Second row: Movies Viewed and Like Ratio
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: '🎬',
                          label: 'Films Bekeken',
                          value: widget.stats.totalMovies.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LikeRatioCard(
                          likePercentage: widget.stats.likePercentage,
                          likeCount: widget.stats.likeCount,
                          totalSwipes: widget.stats.totalSwipes,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neutralGray.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Like ratio card with progress bar
class _LikeRatioCard extends StatelessWidget {
  final double likePercentage;
  final int likeCount;
  final int totalSwipes;

  const _LikeRatioCard({
    required this.likePercentage,
    required this.likeCount,
    required this.totalSwipes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neutralGray.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '❤️',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            '${likePercentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Like Ratio',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalSwipes > 0 ? likePercentage / 100 : 0,
              minHeight: 6,
              backgroundColor: AppTheme.neutralGray.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E), // Green color for likes
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$likeCount / $totalSwipes',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
