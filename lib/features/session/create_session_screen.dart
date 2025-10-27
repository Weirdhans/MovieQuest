import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/dev_log.dart';

/// Create Session Screen - Select filters and create a new session
class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final TextEditingController _hostNameController = TextEditingController();

  @override
  void dispose() {
    _hostNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProviders = ref.watch(selectedProvidersProvider);
    final selectedGenres = ref.watch(selectedGenresProvider);
    final selectedCertification = ref.watch(selectedCertificationProvider);
    final requiredVotes = ref.watch(requiredVotesProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuwe Sessie'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Streaming Providers Section
            _buildSectionTitle('Streamingdiensten'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: StreamingProviders.subscription.map((provider) {
                final isSelected = selectedProviders.contains(provider.id);
                return _FilterChip(
                  label: provider.name,
                  selected: isSelected,
                  onSelected: (selected) {
                    final notifier = ref.read(selectedProvidersProvider.notifier);
                    if (selected) {
                      notifier.state = [...selectedProviders, provider.id];
                    } else {
                      notifier.state = selectedProviders.where((id) => id != provider.id).toList();
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Genres Section
            _buildSectionTitle('Genres'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: Genres.list.map((genre) {
                final isSelected = selectedGenres.contains(genre.id);
                return _FilterChip(
                  label: genre.name,
                  selected: isSelected,
                  onSelected: (selected) {
                    final notifier = ref.read(selectedGenresProvider.notifier);
                    if (selected) {
                      notifier.state = [...selectedGenres, genre.id];
                    } else {
                      notifier.state = selectedGenres.where((id) => id != genre.id).toList();
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Certification Section
            _buildSectionTitle('Maximale Leeftijdsclassificatie'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: Certifications.list.map((cert) {
                final isSelected = selectedCertification == cert.value;
                return _FilterChip(
                  label: cert.label,
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(selectedCertificationProvider.notifier).state = cert.value;
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Required Votes Section
            _buildSectionTitle('Aantal Vereiste Likes'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: requiredVotes.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: requiredVotes.toString(),
                    activeColor: AppTheme.primaryGold,
                    onChanged: (value) {
                      ref.read(requiredVotesProvider.notifier).state = value.toInt();
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                  ),
                  child: Text(
                    requiredVotes.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Host Name Section
            _buildSectionTitle('Jouw Naam (optioneel)'),
            const SizedBox(height: 8),
            Text(
              'Zo weten anderen wie de sessie host is',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Bijv. Hans',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryGold.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryGold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 48),

            // Create Button
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _GradientButton(
                onPressed: _canCreateSession(selectedProviders, selectedGenres)
                    ? () => _createSession()
                    : null,
                child: const Text(
                  'Sessie Aanmaken',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  bool _canCreateSession(List<String> providers, List<String> genres) {
    return providers.isNotEmpty && genres.isNotEmpty;
  }

  Future<void> _createSession() async {
    final selectedProviders = ref.read(selectedProvidersProvider);
    final selectedGenres = ref.read(selectedGenresProvider);
    final selectedCertification = ref.read(selectedCertificationProvider);
    final requiredVotes = ref.read(requiredVotesProvider);
    final hostName = _hostNameController.text.trim();

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

      // Create session
      final supabaseService = ref.read(supabaseServiceProvider);
      final result = await supabaseService.createSession(
        hostUserId: userId,
        streamingProviders: selectedProviders,
        genres: selectedGenres,
        maxCertification: selectedCertification,
        requiredVotes: requiredVotes,
      );

      await result.when(
        success: (session) async {
          devLogSuccess('Session created: ${session['id']}');

          final sessionId = session['id'] as String;

          // Store host name in provider
          ref.read(hostNameProvider.notifier).state = hostName;

          // Set current session ID
          ref.read(currentSessionIdProvider.notifier).state = sessionId;

          // Join session as host with name (use 'Host' if no name provided)
          final memberName = hostName.isNotEmpty ? hostName : 'Host';
          final joinResult = await supabaseService.joinSession(
            sessionId: sessionId,
            userId: userId,
            userName: memberName,
          );

          joinResult.when(
            success: (member) {
              devLogSuccess('Host joined session as: $memberName');
            },
            error: (error) {
              devLogError('Failed to join session as host', error);
            },
          );

          // Navigate to swipe screen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/swipe');
          }
        },
        error: (error) {
          devLogError('Failed to create session', error);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fout bij aanmaken sessie: ${error.message}'),
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
}

/// Custom filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryGold,
      checkmarkColor: Colors.black,
      backgroundColor: AppTheme.surfaceDark,
      side: BorderSide(
        color: selected ? AppTheme.primaryGold : AppTheme.primaryGold.withOpacity(0.3),
        width: selected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

/// Custom gradient button widget
class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _GradientButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled ? AppTheme.phoenixGradient : null,
        color: isEnabled ? null : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
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
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.grey.shade600,
          ),
          child: child,
        ),
      ),
    );
  }
}
