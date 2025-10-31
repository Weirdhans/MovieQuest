import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/responsive_constants.dart';
import '../../core/providers/providers.dart';
import '../../core/models/match.dart';
import '../../core/models/partial_match.dart';
import '../../core/models/movie.dart';
import '../../core/models/session_stats.dart';
import '../../core/utils/dev_log.dart';
import '../../core/errors/app_error.dart';
import '../../shared/widgets/responsive_wrapper.dart';
import 'widgets/session_stats_card.dart';

/// Matches Screen - Display all matched movies with tabs for full and partial matches
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Refresh matches and stats when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(sessionMatchesProvider);
      ref.invalidate(sessionPartialMatchesProvider);
      ref.invalidate(sessionStatsProvider);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: AppTheme.neutralGray,
          tabs: const [
            Tab(text: 'Volledige Matches'),
            Tab(text: 'Gedeeltelijke Matches'),
          ],
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: ResponsiveConstants.matchesScreenMaxWidth,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.darkBackground, Color(0xFF1A0E0E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Session Stats Card
              _buildSessionStatsCard(),

              // TabBarView with matches
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMatchesTab(),
                    _buildPartialMatchesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatsCard() {
    final statsAsync = ref.watch(sessionStatsProvider);

    return statsAsync.when(
      data: (statsJson) {
        if (statsJson == null) {
          return const SizedBox.shrink();
        }

        final stats = SessionStats.fromJson(statsJson);
        return SessionStatsCard(stats: stats);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildMatchesTab() {
    final matchesAsync = ref.watch(sessionMatchesProvider);

    return matchesAsync.when(
      data: (matchesJson) {
        if (matchesJson.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.movie_filter,
                  size: 80,
                  color: AppTheme.primaryGold,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nog geen matches',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Als genoeg mensen een film liken, verschijnt deze hier',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        final matches = matchesJson.map(Match.fromJson).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid: 2 columns on mobile, 3 columns on desktop
            final crossAxisCount = constraints.maxWidth >= ResponsiveConstants.mobileBreakpoint ? 3 : 2;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return _MatchCard(match: match);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Fout bij laden matches',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartialMatchesTab() {
    final partialMatchesAsync = ref.watch(sessionPartialMatchesProvider);

    return partialMatchesAsync.when(
      data: (partialMatchesJson) {
        if (partialMatchesJson.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.thumb_up_outlined,
                  size: 80,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nog geen gedeeltelijke matches',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Films die door sommigen zijn geliked maar nog geen volledige match zijn verschijnen hier',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter out invalid entries and convert to PartialMatch objects
        final partialMatches = <PartialMatch>[];
        for (final json in partialMatchesJson) {
          try {
            partialMatches.add(PartialMatch.fromJson(json));
          } catch (e) {
            // Log the error but continue processing other matches
            devLogError('Failed to parse partial match', AppError.unknown(message: e.toString()));
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid: 2 columns on mobile, 3 columns on desktop
            final crossAxisCount = constraints.maxWidth >= ResponsiveConstants.mobileBreakpoint ? 3 : 2;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: partialMatches.length,
              itemBuilder: (context, index) {
                final partialMatch = partialMatches[index];
                return _PartialMatchCard(partialMatch: partialMatch);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Fout bij laden partial matches',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Match Card Widget
class _MatchCard extends ConsumerWidget {
  final Match match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = match.movie;
    final tmdbService = ref.watch(tmdbServiceProvider);

    return GestureDetector(
      onTap: () => _showMovieDetails(context, movie, ref),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster
              CachedNetworkImage(
                imageUrl: tmdbService.getPosterUrl(movie.posterPath),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(Icons.error, size: 48, color: Colors.red),
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              // Match badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.phoenixGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${match.likesCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title and info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.displayTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (movie.releaseYear != null)
                        Text(
                          movie.releaseYear.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMovieDetails(BuildContext context, Movie movie, WidgetRef ref) {
    final tmdbService = ref.read(tmdbServiceProvider);

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceDark,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poster
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: tmdbService.getPosterUrl(movie.posterPath, size: 'w780'),
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: AppTheme.surfaceDark,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        movie.displayTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Year and Rating
                      Row(
                        children: [
                          if (movie.releaseYear != null) ...[
                            const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryGold),
                            const SizedBox(width: 4),
                            Text(movie.releaseYear.toString()),
                            const SizedBox(width: 16),
                          ],
                          if (movie.voteAverage != null) ...[
                            const Icon(Icons.star, size: 16, color: AppTheme.primaryGold),
                            const SizedBox(width: 4),
                            Text(movie.voteAverage!.toStringAsFixed(1)),
                          ],
                        ],
                      ),

                      if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Overzicht',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.overview!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Partial Match Card Widget - Shows movies with some but not enough likes
class _PartialMatchCard extends ConsumerWidget {
  final PartialMatch partialMatch;

  const _PartialMatchCard({required this.partialMatch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = partialMatch.movie;
    final tmdbService = ref.watch(tmdbServiceProvider);

    return GestureDetector(
      onTap: () => _showMovieDetails(context, movie, ref),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster
              CachedNetworkImage(
                imageUrl: tmdbService.getPosterUrl(movie.posterPath),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(Icons.error, size: 48, color: Colors.red),
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              // Partial match badge (orange)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    partialMatch.displayText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Title and info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.displayTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        partialMatch.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryOrange.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (movie.releaseYear != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          movie.releaseYear.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMovieDetails(BuildContext context, Movie movie, WidgetRef ref) {
    final tmdbService = ref.read(tmdbServiceProvider);

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceDark,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poster
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: tmdbService.getPosterUrl(movie.posterPath, size: 'w780'),
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: AppTheme.surfaceDark,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        movie.displayTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Year and Rating
                      Row(
                        children: [
                          if (movie.releaseYear != null) ...[
                            const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryGold),
                            const SizedBox(width: 4),
                            Text(movie.releaseYear.toString()),
                            const SizedBox(width: 16),
                          ],
                          if (movie.voteAverage != null) ...[
                            const Icon(Icons.star, size: 16, color: AppTheme.primaryGold),
                            const SizedBox(width: 4),
                            Text(movie.voteAverage!.toStringAsFixed(1)),
                          ],
                        ],
                      ),

                      if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Overzicht',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.overview!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
