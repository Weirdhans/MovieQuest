import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/movie.dart';
import '../../core/utils/dev_log.dart';
import '../../core/interfaces/i_tmdb_service.dart';
import '../../shared/widgets/members_button.dart';

/// Swipe Screen - Main movie swiping interface
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  bool _isInitialized = false;
  final List<Movie> _movies = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  int _currentCardIndex = 0;

  // Undo functionality - track last 5 swipes (FIFO queue)
  final List<int> _swipeHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMovies();
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _initializeMovies() async {
    if (_isInitialized) return;

    final sessionId = ref.read(currentSessionIdProvider);
    if (sessionId == null) {
      _showError('Geen actieve sessie');
      return;
    }

    setState(() => _isInitialized = true);

    // Get session details to fetch filters
    final supabaseService = ref.read(supabaseServiceProvider);
    final sessionResult = await supabaseService.getSession(sessionId);

    await sessionResult.when(
      success: (session) async {
        final providers = (session['streaming_providers'] as List<dynamic>).map((e) => e.toString()).toList();
        final genres = (session['genres'] as List<dynamic>).map((e) => e.toString()).toList();
        final maxCertification = session['max_certification'] as String;
        final genreMatchMode = session['genre_match_mode'] as String? ?? 'any';

        // Fetch movies from TMDB
        await _fetchMovies(providers, genres, maxCertification, genreMatchMode, sessionId);
      },
      error: (error) {
        devLogError('Failed to get session', error);
        _showError('Fout bij ophalen sessie: ${error.message}');
      },
    );
  }

  Future<void> _fetchMovies(
    List<String> providers,
    List<String> genres,
    String maxCertification,
    String genreMatchMode,
    String sessionId,
  ) async {
    final tmdbService = ref.read(tmdbServiceProvider);
    final result = await tmdbService.fetchMovies(
      providers: providers,
      genres: genres,
      maxCertification: maxCertification,
      genreMatchMode: genreMatchMode,
      sessionId: sessionId,
      page: _currentPage,
    );

    result.when(
      success: (data) {
        final moviesJson = data['results'] as List<dynamic>;
        final movies = moviesJson.map((json) => Movie.fromJson(json as Map<String, dynamic>)).toList();

        setState(() {
          _movies.addAll(movies);
          // Clear swipe history when loading new batch
          if (_currentPage == 1) {
            _swipeHistory.clear();
          }
        });

        devLogSuccess('Loaded ${movies.length} movies (page $_currentPage)');
      },
      error: (error) {
        devLogError('Failed to fetch movies', error);
        _showError('Fout bij ophalen films: ${error.message}');
      },
    );
  }

  Future<void> _handleSwipe(int index, bool swipedRight) async {
    if (index >= _movies.length) return;

    final movie = _movies[index];
    final sessionId = ref.read(currentSessionIdProvider);
    if (sessionId == null) return;

    // Get user ID
    final utilsService = ref.read(utilsServiceProvider);
    final userIdResult = await utilsService.getUserId();
    final userId = userIdResult.when(
      success: (id) => id,
      error: (error) {
        devLogError('Failed to get user ID', error);
        return null;
      },
    );

    if (userId == null) return;

    // Record swipe
    final supabaseService = ref.read(supabaseServiceProvider);
    final swipeResult = await supabaseService.recordSwipe(
      sessionId: sessionId,
      userId: userId,
      movieId: movie.id,
      swipedRight: swipedRight,
      movieData: movie.toJson(),
    );

    swipeResult.when(
      success: (_) {
        devLog('Swipe recorded: ${swipedRight ? 'LIKE' : 'DISLIKE'} for ${movie.title}');

        // Add to swipe history (keep last 5)
        setState(() {
          _swipeHistory.add(movie.id);
          if (_swipeHistory.length > 5) {
            _swipeHistory.removeAt(0); // Remove oldest (FIFO)
          }
        });

        // Check for match if liked
        if (swipedRight) {
          _checkForMatch(sessionId, movie);
        }
      },
      error: (error) {
        devLogError('Failed to record swipe', error);
      },
    );

    // Load more movies if running low
    if (index >= _movies.length - 3 && !_isLoadingMore) {
      unawaited(_loadMoreMovies());
    }
  }

  Future<void> _checkForMatch(String sessionId, Movie movie) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    final matchResult = await supabaseService.checkAndCreateMatch(
      sessionId: sessionId,
      movieId: movie.id,
      movieData: movie.toJson(),
    );

    matchResult.when(
      success: (data) {
        if (data['is_match'] == true) {
          devLogSuccess('MATCH! ${movie.title}');
          _showMatchNotification(movie);
          _confettiController.play();
        }
      },
      error: (error) {
        devLogError('Failed to check match', error);
      },
    );
  }

  Future<void> _loadMoreMovies() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    final sessionId = ref.read(currentSessionIdProvider);
    if (sessionId == null) return;

    final supabaseService = ref.read(supabaseServiceProvider);
    final sessionResult = await supabaseService.getSession(sessionId);

    await sessionResult.when(
      success: (session) async {
        final providers = (session['streaming_providers'] as List<dynamic>).map((e) => e.toString()).toList();
        final genres = (session['genres'] as List<dynamic>).map((e) => e.toString()).toList();
        final maxCertification = session['max_certification'] as String;
        final genreMatchMode = session['genre_match_mode'] as String? ?? 'any';

        await _fetchMovies(providers, genres, maxCertification, genreMatchMode, sessionId);
        setState(() => _isLoadingMore = false);
      },
      error: (error) {
        setState(() => _isLoadingMore = false);
      },
    );
  }

  Future<void> _handleUndo() async {
    if (_swipeHistory.isEmpty) return;

    final sessionId = ref.read(currentSessionIdProvider);
    if (sessionId == null) return;

    // Get user ID
    final utilsService = ref.read(utilsServiceProvider);
    final userIdResult = await utilsService.getUserId();
    final userId = userIdResult.when(
      success: (id) => id,
      error: (error) {
        devLogError('Failed to get user ID', error);
        return null;
      },
    );

    if (userId == null) return;

    devLog('Undo laatste swipe...');

    // Call undo RPC function
    final supabaseService = ref.read(supabaseServiceProvider);
    final undoResult = await supabaseService.undoLastSwipe(
      sessionId: sessionId,
      userId: userId,
    );

    undoResult.when(
      success: (data) {
        if (data['success'] == true) {
          devLogSuccess('Swipe ongedaan gemaakt: ${data['movie_id']}');

          // Remove last item from history
          setState(() {
            if (_swipeHistory.isNotEmpty) {
              _swipeHistory.removeLast();
            }

            // Go back to previous card if possible
            if (_currentCardIndex > 0) {
              _currentCardIndex--;
            }
          });

          // Use unswipe functionality if available
          _swiperController.unswipe();

          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Swipe ongedaan gemaakt'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showError((data['message'] as String?) ?? 'Kon swipe niet ongedaan maken');
        }
      },
      error: (error) {
        devLogError('Failed to undo swipe', error);
        _showError('Kon swipe niet ongedaan maken: ${error.message}');
      },
    );
  }

  void _showMatchNotification(Movie movie) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: AppTheme.primaryGold, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MATCH!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  Text(
                    movie.title,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareSession() {
    final sessionId = ref.read(currentSessionIdProvider);
    if (sessionId == null) {
      _showError('Geen actieve sessie gevonden');
      return;
    }

    // Get current host and port from browser
    final currentUrl = Uri.base;
    final host = currentUrl.host.isEmpty ? 'localhost' : currentUrl.host;
    final port = currentUrl.port;
    final portStr = port == 80 || port == 443 ? '' : ':$port';
    final scheme = currentUrl.scheme;

    final joinUrl = '$scheme://$host$portStr/#/?join=$sessionId';

    devLog('Session link generated: $joinUrl');

    // Show dialog with link and copy button
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.share, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text('Deel Sessie', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deel deze link met anderen om samen films te vinden:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                joinUrl,
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sessie ID: $sessionId',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: joinUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link gekopieerd!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Kopieer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              Share.share(
                'Join mijn MovieQuest sessie! $joinUrl',
                subject: 'MovieQuest - Samen films vinden',
              );
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('Deel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMovieDetails() {
    if (_currentCardIndex >= _movies.length) return;

    final movie = _movies[_currentCardIndex];
    final tmdbService = ref.read(tmdbServiceProvider);

    showDialog<void>(
      context: context,
      builder: (context) => _MovieDetailsDialog(movie: movie, tmdbService: tmdbService),
    );
  }

  Future<void> _showTrailerDialog() async {
    if (_currentCardIndex >= _movies.length) return;

    final movie = _movies[_currentCardIndex];
    final tmdbService = ref.read(tmdbServiceProvider);

    // Show loading dialog
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    ));

    // Fetch trailer
    final result = await tmdbService.fetchMovieTrailer(movie.id);

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    result.when(
      success: (trailerUrl) {
        if (trailerUrl != null && trailerUrl.isNotEmpty) {
          _showTrailerPopup(movie, trailerUrl);
        } else {
          _showError('Geen trailer beschikbaar voor deze film');
        }
      },
      error: (error) {
        devLogError('Failed to fetch trailer', error);
        _showError('Geen trailer beschikbaar voor deze film');
      },
    );
  }

  void _showTrailerPopup(Movie movie, String videoId) {
    // Create YouTube player controller
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle, color: AppTheme.primaryOrange, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () {
                        controller.close();
                        Navigator.pop(context);
                      },
                      tooltip: 'Sluiten',
                    ),
                  ],
                ),
              ),
              // YouTube player - gebruik AspectRatio voor consistente sizing
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: YoutubePlayer(
                      controller: controller,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Cleanup controller when dialog is dismissed
      controller.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('MovieQuest'),
            if (_movies.isNotEmpty)
              Text(
                'Film ${_currentCardIndex + 1} / ${_movies.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          const MembersButton(),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSession,
            tooltip: 'Deel Sessie',
          ),
          IconButton(
            icon: const Icon(Icons.movie),
            onPressed: () {
              Navigator.pushNamed(context, '/matches');
            },
            tooltip: 'Bekijk Matches',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.darkBackground, Color(0xFF1A0E0E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main content
          if (!_isInitialized)
            const Center(child: CircularProgressIndicator())
          else if (_movies.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_filter, size: 64, color: AppTheme.primaryGold),
                  const SizedBox(height: 16),
                  const Text(
                    'Geen films gevonden',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pas je filters aan',
                    style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  // Swiper
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppinioSwiper(
                        controller: _swiperController,
                        cardCount: _movies.length,
                        swipeOptions: const SwipeOptions.symmetric(horizontal: true), // Only left/right
                        cardBuilder: (context, index) {
                          return _MovieCard(movie: _movies[index]);
                        },
                        onSwipeEnd: (previousIndex, targetIndex, activity) {
                          // Update current card index
                          setState(() {
                            _currentCardIndex = targetIndex;
                          });

                          // Check if it's an actual swipe (not unswipe or cancel)
                          if (activity is Swipe) {
                            final direction = activity.direction;
                            final swipedRight = direction == AxisDirection.right;
                            _handleSwipe(previousIndex, swipedRight);
                          }
                        },
                        onEnd: () {
                          devLog('No more cards!');
                        },
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Undo Button (LEFT of Nope)
                        _UndoButton(
                          undoCount: _swipeHistory.length,
                          onPressed: _swipeHistory.isEmpty ? null : _handleUndo,
                        ),

                        // Dislike Button
                        _ActionButton(
                          icon: Icons.close,
                          color: Colors.red,
                          label: 'Nope',
                          onPressed: () {
                            _swiperController.swipeLeft();
                          },
                        ),

                        // Trailer Button
                        _ActionButton(
                          icon: Icons.play_circle_outline,
                          color: AppTheme.primaryOrange,
                          label: 'Trailer',
                          size: 48,
                          onPressed: () {
                            _showTrailerDialog();
                          },
                        ),

                        // Info Button
                        _ActionButton(
                          icon: Icons.info_outline,
                          color: AppTheme.primaryGold,
                          label: 'Info',
                          size: 48,
                          onPressed: () {
                            _showMovieDetails();
                          },
                        ),

                        // Like Button
                        _ActionButton(
                          icon: Icons.favorite,
                          color: Colors.green,
                          label: 'Like',
                          onPressed: () {
                            _swiperController.swipeRight();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                AppTheme.primaryGold,
                AppTheme.primaryOrange,
                AppTheme.deepRed,
                Colors.green,
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Movie Card Widget
class _MovieCard extends ConsumerWidget {
  final Movie movie;

  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tmdbService = ref.watch(tmdbServiceProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Movie Poster with black background
            Container(
              color: Colors.black,
              child: CachedNetworkImage(
                imageUrl: tmdbService.getPosterUrl(movie.posterPath, size: 'w780'),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(Icons.error, size: 64, color: Colors.red),
                ),
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
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
            ),

            // Movie Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Year and Rating
                    Row(
                      children: [
                        if (movie.releaseYear != null) ...[
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryGold),
                          const SizedBox(width: 4),
                          Text(
                            movie.releaseYear.toString(),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (movie.voteAverage != null) ...[
                          const Icon(Icons.star, size: 16, color: AppTheme.primaryGold),
                          const SizedBox(width: 4),
                          Text(
                            movie.voteAverage!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ],
                    ),

                    if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        movie.overview!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
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
    );
  }
}

/// Movie Details Dialog Widget
class _MovieDetailsDialog extends ConsumerStatefulWidget {
  final Movie movie;
  final ITmdbService tmdbService;

  const _MovieDetailsDialog({
    required this.movie,
    required this.tmdbService,
  });

  @override
  ConsumerState<_MovieDetailsDialog> createState() => _MovieDetailsDialogState();
}

class _MovieDetailsDialogState extends ConsumerState<_MovieDetailsDialog> {
  String? _trailerUrl;
  bool _loadingTrailer = false;

  @override
  void initState() {
    super.initState();
    _loadTrailer();
  }

  Future<void> _loadTrailer() async {
    setState(() => _loadingTrailer = true);

    final result = await widget.tmdbService.fetchMovieTrailer(widget.movie.id);

    result.when(
      success: (url) {
        if (mounted) {
          setState(() {
            _trailerUrl = url;
            _loadingTrailer = false;
          });
        }
      },
      error: (error) {
        if (mounted) {
          setState(() => _loadingTrailer = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    imageUrl: widget.tmdbService.getPosterUrl(widget.movie.posterPath, size: 'w780'),
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
                      widget.movie.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Year and Rating
                    Row(
                      children: [
                        if (widget.movie.releaseYear != null) ...[
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryGold),
                          const SizedBox(width: 4),
                          Text(widget.movie.releaseYear.toString()),
                          const SizedBox(width: 16),
                        ],
                        if (widget.movie.voteAverage != null) ...[
                          const Icon(Icons.star, size: 16, color: AppTheme.primaryGold),
                          const SizedBox(width: 4),
                          Text(widget.movie.voteAverage!.toStringAsFixed(1)),
                        ],
                      ],
                    ),

                    if (widget.movie.overview != null && widget.movie.overview!.isNotEmpty) ...[
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
                        widget.movie.overview!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],

                    // Trailer Button
                    const SizedBox(height: 24),
                    if (_loadingTrailer)
                      const Center(child: CircularProgressIndicator())
                    else if (_trailerUrl != null)
                      ElevatedButton.icon(
                        onPressed: _showTrailer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Bekijk Trailer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      )
                    else
                      Text(
                        'Geen trailer beschikbaar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTrailer() async {
    if (_trailerUrl == null) return;

    // Create YouTube player controller
    final controller = YoutubePlayerController.fromVideoId(
      videoId: _trailerUrl!,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    if (!mounted) return;

    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          child: Column(
            children: [
              // Header with title and close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle, color: AppTheme.primaryOrange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        controller.close();
                        Navigator.pop(dialogContext);
                      },
                      tooltip: 'Sluiten',
                    ),
                  ],
                ),
              ),
              // YouTube player
              Expanded(
                child: YoutubePlayer(
                  controller: controller,
                  aspectRatio: 16 / 9,
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Cleanup controller when dialog is dismissed
      controller.close();
    }));
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final String? label;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 64,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 3),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            iconSize: size * 0.5,
            onPressed: onPressed,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

/// Undo Button Widget with badge
class _UndoButton extends StatelessWidget {
  final int undoCount;
  final VoidCallback? onPressed;

  const _UndoButton({
    required this.undoCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && undoCount > 0;
    final color = isEnabled ? Colors.grey : Colors.grey.shade800;
    const size = 64.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.undo,
                  color: color,
                ),
                iconSize: size * 0.5,
                onPressed: onPressed,
              ),
            ),
            // Badge with count
            if (undoCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.darkBackground, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  child: Center(
                    child: Text(
                      undoCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Undo',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
