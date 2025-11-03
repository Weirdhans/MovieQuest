/// Public API for browser history management with platform-specific implementations.
///
/// Uses conditional imports to provide web-specific functionality while
/// maintaining compatibility with mobile platforms.
library;

// Conditional export: use web implementation on web, stub on other platforms
export 'browser_history_stub.dart'
    if (dart.library.js_interop) 'browser_history_web.dart';
