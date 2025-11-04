/// Web implementation for browser history management.
/// This file uses package:web to control browser back button behavior.
library;

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Callback type for handling browser back button events
typedef BrowserBackCallback = void Function();

/// Browser history manager (web implementation using package:web)
class BrowserHistoryManager {
  BrowserHistoryManager._();

  /// Singleton instance
  static final BrowserHistoryManager instance = BrowserHistoryManager._();

  BrowserBackCallback? _onBrowserBack;

  /// Initialize browser history listener
  ///
  /// Registers a listener for browser back/forward button events.
  /// The [onBrowserBack] callback will be called when user presses browser back.
  void initialize(BrowserBackCallback onBrowserBack) {
    _onBrowserBack = onBrowserBack;

    // Listen to browser popstate events (back/forward buttons)
    web.window.addEventListener('popstate', _handlePopState.toJS);
  }

  /// Handle popstate event
  void _handlePopState(web.Event event) {
    _onBrowserBack?.call();
  }

  /// Update browser history state without adding new entry
  ///
  /// Uses replaceState() to update the browser URL/title without creating
  /// a new history entry. This prevents accumulating multiple entries during
  /// wizard navigation.
  ///
  /// [title] - The title/state identifier for the current step
  void replaceState(String title) {
    // Use Future.delayed to avoid timing issues with browser history API
    Future.delayed(Duration.zero, () {
      final window = web.window;
      window.history.replaceState(
        {'step': title}.jsify(),
        title,
        window.location.href,
      );
    });
  }

  /// Clean up listeners
  ///
  /// Removes the popstate event listener to prevent memory leaks.
  void dispose() {
    web.window.removeEventListener('popstate', _handlePopState.toJS);
    _onBrowserBack = null;
  }
}
