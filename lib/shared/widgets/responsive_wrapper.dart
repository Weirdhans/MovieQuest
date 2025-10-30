import 'package:flutter/material.dart';

/// A wrapper widget that constrains content width on large screens
///
/// This widget centers its child and applies a maximum width constraint
/// to prevent content from stretching too wide on desktop/tablet screens.
/// The content remains full-width on mobile devices but gets centered
/// with padding on larger screens.
///
/// Example usage:
/// ```dart
/// ResponsiveWrapper(
///   maxWidth: ResponsiveConstants.homeScreenMaxWidth,
///   child: YourScreenContent(),
/// )
/// ```
class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({
    super.key,
    required this.child,
    required this.maxWidth,
  });

  /// The child widget to wrap
  final Widget child;

  /// Maximum width constraint for the content
  /// Content will be centered if the screen is wider than this value
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
