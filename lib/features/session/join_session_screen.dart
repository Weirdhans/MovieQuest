import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/responsive_constants.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/dev_log.dart';
import '../../shared/widgets/responsive_wrapper.dart';

/// Join Session Screen - Enter session ID and join
class JoinSessionScreen extends ConsumerStatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  ConsumerState<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen> {
  final _sessionIdController = TextEditingController();
  final _userNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Check if session ID was passed as route argument (from auto-join)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionId = ModalRoute.of(context)?.settings.arguments as String?;
      if (sessionId != null && sessionId.isNotEmpty) {
        _sessionIdController.text = sessionId;
      }
    });
  }

  @override
  void dispose() {
    _sessionIdController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deelnemen aan Sessie'),
        centerTitle: true,
      ),
      body: ResponsiveWrapper(
        maxWidth: ResponsiveConstants.formScreenMaxWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.phoenixGradient,
                ),
                child: const Icon(
                  Icons.group_add,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Session ID Input
              TextFormField(
                controller: _sessionIdController,
                decoration: InputDecoration(
                  labelText: 'Sessie ID',
                  hintText: 'Voer de sessie ID in',
                  prefixIcon: const Icon(Icons.link),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Sessie ID is verplicht';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 24),

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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _joinSession(),
              ),

              const SizedBox(height: 48),

              // Join Button
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _GradientButton(
                  onPressed: _joinSession,
                  child: const Text(
                    'Deelnemen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Help Text
              Center(
                child: Text(
                  'Vraag de host om de sessie ID te delen',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _joinSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sessionId = _sessionIdController.text.trim();
    final userName = _userNameController.text.trim();

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
        sessionId: sessionId,
        userId: userId,
        userName: userName.isNotEmpty ? userName : null,
      );

      result.when(
        success: (member) {
          devLogSuccess('Joined session: $sessionId');

          // Set current session ID
          ref.read(currentSessionIdProvider.notifier).state = sessionId;

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
