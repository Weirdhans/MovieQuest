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
│   └── utils/              # Dev logging, URL generation, string utilities
├── features/               # Feature modules
│   ├── home/              # Home screen (create/join session)
│   ├── session/           # Session creation, joining, and preview screen
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
- `getSession()` - Get session by ID
- `getSessionPreview()` - Get session data + host info for preview screen
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

### Smart Movie Title Display

Movies are displayed with intelligent title fallback to ensure readability for Dutch/English users:

**Display Logic** ([Movie.displayTitle](lib/core/models/movie.dart)):
1. Check if `title` contains non-Latin characters (Japanese, Chinese, Korean, Arabic, etc.)
2. If yes, try using `originalTitle` as fallback if it's readable (Latin script)
3. If both have non-Latin characters, use `title` as last resort

**Examples:**
- `title: "劇場版「鬼滅の刃」"`, `originalTitle: "Demon Slayer: Mugen Train"` → Shows "Demon Slayer: Mugen Train"
- `title: "Squid Game"`, `originalTitle: "오징어 게임"` → Shows "Squid Game"

**Implementation:**
- [string_utils.dart](lib/core/utils/string_utils.dart): `containsNonLatinScript()` detects 10+ writing systems
- [movie.dart](lib/core/models/movie.dart): `displayTitle` getter with automatic fallback
- All movie titles across the app use `movie.displayTitle` instead of `movie.title`

**Benefits:**
- Zero extra API calls (uses existing TMDB data)
- Automatic detection, no manual configuration
- Preserves full movie library (anime, K-dramas remain available)

### User ID Management

Each device gets a persistent UUID stored in SharedPreferences via `UtilsService`. This identifies users without requiring authentication.

### Deep Linking & Route Handling

The app supports deep linking for joining sessions via shareable URLs and QR codes.

**URL Formats:**
- **Modern (primary)**: `/join/SESSION_ID` - Clean, shareable URLs
- **Legacy (backward compatible)**: `/?join=SESSION_ID` - Redirects to session preview

**Flow:**
1. User scans QR code or opens join link
2. [SessionPreviewScreen](lib/features/session/session_preview_screen.dart) shows session details:
   - Host name, member count, active filters (streaming providers, genres, age rating)
   - Optional username input
   - One-click join button
3. Error handling for invalid/expired sessions
4. After joining → Navigate to swipe screen

**Implementation Details:**
- **URL Strategy**: Uses `usePathUrlStrategy()` on web for clean URLs without `#` fragments
- **Route Parsing**: [main.dart](lib/main.dart) `onGenerateRoute` handles both URL formats
- **URL Generation**: [url_utils.dart](lib/core/utils/url_utils.dart) generates join URLs with automatic environment detection
- **Preview Data**: [SupabaseService.getSessionPreview()](lib/shared/services/supabase_service.dart) fetches session + host info

See [main.dart](lib/main.dart) `onGenerateRoute` for complete routing logic.

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

## Deployment

### Vercel Web Deployment

The Flutter web version is automatically deployed to Vercel via `vercel.json`:

- **Build Command**: `node generate_env.js && touch .env && flutter/bin/flutter build web --release`
  - `generate_env.js`: Node.js script that reads Vercel environment variables and generates `lib/core/config/env_config_web.dart` with compile-time constants
  - Flutter web requires env vars at compile-time (unlike mobile which can read .env at runtime)
- **Output**: `build/web` directory
- **Environment Variables**: Set in Vercel dashboard (SUPABASE_URL, SUPABASE_ANON_KEY, TMDB_API_KEY, TMDB_BASE_URL, TMDB_IMAGE_BASE)
- **Auto-Deploy**: Triggers on push to `main` branch
- **Vercel Analytics**: Integrated via script injection in [web/index.html](web/index.html) - automatically tracks page views and user interactions

**Platform-Specific Environment Config**:
- **Web** ([env_config_web.dart](lib/core/config/env_config_web.dart)): Compile-time constants generated during Vercel build
- **Mobile** ([env_config_mobile.dart](lib/core/config/env_config_mobile.dart)): Runtime .env file loaded via `flutter_dotenv`
- **Main API** ([env_config.dart](lib/core/config/env_config.dart)): Uses conditional imports to automatically select the correct implementation

