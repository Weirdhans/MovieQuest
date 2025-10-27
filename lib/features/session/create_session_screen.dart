import 'dart:async';

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

  // Expansion states for provider categories
  bool _subscriptionExpanded = true;
  bool _payPerViewExpanded = false;
  bool _freeExpanded = false;

  // No preference checkbox
  bool _noPreference = false;

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
    final genreMatchMode = ref.watch(genreMatchModeProvider);
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

            // No Preference Option
            _buildNoPreferenceCheckbox(),

            const SizedBox(height: 12),

            // Subscription Services
            _buildProviderCategory(
              title: '📺 Abonnement diensten',
              expanded: _subscriptionExpanded,
              onToggle: () => setState(() => _subscriptionExpanded = !_subscriptionExpanded),
              providers: StreamingProviders.subscription,
              selectedProviders: selectedProviders,
              showWarning: true,
            ),

            const SizedBox(height: 8),

            // Pay-Per-View Services
            _buildProviderCategory(
              title: '💰 Huur & Koop',
              expanded: _payPerViewExpanded,
              onToggle: () => setState(() => _payPerViewExpanded = !_payPerViewExpanded),
              providers: StreamingProviders.payPerView,
              selectedProviders: selectedProviders,
            ),

            const SizedBox(height: 8),

            // Free Services
            _buildProviderCategory(
              title: '🆓 Gratis diensten',
              expanded: _freeExpanded,
              onToggle: () => setState(() => _freeExpanded = !_freeExpanded),
              providers: StreamingProviders.free,
              selectedProviders: selectedProviders,
            ),

            // Provider validation warning
            if (!_noPreference && selectedProviders.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '⚠️ Selecteer minimaal 1 streaming dienst of kies "Geen voorkeur"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade300,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Genres Section
            _buildSectionTitle('Genres'),
            const SizedBox(height: 12),

            // Genre Match Mode Selection
            _buildGenreMatchModeSelector(genreMatchMode),

            const SizedBox(height: 16),

            // Genre Chips
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

            // Genre validation warning
            if (selectedGenres.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '⚠️ Selecteer minimaal 1 genre',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade300,
                  ),
                ),
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
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
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
            Text(
              'Bijv: Bij $requiredVotes stemmen = match als minimaal $requiredVotes ${requiredVotes == 1 ? "persoon" : "personen"} de film leuk ${requiredVotes == 1 ? "vindt" : "vinden"}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
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
                  borderSide: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
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
                    ? _createSession
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

  Widget _buildNoPreferenceCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _noPreference = !_noPreference;
          if (_noPreference) {
            // Clear selected providers when no preference is selected
            ref.read(selectedProvidersProvider.notifier).state = [];
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _noPreference ? AppTheme.primaryGold.withValues(alpha: 0.1) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _noPreference ? AppTheme.primaryGold : AppTheme.primaryGold.withValues(alpha: 0.3),
            width: _noPreference ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _noPreference ? Icons.check_box : Icons.check_box_outline_blank,
              color: _noPreference ? AppTheme.primaryGold : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            const Text(
              '✨ Geen voorkeur (alle diensten)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCategory({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List<StreamingProvider> providers,
    required List<String> selectedProviders,
    bool showWarning = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppTheme.primaryGold,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 12),
          if (showWarning)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '⚠️ Sommige films kunnen extra kosten hebben (Prime Video & Apple TV)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade300,
                ),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: providers.map((provider) {
              final isSelected = selectedProviders.contains(provider.id);
              return _FilterChip(
                label: provider.name,
                selected: isSelected && !_noPreference,
                onSelected: _noPreference ? null : (selected) {
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
        ],
      ],
    );
  }

  Widget _buildGenreMatchModeSelector(String currentMode) {
    return Column(
      children: GenreMatchMode.values.map((mode) {
        final isSelected = currentMode == mode.value;
        return InkWell(
          onTap: () {
            ref.read(genreMatchModeProvider.notifier).state = mode.value;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryGold.withValues(alpha: 0.1) : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGold : AppTheme.primaryGold.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.primaryGold : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        mode.description,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _canCreateSession(List<String> providers, List<String> genres) {
    // Must have genres, and either providers selected or no preference
    return genres.isNotEmpty && (_noPreference || providers.isNotEmpty);
  }

  Future<void> _createSession() async {
    final selectedProviders = _noPreference ? <String>[] : ref.read(selectedProvidersProvider);
    final selectedGenres = ref.read(selectedGenresProvider);
    final selectedCertification = ref.read(selectedCertificationProvider);
    final requiredVotes = ref.read(requiredVotesProvider);
    final genreMatchMode = ref.read(genreMatchModeProvider);
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
        genreMatchMode: genreMatchMode,
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

          // Navigate to session created screen
          if (mounted) {
            unawaited(Navigator.pushReplacementNamed(context, '/session-created'));
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
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

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
        color: selected ? AppTheme.primaryGold : AppTheme.primaryGold.withValues(alpha: 0.3),
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
  const _GradientButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

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
                  color: AppTheme.primaryOrange.withValues(alpha: 0.3),
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
