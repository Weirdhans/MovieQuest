import 'dart:math';

/// Random Name Generator - Generates fun movie-themed names for anonymous users
class RandomNameGenerator {
  RandomNameGenerator._();

  static final Random _random = Random();

  // Movie-themed prefixes
  static const List<String> _prefixes = [
    'Popcorn',
    'Cinema',
    'Movie',
    'Film',
    'Trailer',
    'Blockbuster',
    'Oscar',
    'Premiere',
    'Hollywood',
    'Netflix',
    'Bioscoop',
    'Ticket',
    'Screen',
    'Reel',
    'Scene',
  ];

  // Fun suffixes
  static const List<String> _suffixes = [
    'Piraat',
    'Meester',
    'Tovenaar',
    'Held',
    'Koning',
    'Koningin',
    'Ninja',
    'Kapitein',
    'Legende',
    'Expert',
    'Guru',
    'Fanaat',
    'Liefhebber',
    'Junkie',
    'Addict',
  ];

  /// Generate a random fun movie-themed name
  /// Example: "Popcorn Piraat", "Cinema Meester", "Film Held"
  static String generate() {
    final prefix = _prefixes[_random.nextInt(_prefixes.length)];
    final suffix = _suffixes[_random.nextInt(_suffixes.length)];
    return '$prefix $suffix';
  }

  /// Generate a random name with a seed (for deterministic generation)
  /// Useful for generating the same name from the same user ID
  static String generateWithSeed(String seed) {
    final seedInt = seed.hashCode.abs();
    final seededRandom = Random(seedInt);

    final prefix = _prefixes[seededRandom.nextInt(_prefixes.length)];
    final suffix = _suffixes[seededRandom.nextInt(_suffixes.length)];
    return '$prefix $suffix';
  }

  /// Get total possible combinations
  static int get totalCombinations => _prefixes.length * _suffixes.length;
}
