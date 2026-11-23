import 'dart:collection';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/artwork_palette.dart';
import 'playback_controller.dart';

/// Strategy signature for extracting an [ArtworkPalette] from an image URL.
typedef PaletteExtractionStrategy = Future<ArtworkPalette> Function(
  String imageUrl, {
  required Brightness brightness,
  required AudifiThemeColors colors,
});

/// Default palette extraction strategy using Flutter's built-in Material 3
/// [ColorScheme.fromImageProvider], scaled down to 112x112 for high performance.
Future<ArtworkPalette> defaultPaletteExtractionStrategy(
  String imageUrl, {
  required Brightness brightness,
  required AudifiThemeColors colors,
}) async {
  final imageProvider = ResizeImage(
    NetworkImage(imageUrl),
    width: 112,
    height: 112,
  );

  final colorScheme = await ColorScheme.fromImageProvider(
    provider: imageProvider,
    brightness: brightness,
  );

  return ArtworkPalette(
    dominant: colorScheme.primary,
    secondary: colorScheme.secondary,
    accent: colorScheme.tertiary,
    background: colorScheme.surface,
    isFallback: false,
  );
}

/// Provider overriding the extraction strategy (useful for unit tests without network).
final paletteExtractionStrategyProvider = Provider<PaletteExtractionStrategy>(
  (ref) => defaultPaletteExtractionStrategy,
);

/// State of the artwork palette extraction.
class ArtworkPaletteState {
  const ArtworkPaletteState({
    required this.palette,
    required this.currentArtworkUrl,
    this.isLoading = false,
  });

  final ArtworkPalette palette;
  final String? currentArtworkUrl;
  final bool isLoading;

  ArtworkPaletteState copyWith({
    ArtworkPalette? palette,
    String? currentArtworkUrl,
    bool? isLoading,
  }) {
    return ArtworkPaletteState(
      palette: palette ?? this.palette,
      currentArtworkUrl: currentArtworkUrl ?? this.currentArtworkUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller managing dynamic artwork palette extraction, caching, and fallback states.
class ArtworkPaletteController extends Notifier<ArtworkPaletteState> {
  static const int _maxCacheEntries = 30;

  /// Bounded in-memory LRU cache storing palettes by artwork URL.
  final LinkedHashMap<String, ArtworkPalette> _cache =
      LinkedHashMap<String, ArtworkPalette>();

  int _currentRequestId = 0;

  @override
  ArtworkPaletteState build() {
    final dynamicColorsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.dynamicColors),
    );
    // Watch current track's artwork URL
    final artworkUrl = ref.watch(
      playbackControllerProvider.select(
        (s) => s.currentTrack?.artwork?.primaryUrl,
      ),
    );
    final themeMode = ref.watch(themeModeProvider);
    final isOled = ref.watch(oledModeProvider);

    final brightness = _resolveBrightness(themeMode);
    final colors = isOled && brightness == Brightness.dark
        ? AudifiThemeColors.oled
        : (brightness == Brightness.dark
              ? AudifiThemeColors.dark
              : AudifiThemeColors.light);

    final fallback = ArtworkPalette.fallback(
      brightness: brightness,
      colors: colors,
    );

    if (!dynamicColorsEnabled) {
      return ArtworkPaletteState(
        palette: fallback,
        currentArtworkUrl: artworkUrl,
        isLoading: false,
      );
    }

    // Initial state with fallback palette
    final initialState = ArtworkPaletteState(
      palette: _cache[artworkUrl] ?? fallback,
      currentArtworkUrl: artworkUrl,
      isLoading: false,
    );

    if (artworkUrl != null &&
        artworkUrl.isNotEmpty &&
        !_cache.containsKey(artworkUrl)) {
      Future.microtask(() => _extractPalette(artworkUrl, brightness, colors));
    }

    return initialState;
  }

  /// Extracts the palette asynchronously with race condition protection and bounded caching.
  Future<void> _extractPalette(
    String url,
    Brightness brightness,
    AudifiThemeColors colors,
  ) async {
    final requestId = ++_currentRequestId;

    // Check bounded cache first
    if (_cache.containsKey(url)) {
      final cached = _cache.remove(url)!;
      _cache[url] = cached; // Move to most recently used
      if (requestId == _currentRequestId) {
        state = state.copyWith(
          palette: cached,
          currentArtworkUrl: url,
          isLoading: false,
        );
      }
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final strategy = ref.read(paletteExtractionStrategyProvider);
      final palette = await strategy(
        url,
        brightness: brightness,
        colors: colors,
      );

      // Race condition check: discard if a newer track extraction was requested
      if (requestId != _currentRequestId) {
        return;
      }

      // Store in bounded LRU cache
      if (_cache.length >= _maxCacheEntries) {
        _cache.remove(_cache.keys.first); // Evict oldest
      }
      _cache[url] = palette;

      state = state.copyWith(
        palette: palette,
        currentArtworkUrl: url,
        isLoading: false,
      );
    } catch (e, st) {
      AppLogger.warning(
        'Palette extraction failed for $url; using theme fallback',
        tag: 'ArtworkPalette',
        error: e,
        stackTrace: st,
      );

      // Gracefully fall back without disrupting the user
      if (requestId == _currentRequestId) {
        final fallback = ArtworkPalette.fallback(
          brightness: brightness,
          colors: colors,
        );
        state = state.copyWith(
          palette: fallback,
          currentArtworkUrl: url,
          isLoading: false,
        );
      }
    }
  }

  Brightness _resolveBrightness(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness;
    }
  }

  /// Clears the palette cache (for testing or memory management).
  void clearCache() {
    _cache.clear();
  }
}

/// Provider for accessing the active [ArtworkPaletteState].
final artworkPaletteProvider =
    NotifierProvider<ArtworkPaletteController, ArtworkPaletteState>(
      ArtworkPaletteController.new,
    );
