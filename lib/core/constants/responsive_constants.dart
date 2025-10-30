/// Constants for responsive screen width constraints
///
/// These values ensure the app looks good on large screens by preventing
/// content from stretching too wide. Different screen types have different
/// optimal widths based on their content.
class ResponsiveConstants {
  ResponsiveConstants._(); // Private constructor to prevent instantiation

  /// Maximum width for home screen (compact, centered welcome screen)
  static const double homeScreenMaxWidth = 500;

  /// Maximum width for swipe screen (movie cards need visual space)
  static const double swipeScreenMaxWidth = 700;

  /// Maximum width for form screens (create/join session forms)
  /// Optimal line length for form inputs and readability
  static const double formScreenMaxWidth = 600;

  /// Maximum width for matches grid screen
  /// Allows 2-3 columns depending on actual screen width
  static const double matchesScreenMaxWidth = 900;

  /// Breakpoint for switching between mobile and desktop layouts
  /// Used for responsive grids and multi-column layouts
  static const double mobileBreakpoint = 600;
}
