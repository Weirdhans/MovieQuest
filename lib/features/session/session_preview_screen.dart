import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/responsive_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/dev_log.dart';
import '../../shared/widgets/responsive_wrapper.dart';

/// Session Preview Screen - Shows session details before joining
/// Displays host name, member count, filters (streaming providers, genres, age rating)
/// Similar to Discord server preview or WhatsApp group invite
class SessionPreviewScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionPreviewScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<SessionPreviewScreen> createState() => _SessionPreviewScreenState();
}

class _SessionPreviewScreenState extends ConsumerState<SessionPreviewScreen> {
  Map<String, dynamic>? _sessionData;
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = '';
  final _userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessionPreview();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionPreview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final result = await supabaseService.getSessionPreview(widget.sessionId);

      result.when(
        success: (Map<String, dynamic> data) {
          if (mounted) {
            setState(() {
              _sessionData = data;
              _isLoading = false;
            });
          }
        },
        error: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error.message as String?;
              _isLoading = false;
            });
          }
          devLogError('Failed to load session preview', error as Object);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden bij het laden van de sessie';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinSession() async {
    if (_sessionData == null) return;

    // Set loading state
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      // Get user ID
      final utilsService = ref.read(utilsServiceProvider);
      final userIdResult = await utilsService.getUserId();
      final userId = userIdResult.when(
        success: (id) => id,
        error: (error) => throw error,
      );

      // Join session
      final supabaseService = ref.read(supabaseServiceProvider);
      final result = await supabaseService.joinSession(
        sessionId: widget.sessionId,
        userId: userId,
        userName: _userName.isNotEmpty ? _userName : null,
      );

      result.when(
        success: (member) {
          devLogSuccess('Joined session: ${widget.sessionId}');

          // Set current session ID
          ref.read(currentSessionIdProvider.notifier).state = widget.sessionId;

          // Navigate to swipe screen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/swipe');
          }
        },
        error: (error) {
          devLogError('Failed to join session', error);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fout bij deelnemen: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessie Details'),
        centerTitle: true,
      ),
      body: ResponsiveWrapper(
        maxWidth: ResponsiveConstants.formScreenMaxWidth,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : _buildPreviewContent(isLoading),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 32),

            // Error Title
            const Text(
              'Sessie Niet Gevonden',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Error Message
            Text(
              _errorMessage ?? 'Deze sessie bestaat niet of is verlopen.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Ga naar Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/create-session'),
                  icon: const Icon(Icons.add),
                  label: const Text('Maak Nieuwe Sessie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(bool isLoading) {
    if (_sessionData == null) return const SizedBox();

    final hostName = _sessionData!['host_name'] as String? ?? 'Host';
    final memberCount = _sessionData!['total_members'] as int? ?? 1;
    final streamingProviderIds = List<String>.from((_sessionData!['streaming_providers'] as List?) ?? []);
    final genreIds = List<String>.from((_sessionData!['genres'] as List?) ?? []);
    final maxCert = _sessionData!['max_certification'] as String? ?? 'AL';
    final requiredVotes = _sessionData!['required_votes'] as int? ?? 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.phoenixGradient,
            ),
            child: const Icon(
              Icons.movie_filter,
              size: 64,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          const Text(
            'Sessie Aangemaakt!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Host Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 20, color: AppTheme.primaryGold),
              const SizedBox(width: 8),
              Text(
                'Gehost door $hostName',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Member Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group, size: 20, color: AppTheme.accentTurquoise),
              const SizedBox(width: 8),
              Text(
                '$memberCount ${memberCount == 1 ? 'lid' : 'leden'} al toegetreden',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Session Filters Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: AppTheme.primaryGold),
                    const SizedBox(width: 12),
                    Text(
                      'Sessie Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Streaming Providers
                _buildFilterSection(
                  'Streamingdiensten',
                  Icons.play_circle_outline,
                  streamingProviderIds.map((id) => StreamingProviders.getNameById(id)).toList(),
                ),

                const SizedBox(height: 16),

                // Genres
                _buildFilterSection(
                  'Genres',
                  Icons.category,
                  genreIds.map((id) => Genres.getNameById(id)).toList(),
                ),

                const SizedBox(height: 16),

                // Age Rating & Required Votes
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        'Leeftijdsgrens',
                        Icons.family_restroom,
                        Certifications.list.firstWhere((c) => c.value == maxCert, orElse: () => Certifications.list.first).label,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        'Stemmen Vereist',
                        Icons.how_to_vote,
                        '$requiredVotes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // User Name Input (Optional)
          TextFormField(
            controller: _userNameController,
            decoration: InputDecoration(
              labelText: 'Jouw Naam (Optioneel)',
              hintText: 'Bijv. Jan',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.primaryGold.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGold,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) => setState(() => _userName = value),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _joinSession(),
          ),

          const SizedBox(height: 24),

          // Join Button
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _GradientButton(
              onPressed: _joinSession,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Deelnemen aan Sessie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Cancel Button
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.accentTurquoise),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? Text(
                'Geen filters - alle opties toegestaan',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => Chip(
                  label: Text(item),
                  backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryOrange),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom gradient button widget
class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _GradientButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.phoenixGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}
