// lib/theme.dart
// App Theme

import 'package:flutter/material.dart'; // get access to all Flutter’s built-in color, theme, and widget classes

/// STEP 1: Pick colors:
const Color _white       = Color(0xFFFFFFFF);
const Color _black       = Color(0xFF000000);
const Color _appleBlue   = Color(0xFF007AFF); // iOS system blue

/// STEP 2: Create a “base” ColorScheme from your seed, then override surface/onSurface.
///   - `fromSeed` gives you primary, secondary, tertiary, etc. derived from Apple‐blue,
///     but `surface` may be a light gray by default, so we force it to pure white.
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: _appleBlue,
  brightness: Brightness.light,
).copyWith(
  surface: _white,
  onSurface: _black,
  // (You could also override error / outline / etc. here if desired)
);

/// STEP 3: Build ThemeData for light mode using that “surface‐overridden” scheme:
final ThemeData lightThemeData = ThemeData(
  useMaterial3: true,

  // 1) Because `surface` is now _white_, set scaffold’s background to `surface`.
  //    Never read or write `background`—M3 will quietly ignore it.
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: lightColorScheme.surface,

  // 2) Force all default “body” text to be black:
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: _black),
    bodyMedium: TextStyle(color: _black),
    headlineMedium: TextStyle(color: _black),
  ),

  // 3) Force every ElevatedButton (primary CTA) to use Apple‐blue (#007AFF) + white text:
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          WidgetStateProperty.all(lightColorScheme.primary), // #007AFF
      foregroundColor:
          WidgetStateProperty.all(lightColorScheme.onPrimary), // usually #FFFFFF
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  ),

  // 4) If you use OutlinedButtons, make them Apple‐blue border + blue text:
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      side: WidgetStateProperty.all(
        BorderSide(color: lightColorScheme.primary),
      ),
      foregroundColor:
          WidgetStateProperty.all(lightColorScheme.primary),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  ),
);

/// STEP 4: For dark mode, we can either hand‐craft another scheme (pure black‐white‐blue),
/// or simply let M3 generate one and then override the same way. Here, we generate via seed:
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: _appleBlue,
  brightness: Brightness.dark,
).copyWith(
  surface: const Color(0xFF1C1C1E), // iOS‐style “pure dark” background
  onSurface: _white,                // white text on that dark background
);

final ThemeData darkThemeData = ThemeData(
  useMaterial3: true,

  // 1) In dark mode, set scaffold background to `surface` (which is now a deep near‐black).
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: darkColorScheme.surface,

  // 2) Force default text in dark to be white:
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.white),
  ),

  // 3) ElevatedButtons in dark mode use the same M3‐generated “primary” (a bluish shade),
  //    with white text on top for contrast:
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          WidgetStateProperty.all(darkColorScheme.primary),
      foregroundColor:
          WidgetStateProperty.all(darkColorScheme.onPrimary),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  ),

  // 4) OutlinedButtons in dark:
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      side: WidgetStateProperty.all(
        BorderSide(color: darkColorScheme.primary),
      ),
      foregroundColor:
          WidgetStateProperty.all(darkColorScheme.primary),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  ),
);
