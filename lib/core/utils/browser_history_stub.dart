/// Stub implementation for browser history management.
/// This file is used on non-web platforms where dart:html is not available.

/// Callback type for handling browser back button events
typedef BrowserBackCallback = void Function();

/// Browser history manager (stub implementation)
class BrowserHistoryManager {
  /// Singleton instance
  static final BrowserHistoryManager instance = BrowserHistoryManager._();

  BrowserHistoryManager._();

  /// Initialize browser history listener (no-op on non-web platforms)
  void initialize(BrowserBackCallback onBrowserBack) {
    // No-op: Browser history only relevant on web
  }

  /// Update browser history state without adding new entry (no-op on non-web)
  void replaceState(String title) {
    // No-op: Browser history only relevant on web
  }

  /// Clean up listeners (no-op on non-web platforms)
  void dispose() {
    // No-op: Browser history only relevant on web
  }
}
