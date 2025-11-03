import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/responsive_constants.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/dev_log.dart';
import '../../shared/widgets/responsive_wrapper.dart';

/// Multi-Step Wizard for Creating a Session
class CreateSessionWizard extends ConsumerStatefulWidget {
  const CreateSessionWizard({super.key});

  @override
  ConsumerState<CreateSessionWizard> createState() => _CreateSessionWizardState();
}

class _CreateSessionWizardState extends ConsumerState<CreateSessionWizard> {
  int _currentStep = 0;
  final TextEditingController _hostNameController = TextEditingController();

  // Expansion states for provider categories (Step 1)
  bool _subscriptionExpanded = true;
  bool _payPerViewExpanded = false;
  bool _freeExpanded = false;
  bool _noPreference = false;

  // Filter and sort state variables (Step 3)
  static const int minYearEver = 1888;  // Eerste film in TMDB database
  static int get currentYear => DateTime.now().year;  // Dynamisch huidige jaar

  double _minRating = 1.0;  // Min TMDB rating (1.0-10.0)
  int _minYear = minYearEver;  // Release year start
  late int _maxYear = currentYear;  // Release year end (default = huidige jaar)
  String _sortBy = 'popularity.desc';  // Sort option

  @override
  void dispose() {
    _hostNameController.dispose();
    super.dispose();
  }

  // Wizard steps configuration
  static const int totalSteps = 4;
  static const List<String> stepTitles = [
    'Waar wil je kijken?',
    'Wat wil je kijken?',
    'Verfijn je zoekopdracht',
    'Start je MovieQuest!',
  ];

