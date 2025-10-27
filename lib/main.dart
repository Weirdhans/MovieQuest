import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'shared/services/supabase_service.dart';
import 'features/home/home_screen.dart';
import 'features/session/create_session_screen.dart';
import 'features/session/join_session_screen.dart';
import 'features/swipe/swipe_screen.dart';
import 'features/matches/matches_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        // Check if this is a route with join parameter (e.g., "/?join=xxx")
        if (settings.name != null && settings.name!.contains('join=')) {
          // Extract session ID from route name
          final routeName = settings.name!;
          final joinIndex = routeName.indexOf('join=');
          if (joinIndex != -1) {
            final afterJoin = routeName.substring(joinIndex + 5);
            final endIndex = afterJoin.indexOf('&');
            final sessionId = endIndex == -1 ? afterJoin : afterJoin.substring(0, endIndex);

            // Navigate directly to join session screen with the ID
            return MaterialPageRoute(
              builder: (context) => const JoinSessionScreen(),
              settings: RouteSettings(arguments: sessionId),
            );
          }
        }

        // Default routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/create-session':
            return MaterialPageRoute(builder: (context) => const CreateSessionScreen());
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