The same Flutter/Dart codebase supports multiple platforms:
- **Web**: Deployed to Vercel
- **Mobile**: Android/iOS apps
- **Desktop**: Windows/macOS (configured but not deployed)

All platforms share the same Supabase backend and Riverpod state management.

## Project Management

### Notion Database

The project uses Notion for task and feature tracking:

- **Database ID**: `52e21d40-3478-4b25-82e4-3a5cf9d9bce1`
- **Database Name**: "Movie Quest - Ideas & Tasks"
- **Notion URL**: https://notion.so/52e21d4034784b2582e43a5cf9d9bce1
- **Access**: Via Notion MCP server (configured in global `.claude.json`)

### Database Schema

**Properties:**

1. **Name** (Title): Task/idea description
2. **Type** (Select):
   - `Idea` - Initial concepts and suggestions
   - `Feature` - Confirmed features to implement
   - `Bug` - Issues to fix
   - `Improvement` - Enhancements to existing functionality
   - `Research` - Investigation tasks

3. **Priority** (Select):
   - `Urgent` (Red) - Critical, needs immediate attention
   - `High` (Orange) - Important, high priority
   - `Medium` (Yellow) - Standard priority
   - `Low` (Green) - Nice to have

4. **Labels** (Multi-select):
   - `UI`, `UX`, `Backend`, `API Integration`
   - `Performance`, `Design`, `TMDB`, `Streaming`

5. **Created** (Created Time): Auto-tracked creation timestamp

### Current High Priority Features

These features are currently marked as High Priority:

1. **Sorteer functie op rating, naam, etc** (`UI`, `UX`, `TMDB`)
   - Enable sorting movies by rating, name, release date

2. **Streaming dienst info in swipe cards en matches** (`UI`, `UX`, `API Integration`, `Streaming`)
   - Display which streaming service offers each movie

3. **Filter voor minimale film rating** (`UX`, `TMDB`, `Backend`)
   - Allow filtering movies by minimum TMDB rating (e.g., min 8.0)

4. **Filter voor jaargetal** (`UX`, `TMDB`, `Backend`)
   - Filter movies by release year range

5. **Sorteer functie voor jaargetal** (`UI`, `UX`, `TMDB`)
   - Sort movies by release year

### Workflow Guidelines

**For Claude Code:**
- Check Notion database for context and priority before implementing features
- Update task status and add implementation notes in Notion via MCP
- Link related tasks when dependencies exist
- Use Labels to understand which parts of codebase are affected

**Adding New Ideas:**
- Add to Notion database with Type: "Idea"
- Assign appropriate Labels based on affected areas
- Priority starts at "Medium" unless urgent
- Convert to "Feature" type once approved for implementation

**From User Testing:**
- UX insights from user testing should be added as separate tasks
- Reference the source (e.g., "From family testing session 2025-10-26")
- Tag with `UX` label at minimum

### Notion MCP Integration

Claude Code can interact with this database via the Notion MCP server:
- Query current tasks and priorities
- Read task details and descriptions
- Update task status when implementing features
- Create new tasks based on code analysis or user requests

**Example queries:**
- "What are the current high priority features in Notion?"
- "Add a new idea to track [description]"
- "Show me all UX-related tasks"
- "Update task X to mark it as completed"

## Common Gotchas

1. **Riverpod Code Generation**: Always run `dart run build_runner build` after adding/modifying `@riverpod` annotated code
2. **Environment Variables**:
   - **Mobile**: App will throw exception on startup if `.env` is missing or invalid
   - **Web**: Environment variables are baked in at build time via `generate_env.js` script
3. **Supabase RPC Functions**: Backend must have all required RPC functions deployed for full functionality
4. **TMDB Region**: Hardcoded to Netherlands (`NL`) for certifications and streaming providers
5. **Member Count**: The app tries to use `increment_total_members` RPC but has a manual fallback if not available
6. **Vercel Deployment**:
   - Changes to fonts/assets require new Vercel build (auto-triggered on git push)
   - Environment variables must be set in Vercel dashboard (not in git)
   - The `env_config_web.dart` file is gitignored and generated during each build
