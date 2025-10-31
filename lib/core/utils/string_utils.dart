/// String utility functions for text processing
library;

/// Checks if a string contains non-Latin script characters
///
/// Detects:
/// - Japanese (Hiragana, Katakana, Kanji)
/// - Chinese (Hanzi)
/// - Korean (Hangul)
/// - Arabic
/// - Cyrillic
/// - Thai
/// - Hebrew
/// - And other non-Latin Unicode blocks
///
/// Returns true if ANY non-Latin characters are found
/// Returns false if string is empty or contains only Latin characters
bool containsNonLatinScript(String text) {
  if (text.isEmpty) return false;

  for (int i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);

    // Japanese Hiragana (U+3040 to U+309F)
    if (code >= 0x3040 && code <= 0x309F) return true;

    // Japanese Katakana (U+30A0 to U+30FF)
    if (code >= 0x30A0 && code <= 0x30FF) return true;

    // CJK Unified Ideographs (Chinese/Japanese Kanji) (U+4E00 to U+9FFF)
    if (code >= 0x4E00 && code <= 0x9FFF) return true;

    // Korean Hangul Syllables (U+AC00 to U+D7AF)
    if (code >= 0xAC00 && code <= 0xD7AF) return true;

    // Arabic (U+0600 to U+06FF)
    if (code >= 0x0600 && code <= 0x06FF) return true;

    // Cyrillic (U+0400 to U+04FF)
    if (code >= 0x0400 && code <= 0x04FF) return true;

    // Thai (U+0E00 to U+0E7F)
    if (code >= 0x0E00 && code <= 0x0E7F) return true;

    // Hebrew (U+0590 to U+05FF)
    if (code >= 0x0590 && code <= 0x05FF) return true;

    // Devanagari (Hindi) (U+0900 to U+097F)
    if (code >= 0x0900 && code <= 0x097F) return true;

    // Bengali (U+0980 to U+09FF)
    if (code >= 0x0980 && code <= 0x09FF) return true;
  }

  return false;
}
