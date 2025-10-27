/// App Configuration Constants
class AppConstants {
  // API Settings
  static const int moviesPerPage = 20;
  static const int prefetchThreshold = 5;
  static const int minVoteCount = 50;
  static const String defaultSort = 'popularity.desc';
  static const String region = 'NL';
  static const String language = 'nl-NL';

  // Swipe Thresholds
  static const int swipeThreshold = 50;
  static const double maxSwipeAngle = 30;
  static const int swipeAnimationDuration = 300;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 8.0;
}

/// Streaming Provider Model
class StreamingProvider {
  const StreamingProvider({
    required this.id,
    required this.name,
    this.hasExtraCosts = false,
  });

  final String id;
  final String name;
  final bool hasExtraCosts;
}

/// Categorized Streaming Providers (same as web version)
class StreamingProviders {
  static const subscription = [
    StreamingProvider(id: '8', name: 'Netflix'),
    StreamingProvider(id: '71', name: 'Videoland'),
    StreamingProvider(id: '119', name: 'Prime Video', hasExtraCosts: true),
    StreamingProvider(id: '337', name: 'Disney+'),
    StreamingProvider(id: '380', name: 'HBO Max'),
    StreamingProvider(id: '350', name: 'Apple TV+', hasExtraCosts: true),
  ];

  static const payPerView = [
    StreamingProvider(id: '536', name: 'Pathé Thuis'),
    StreamingProvider(id: '12', name: 'KPN Film'),
  ];

  static const free = [
    StreamingProvider(id: '531', name: 'NPO Start Plus'),
  ];

  static List<StreamingProvider> get all => [
        ...subscription,
        ...payPerView,
        ...free,
      ];

  static String getNameById(String id) {
    try {
      return all.firstWhere((p) => p.id == id).name;
    } catch (e) {
      return 'Onbekend';
    }
  }
}

/// Genre Model
class Genre {
  const Genre({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

/// Film Genres (TMDB IDs - same as web version)
class Genres {
  static const list = [
    Genre(id: '28', name: 'Actie'),
    Genre(id: '12', name: 'Avontuur'),
    Genre(id: '16', name: 'Animatie'),
    Genre(id: '35', name: 'Komedie'),
    Genre(id: '80', name: 'Misdaad'),
    Genre(id: '99', name: 'Documentaire'),
    Genre(id: '18', name: 'Drama'),
    Genre(id: '10751', name: 'Familie'),
    Genre(id: '14', name: 'Fantasy'),
    Genre(id: '36', name: 'Geschiedenis'),
    Genre(id: '27', name: 'Horror'),
    Genre(id: '10402', name: 'Muziek'),
    Genre(id: '9648', name: 'Mysterie'),
    Genre(id: '10749', name: 'Romantiek'),
    Genre(id: '878', name: 'Sciencefiction'),
    Genre(id: '53', name: 'Thriller'),
    Genre(id: '10752', name: 'Oorlog'),
    Genre(id: '37', name: 'Western'),
  ];

  static String getNameById(String id) {
    try {
      return list.firstWhere((g) => g.id == id).name;
    } catch (e) {
      return 'Onbekend';
    }
  }
}

/// Certification Model (Kijkwijzer - Netherlands)
class Certification {
  const Certification({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

/// Age Certifications (Netherlands)
class Certifications {
  static const list = [
    Certification(value: 'AL', label: 'Alle leeftijden'),
    Certification(value: '6', label: '6 jaar'),
    Certification(value: '9', label: '9 jaar'),
    Certification(value: '12', label: '12 jaar'),
    Certification(value: '16', label: '16 jaar'),
  ];
}

/// Genre Match Mode - determines how multiple genres are combined
enum GenreMatchMode {
  /// Films with at least ONE of the selected genres (OR logic) - More results
  any('any', 'Films met minimaal één van deze genres', 'Aanbevolen voor meer resultaten'),

  /// Films with ALL selected genres (AND logic) - Fewer, more specific results
  all('all', 'Films met ALLE geselecteerde genres', 'Voor specifieke zoekopdrachten');

  const GenreMatchMode(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;
}
