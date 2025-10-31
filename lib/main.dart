import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'shared/services/supabase_service.dart';
import 'features/home/home_screen.dart';
import 'features/session/create_session_wizard.dart';
import 'features/session/session_created_screen.dart';
import 'features/session/join_session_screen.dart';
import 'features/session/session_preview_screen.dart';
import 'features/swipe/swipe_screen.dart';
import 'features/matches/matches_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path URL strategy for clean URLs on web (removes # from URLs)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize environment variables
  await EnvConfig.init();

  // Validate environment
  if (!EnvConfig.validate()) {
    throw Exception('❌ Environment variables niet correct geconfigureerd');
  }

  // Initialize Supabase
  await SupabaseService.init();

  runApp(
    const ProviderScope(
      child: MovieQuestApp(),
    ),
  );
}

class MovieQuestApp extends StatelessWidget {
  const MovieQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieQuest',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        // Handle new deep link format: /join/SESSION_ID
        if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'join') {
          if (uri.pathSegments.length > 1) {
            final sessionId = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (context) => SessionPreviewScreen(sessionId: sessionId),
            );
          }
        }

        // Handle legacy deep link format: /?join=SESSION_ID (for backward compatibility)
        if (uri.queryParameters.containsKey('join')) {
          final sessionId = uri.queryParameters['join'];
          if (sessionId != null && sessionId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => SessionPreviewScreen(sessionId: sessionId),
            );
          }
        }

        // Default routes
        switch (uri.path) {
          case '/':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/create-session':
            return MaterialPageRoute(builder: (context) => const CreateSessionWizard());
          case '/session-created':
            return MaterialPageRoute(builder: (context) => const SessionCreatedScreen());
          case '/join-session':
            return MaterialPageRoute(
              builder: (context) => const JoinSessionScreen(),
              settings: settings,
            );
          case '/swipe':
            return MaterialPageRoute(builder: (context) => const SwipeScreen());
          case '/matches':
            return MaterialPageRoute(builder: (context) => const MatchesScreen());
          default:
            return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
      },
    );
  }
}

