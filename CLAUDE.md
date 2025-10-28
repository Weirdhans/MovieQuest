# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MovieQuest** is a Flutter mobile app that allows groups of users to discover movies together through a Tinder-style swipe interface. Users create or join sessions, swipe on movies with shared filters (streaming providers, genres, age ratings), and when enough members like the same movie, it becomes a match.

This is a Flutter mobile port of a web application and shares the same Supabase backend.

## Core Technologies

- **Flutter SDK**: 3.35.7 / Dart 3.9.2
- **State Management**: Riverpod (with code generation via `riverpod_generator`)
- **Backend**: Supabase (authentication, database, realtime subscriptions)
- **Movie API**: The Movie Database (TMDB)
- **UI Components**:
  - `appinio_swiper` for swipe cards
  - `youtube_player_iframe` for trailers
  - `cached_network_image` for image caching

## Environment Setup

### Required Environment Variables

Create a `.env` file in the project root with:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
TMDB_API_KEY=your_tmdb_api_key
TMDB_BASE_URL=https://api.themoviedb.org/3
TMDB_IMAGE_BASE=https://image.tmdb.org/t/p/w500
```

The app validates these on startup via [env_config.dart](lib/core/config/env_config.dart).

## Development Commands

### Build and Run

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device_id>

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

### Code Generation

Riverpod uses code generation for providers. After modifying any files with `@riverpod` annotations:

```bash
# Generate code once
dart run build_runner build

# Watch for changes and rebuild automatically
dart run build_runner watch

# Clean and rebuild
dart run build_runner build --delete-conflicting-outputs
```

### Testing and Linting

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

## Architecture

### Directory Structure

```
lib/
├── core/                    # Shared core functionality
│   ├── config/             # Environment configuration
│   ├── constants/          # App-wide constants
│   ├── errors/             # Result<T> type, AppError, error handling
│   ├── interfaces/         # Service interfaces (ISupabaseService, ITmdbService, etc.)
│   ├── models/             # Core domain models (Session, Movie, Match, etc.)
│   ├── providers/          # Global Riverpod providers (providers.dart)
│   ├── services/           # BaseService abstract class
│   ├── theme/              # App theme (AppTheme.dark)
│   └── utils/              # Dev logging utilities
├── features/               # Feature modules
│   ├── home/              # Home screen (create/join session)
│   ├── session/           # Session creation and joining
│   ├── swipe/             # Movie swiping interface
│   └── matches/           # Matches and stats display
└── shared/                # Shared services and widgets
    ├── services/          # SupabaseService, TmdbService, UtilsService
    └── widgets/           # Reusable UI components
```

### Error Handling Pattern

The codebase uses a **Result<T> type** instead of throwing exceptions (inspired by Rust/Kotlin):

```dart
Future<Result<Session>> getSession(String id) async {
  return executeWithErrorHandling(
    () async {
      final response = await supabase.from('sessions').select().eq('id', id).single();
      return response;
    },
    'getSession',
    metadata: {'sessionId': id},
  );
}