  static const List<String> stepIcons = ['🎬', '🎭', '⚙️', '🚀'];

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If not on first step, go back to previous step
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
          });
        } else {
          // On first step, navigate back to home
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nieuwe Sessie'),
          centerTitle: true,
          automaticallyImplyLeading: !kIsWeb,
        ),
      body: ResponsiveWrapper(
        maxWidth: ResponsiveConstants.formScreenMaxWidth,
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),

            // Step Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStepContent(),
            ),

            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == totalSteps - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppTheme.primaryGold
                        : AppTheme.primaryGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Step title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stepIcons[_currentStep],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stap ${_currentStep + 1} van $totalSteps',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      stepTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: switch (_currentStep) {
        0 => _buildStep1StreamingServices(),
        1 => _buildStep2Genres(),
        2 => _buildStep3Options(),
        3 => _buildStep4Summary(),
        _ => const SizedBox(),
      },
    );
  }

  // STEP 1: Streaming Services
  Widget _buildStep1StreamingServices() {
    final selectedProviders = ref.watch(selectedProvidersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecteer waar je films wilt bekijken',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
          ),
        ),

        const SizedBox(height: 24),

        // No Preference Option
        _buildNoPreferenceCheckbox(),

        const SizedBox(height: 16),

        // Subscription Services
        _buildProviderCategory(
          title: '📺 Abonnement diensten',
          expanded: _subscriptionExpanded,
          onToggle: () => setState(() => _subscriptionExpanded = !_subscriptionExpanded),
          providers: StreamingProviders.subscription,
          selectedProviders: selectedProviders,
          showWarning: true,
        ),

        const SizedBox(height: 12),

        // Pay-Per-View Services
        _buildProviderCategory(
          title: '💰 Huur & Koop',
          expanded: _payPerViewExpanded,
          onToggle: () => setState(() => _payPerViewExpanded = !_payPerViewExpanded),
          providers: StreamingProviders.payPerView,
          selectedProviders: selectedProviders,
        ),

        const SizedBox(height: 12),

        // Free Services
        _buildProviderCategory(
          title: '🆓 Gratis diensten',
          expanded: _freeExpanded,
          onToggle: () => setState(() => _freeExpanded = !_freeExpanded),
          providers: StreamingProviders.free,
          selectedProviders: selectedProviders,
        ),

        // Validation warning
        if (!_noPreference && selectedProviders.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '⚠️ Selecteer minimaal 1 streaming dienst of kies "Geen voorkeur"',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade300,
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  // STEP 2: Genres
  Widget _buildStep2Genres() {
    final selectedGenres = ref.watch(selectedGenresProvider);
    final excludedGenres = ref.watch(excludedGenresProvider);
    final genreMatchMode = ref.watch(genreMatchModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kies de genres die je interesseren',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
          ),
        ),

        const SizedBox(height: 24),

        // Genre Match Mode - Compact Segmented Control
        _buildCompactGenreMatchMode(genreMatchMode),

        const SizedBox(height: 24),

        // Genre Chips
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: Genres.list.map((genre) {
            final isSelected = selectedGenres.contains(genre.id);
            final isExcluded = excludedGenres.contains(genre.id);

            return _ThreeStateFilterChip(
              label: genre.name,
              isSelected: isSelected,
              isExcluded: isExcluded,
              onTap: () {
                final selectedNotifier = ref.read(selectedGenresProvider.notifier);
                final excludedNotifier = ref.read(excludedGenresProvider.notifier);

                if (isSelected) {
                  // State 1→2: Selected → Excluded
                  selectedNotifier.state = selectedGenres.where((id) => id != genre.id).toList();
                  excludedNotifier.state = [...excludedGenres, genre.id];
                } else if (isExcluded) {
                  // State 2→0: Excluded → Unselected
                  excludedNotifier.state = excludedGenres.where((id) => id != genre.id).toList();
                } else {
                  // State 0→1: Unselected → Selected
                  selectedNotifier.state = [...selectedGenres, genre.id];
                }
              },
            );
          }).toList(),
        ),

        // Validation warning
        if (selectedGenres.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '⚠️ Selecteer minimaal 1 genre',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade300,
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  // STEP 3: Options (Certification + Votes)
  Widget _buildStep3Options() {
    final selectedCertification = ref.watch(selectedCertificationProvider);
    final requiredVotes = ref.watch(requiredVotesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pas de instellingen aan naar wens (optioneel)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
          ),
        ),

        const SizedBox(height: 32),

        // Certification Section
        Text(
          'Maximale Leeftijdsclassificatie',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
        Text(
          'Aantal Vereiste Likes',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
          'Bij $requiredVotes ${requiredVotes == 1 ? "stem" : "stemmen"} = match als minimaal $requiredVotes ${requiredVotes == 1 ? "persoon" : "personen"} de film leuk ${requiredVotes == 1 ? "vindt" : "vinden"}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
        ),

        const SizedBox(height: 32),

        // ===== NEW FILTER CONTROLS =====

        // Minimum Rating Slider
        Text(
          '⭐ Minimale Rating',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toon alleen films met minimaal deze TMDB-rating',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _minRating,
                min: 1.0,
                max: 10.0,
                divisions: 18,  // 0.5 steps
                label: _minRating.toStringAsFixed(1),
                activeColor: AppTheme.primaryGold,
                onChanged: (value) => setState(() => _minRating = value),
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
                '${_minRating.toStringAsFixed(1)} ⭐',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Release Year Range Slider
        Text(
          '📅 Release Jaar',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Films uitgebracht tussen $minYearEver en $currentYear',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(_minYear.toDouble(), _maxYear.toDouble()),
          min: minYearEver.toDouble(),
          max: currentYear.toDouble(),
          divisions: currentYear - minYearEver,
          labels: RangeLabels(_minYear.toString(), _maxYear.toString()),
          activeColor: AppTheme.primaryGold,
          onChanged: (RangeValues values) {
            setState(() {
              _minYear = values.start.round();
              _maxYear = values.end.round();
            });
          },
        ),
        Text(
          'Huidige bereik: $_minYear - $_maxYear',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.primaryGold,
          ),
        ),

        const SizedBox(height: 32),

        // Sort Dropdown
        Text(
          '📊 Sorteer op',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Volgorde waarin films verschijnen (voor alle leden)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _sortBy,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: AppTheme.primaryGold),
            ),
          ),
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: 'popularity.desc', child: Text('📊 Populariteit (aanbevolen)')),
            DropdownMenuItem(value: 'vote_average.desc', child: Text('⭐ Rating (hoog → laag)')),
            DropdownMenuItem(value: 'vote_average.asc', child: Text('⭐ Rating (laag → hoog)')),
            DropdownMenuItem(value: 'title.asc', child: Text('🔤 Naam (A → Z)')),
            DropdownMenuItem(value: 'title.desc', child: Text('🔤 Naam (Z → A)')),
            DropdownMenuItem(value: 'primary_release_date.desc', child: Text('📅 Jaar (nieuw → oud)')),
            DropdownMenuItem(value: 'primary_release_date.asc', child: Text('📅 Jaar (oud → nieuw)')),
            DropdownMenuItem(value: 'random', child: Text('🎲 Willekeurig')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _sortBy = value);
            }
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // STEP 4: Summary + Name
  Widget _buildStep4Summary() {
    final selectedProviders = _noPreference ? <String>[] : ref.watch(selectedProvidersProvider);
    final selectedGenres = ref.watch(selectedGenresProvider);
    final selectedCertification = ref.watch(selectedCertificationProvider);
    final requiredVotes = ref.watch(requiredVotesProvider);
    final genreMatchMode = ref.watch(genreMatchModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Controleer je keuzes en start de sessie!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
          ),
        ),

        const SizedBox(height: 24),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streaming Services
              _buildSummaryItem(
                icon: '🎬',
                title: 'Streamingdiensten',
                value: _noPreference
                    ? 'Alle diensten'
                    : selectedProviders.isEmpty
                        ? 'Geen geselecteerd'
                        : selectedProviders
                            .map((id) => StreamingProviders.getNameById(id))
                            .join(', '),
                onEdit: () => setState(() => _currentStep = 0),
              ),

              const Divider(height: 32, color: Colors.grey),

              // Genres
              _buildSummaryItem(
                icon: '🎭',
                title: 'Genres (${genreMatchMode == 'all' ? 'ALLE' : 'ÉÉN'})',
                value: selectedGenres.isEmpty
                    ? 'Geen geselecteerd'
                    : selectedGenres.map((id) => Genres.getNameById(id)).join(', '),
                onEdit: () => setState(() => _currentStep = 1),
              ),

              const Divider(height: 32, color: Colors.grey),

              // Options
              _buildSummaryItem(
                icon: '⚙️',
                title: 'Instellingen',
                value: 'Max ${Certifications.list.firstWhere((c) => c.value == selectedCertification).label} • $requiredVotes ${requiredVotes == 1 ? 'like' : 'likes'} vereist',
                onEdit: () => setState(() => _currentStep = 2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Host Name Section
        Text(
          'Jouw Naam (optioneel)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummaryItem({
    required String icon,
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, color: AppTheme.primaryGold, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildNoPreferenceCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _noPreference = !_noPreference;
          if (_noPreference) {
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
                onSelected: _noPreference
                    ? null
                    : (selected) {
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

  Widget _buildCompactGenreMatchMode(String currentMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Genre matching',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surfaceDark,
                    title: const Text('Genre Matching', style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ALLE geselecteerde genres:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                        ),
                        const Text(
                          'Films moeten álle gekozen genres hebben (specifiekere zoekresultaten)',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ÉÉN van de genres:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                        ),
                        const Text(
                          'Films met minimaal één van de genres (meer resultaten)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Begrepen', style: TextStyle(color: AppTheme.primaryGold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  label: 'ALLE',
                  value: 'all',
                  currentValue: currentMode,
                  isFirst: true,
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  label: 'ÉÉN',
                  value: 'any',
                  currentValue: currentMode,
                  isLast: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required String value,
    required String currentValue,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = value == currentValue;

    return InkWell(
      onTap: () => ref.read(genreMatchModeProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(7) : Radius.zero,
            right: isLast ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final selectedProviders = ref.watch(selectedProvidersProvider);
    final selectedGenres = ref.watch(selectedGenresProvider);
    final canProceed = _canProceedFromStep(_currentStep, selectedProviders, selectedGenres);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Terug',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Next/Create Button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: _GradientButton(
              onPressed: canProceed ? _handleNextOrCreate : null,
              child: Text(
                _currentStep == totalSteps - 1 ? 'Sessie Aanmaken' : 'Volgende',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedFromStep(int step, List<String> providers, List<String> genres) {
    switch (step) {
      case 0:
        return _noPreference || providers.isNotEmpty;
      case 1:
        return genres.isNotEmpty;
      case 2:
        return true; // Options are optional
      case 3:
        return true; // Summary, always can proceed
      default:
        return false;
    }
  }

  void _handleNextOrCreate() {
    if (_currentStep < totalSteps - 1) {
      // Go to next step
      setState(() => _currentStep++);
    } else {
      // Create session (final step)
      _createSession();
    }
  }

  Future<void> _createSession() async {
    final selectedProviders = _noPreference ? <String>[] : ref.read(selectedProvidersProvider);
    final selectedGenres = ref.read(selectedGenresProvider);
    final excludedGenres = ref.read(excludedGenresProvider);
    final selectedCertification = ref.read(selectedCertificationProvider);
    final requiredVotes = ref.read(requiredVotesProvider);
    final genreMatchMode = ref.read(genreMatchModeProvider);
    final hostName = _hostNameController.text.trim();

    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final utilsService = ref.read(utilsServiceProvider);
      final userIdResult = await utilsService.getUserId();
      final userId = userIdResult.when(
        success: (id) => id,
        error: (error) => throw error,
      );

      final supabaseService = ref.read(supabaseServiceProvider);
      final result = await supabaseService.createSession(
        hostUserId: userId,
        streamingProviders: selectedProviders,
        genres: selectedGenres,
        maxCertification: selectedCertification,
        requiredVotes: requiredVotes,
        genreMatchMode: genreMatchMode,
        excludedGenres: excludedGenres.isNotEmpty ? excludedGenres : null,
        minRating: _minRating,
        minYear: _minYear,
        maxYear: _maxYear,
        sortBy: _sortBy,
      );

      await result.when(
        success: (session) async {
          devLogSuccess('Session created: ${session['id']}');

          final sessionId = session['id'] as String;
          ref.read(hostNameProvider.notifier).state = hostName;
          ref.read(currentSessionIdProvider.notifier).state = sessionId;

          final memberName = hostName.isNotEmpty ? hostName : 'Host';
          final joinResult = await supabaseService.joinSession(
            sessionId: sessionId,
            userId: userId,
            userName: memberName,
          );

          joinResult.when(
            success: (member) => devLogSuccess('Host joined session as: $memberName'),
            error: (error) => devLogError('Failed to join session as host', error),
          );

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

/// Three-state filter chip widget (Unselected → Selected → Excluded)
class _ThreeStateFilterChip extends StatefulWidget {
  const _ThreeStateFilterChip({
    required this.label,
    required this.isSelected,
    required this.isExcluded,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isExcluded;
  final VoidCallback onTap;

  @override
  State<_ThreeStateFilterChip> createState() => _ThreeStateFilterChipState();
}

class _ThreeStateFilterChipState extends State<_ThreeStateFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Trigger haptic feedback
    await HapticFeedback.lightImpact();

    // Animate
    await _controller.forward();
    await _controller.reverse();

    // Execute callback
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Widget? icon;
    TextDecoration? textDecoration;

    if (widget.isSelected) {
      // State 1: Selected (yellow/gold)
      backgroundColor = AppTheme.primaryGold;
      textColor = Colors.black;
      icon = const Icon(Icons.check, size: 16, color: Colors.black);
      textDecoration = null;
    } else if (widget.isExcluded) {
      // State 2: Excluded (red with strikethrough)
      backgroundColor = const Color(0xFFD32F2F);
      textColor = Colors.white;
      icon = const Icon(Icons.close, size: 16, color: Colors.white);
      textDecoration = TextDecoration.lineThrough;
    } else {
      // State 0: Unselected (dark)
      backgroundColor = AppTheme.surfaceDark;
      textColor = Colors.white;
      icon = null;
      textDecoration = null;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryGold
                  : widget.isExcluded
                      ? const Color(0xFFD32F2F)
                      : AppTheme.primaryGold.withValues(alpha: 0.3),
              width: widget.isSelected || widget.isExcluded ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: widget.isSelected || widget.isExcluded
                      ? FontWeight.bold
                      : FontWeight.normal,
                  decoration: textDecoration,
                  decorationColor: textColor,
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