// Usage:
final result = await supabaseService.getSession(sessionId);
result.when(
  success: (session) => print('Got session: ${session['id']}'),
  error: (error) => print('Error: ${error.message}'),
);
```

All service methods return `Result<T>` and use `BaseService.executeWithErrorHandling()` for consistent error handling.

### State Management with Riverpod

All providers are centralized in [core/providers/providers.dart](lib/core/providers/providers.dart):

**Service Providers (Singletons)**:
- `supabaseServiceProvider` - Supabase backend operations
- `tmdbServiceProvider` - TMDB API interactions
- `utilsServiceProvider` - UUID generation, user ID management

**State Providers**:
- `currentSessionIdProvider` - Currently active session ID
- `moviesProvider` - List of movies for current session
- `currentMovieIndexProvider` - Index of currently displayed movie
- `sessionMembersProvider` - Live member swipe counts (auto-refreshes)
- `sessionMatchesProvider` - Session matches
- `sessionStatsProvider` - Session statistics

**UI State**:
- `isLoadingProvider` - Global loading state
- `errorMessageProvider` - Global error messages
- `showMatchesDialogProvider` - Control match dialog visibility

### Supabase Integration

The [SupabaseService](lib/shared/services/supabase_service.dart) is a singleton that wraps all backend operations:

**Key Methods**:
- `createSession()` - Create new session with filters
- `joinSession()` - Join existing session, auto-increment member count
- `recordSwipe()` - Record like/dislike
- `checkAndCreateMatch()` - Check if enough votes exist for a match (uses `check_and_create_match_v2` RPC)
- `getMatches()` / `getPartialMatches()` - Fetch match data
- `getMemberSwipeCounts()` - Get swipe progress for all members (uses `get_member_swipe_counts` RPC)
- `subscribeToMatches()` / `subscribeToMembers()` - Realtime subscriptions

**Required Supabase RPC Functions**:
- `check_and_create_match_v2(p_session_id, p_movie_id, p_movie_data)` - Match checking with configurable vote threshold
- `get_partial_matches(p_session_id, p_min_votes)` - Movies with some but not all votes
- `get_member_swipe_counts(p_session_id)` - Member progress tracking with full member data (id, session_id, user_id, user_name, joined_at, swipe_count, likes_count, last_swipe_at, is_host)
- `get_session_stats(p_session_id)` - Session statistics
- `undo_last_swipe(p_session_id, p_user_id)` - Undo functionality
- `increment_total_members(session_id)` - Increment member count (optional, has fallback)

### TMDB Integration

The [TmdbService](lib/shared/services/tmdb_service.dart) handles movie data:

**Key Features**:
- **Seeded Shuffle**: Movies are shuffled using session ID as seed, ensuring all members see the same order
- **Caching**: API responses are cached to prevent duplicate calls
- **Discover API**: Fetches movies with filters (providers, genres, certifications)
- **Trailer Fetching**: Multi-language priority fallback (Dutch Official → English Official → Dutch Trailer → English Trailer → Teaser)
- **Prefetching**: Next page can be prefetched for smooth UX

**Methods**:
- `fetchMovies()` - Fetch with filters, returns seeded-shuffled results
- `fetchMovieTrailer()` - Get YouTube trailer key with language fallback
- `getMovieDetails()` - Fetch detailed movie info
- `searchMovies()` - Search by title
- `getPosterUrl()` - Generate TMDB image URL

### Constants and Configuration

[app_constants.dart](lib/core/constants/app_constants.dart) contains:
- Streaming provider IDs (Netflix: `8`, Disney+: `337`, etc.)
- Genre IDs (Action: `28`, Comedy: `35`, etc.)
- Dutch age certification codes (`AL`, `6`, `9`, `12`, `16`)
- TMDB API defaults (region: `NL`, language: `nl-NL`, min vote count: `100`)

## Key Implementation Details

### Seeded Random Shuffle

Movies are shuffled deterministically based on session ID so all users see the same order. This uses the **mulberry32** PRNG algorithm with Fisher-Yates shuffle. See `TmdbService._seededShuffle()`.

### Real-time Features

The app subscribes to Supabase realtime channels:
- **Matches**: Show instant match notifications when members align
- **Members**: Update member count and stats when someone joins or swipes

Subscriptions are managed in screen widgets and cleaned up on dispose. The swipe screen uses a dual approach: Supabase real-time subscription for automatic updates plus manual provider invalidation after each swipe for instant feedback.

### Members Display and Progress Tracking

The members button in the swipe screen shows:
- **Real-time Member Count**: Badge on the group icon updates instantly
- **Member Stats Card Layout**: Beautiful cards with gradients (gold/silver/bronze for top 3)
- **Progress Bars**: Visual progress relative to the most active member
- **Medal Rankings**: 🥇🥈🥉 emojis for top 3 members
- **Swipe & Likes Tracking**: Shows total swipes and number of right swipes (likes)
- **Host Badge**: Crown icon for session host

The RPC function `get_member_swipe_counts` returns comprehensive member data including `likes_count` (filtered by `swiped_right = true`) and calculates `is_host` dynamically.

### Fun Random Names

Users who don't provide a name get auto-generated movie-themed names:
- **Deterministic Generation**: Same user ID always produces the same name
- **Movie Themes**: Combinations like "Popcorn Piraat", "Cinema Meester", "Blockbuster Ninja"
- **225 Combinations**: 15 prefixes × 15 suffixes
- Implementation: `SessionMember.generateFunName()` uses hashCode-based selection

See [session_member.dart](lib/core/models/session_member.dart) for the name generation algorithm.

### User ID Management

Each device gets a persistent UUID stored in SharedPreferences via `UtilsService`. This identifies users without requiring authentication.

### Route Handling

The app supports deep linking for joining sessions via URL: `/?join=SESSION_ID`

See [main.dart](lib/main.dart) `onGenerateRoute` for route parsing.

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

## Common Gotchas

1. **Riverpod Code Generation**: Always run `dart run build_runner build` after adding/modifying `@riverpod` annotated code
2. **Environment Variables**: App will throw exception on startup if `.env` is missing or invalid
3. **Supabase RPC Functions**: Backend must have all required RPC functions deployed for full functionality
4. **TMDB Region**: Hardcoded to Netherlands (`NL`) for certifications and streaming providers
5. **Member Count**: The app tries to use `increment_total_members` RPC but has a manual fallback if not available
