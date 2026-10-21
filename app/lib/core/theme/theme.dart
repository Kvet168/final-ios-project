import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WAYFARER design tokens. The palette is taken from the places the app is about:
/// jungle forest, Angkor sandstone paper, temple gold and Mekong-dusk terracotta.
class Tokens {
  static const ivory = Color(0xFFFAF5EA);
  static const paper = Color(0xFFFFFFFF);
  static const sand = Color(0xFFF2EADA);
  static const sandDeep = Color(0xFFE7DBC3);
  static const ink = Color(0xFF17211D);
  static const inkSoft = Color(0xFF3A4540);
  static const inkMuted = Color(0xFF6B746E);
  static const border = Color(0xFFE8DFCB);
  static const forest = Color(0xFF1F4A3F);
  static const forestDeep = Color(0xFF14342C);
  static const jade = Color(0xFF3E8F7A);
  static const mint = Color(0xFFD8E8DE);
  static const terracotta = Color(0xFFC4633A);
  static const gold = Color(0xFFE2A64C);
  static const amber = Color(0xFFE2A64C);
  static const lotus = Color(0xFFD9788A);
  static const danger = Color(0xFFB3382C);
  static const success = Color(0xFF2E7D4F);

  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s5 = 24.0, s6 = 32.0, s7 = 48.0;
  static const radius = 20.0;
  static const radiusLg = 28.0;
  static const maxContent = 720.0;

  static const dusk = LinearGradient(colors: [Color(0xFF1F4A3F), Color(0xFF14342C)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const sunrise = LinearGradient(colors: [Color(0xFFE2A64C), Color(0xFFC4633A)], begin: Alignment.topLeft, end: Alignment.bottomRight);

  static List<BoxShadow> softShadow([double a = 0.10]) => [
        BoxShadow(color: forestDeep.withValues(alpha: a), blurRadius: 28, offset: const Offset(0, 12)),
        BoxShadow(color: forestDeep.withValues(alpha: a * 0.5), blurRadius: 6, offset: const Offset(0, 2)),
      ];
}

/// Typography. Fraunces (variable serif) carries the editorial voice; Plus Jakarta Sans does the work.
class Type {
  static const _display = 'Fraunces';
  static const _body = 'PlusJakartaSans';

  static TextStyle display(double size, {FontWeight weight = FontWeight.w600, Color color = Tokens.ink, double? height, double? spacing, bool italic = false}) => TextStyle(
        fontFamily: _display,
        fontSize: size,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color,
        height: height ?? 1.08,
        letterSpacing: spacing ?? -size * 0.018,
        fontVariations: [FontVariation('wght', weight.value.toDouble()), FontVariation('opsz', size.clamp(9, 144).toDouble()), const FontVariation('SOFT', 60)],
      );

  static TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color color = Tokens.ink, double? height, double? spacing}) => TextStyle(
        fontFamily: _body,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.4,
        letterSpacing: spacing,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );

  static TextStyle label(double size, {Color color = Tokens.inkMuted, FontWeight weight = FontWeight.w700}) =>
      body(size, weight: weight, color: color, spacing: 1.2, height: 1.2);
}

class WayfarerTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: Tokens.forest, brightness: Brightness.light).copyWith(
      primary: Tokens.forest,
      onPrimary: Colors.white,
      secondary: Tokens.terracotta,
      onSecondary: Colors.white,
      surface: Tokens.paper,
      onSurface: Tokens.ink,
      error: Tokens.danger,
      outline: Tokens.border,
      surfaceContainerHighest: Tokens.sand,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: Tokens.ivory, fontFamily: 'PlusJakartaSans');
    final text = base.textTheme.copyWith(
      displayLarge: Type.display(48),
      displayMedium: Type.display(40),
      displaySmall: Type.display(34),
      headlineLarge: Type.display(30),
      headlineMedium: Type.display(26),
      headlineSmall: Type.display(22),
      titleLarge: Type.body(19, weight: FontWeight.w700),
      titleMedium: Type.body(16, weight: FontWeight.w700),
      titleSmall: Type.body(14, weight: FontWeight.w700),
      bodyLarge: Type.body(16, height: 1.5),
      bodyMedium: Type.body(14, height: 1.5),
      bodySmall: Type.body(12.5, color: Tokens.inkMuted),
      labelLarge: Type.body(14, weight: FontWeight.w700),
      labelMedium: Type.body(12, weight: FontWeight.w600),
      labelSmall: Type.body(11, weight: FontWeight.w600),
    );
    OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return base.copyWith(
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Tokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: Type.display(22),
      ),
      cardTheme: CardThemeData(
        color: Tokens.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radius), side: const BorderSide(color: Tokens.border)),
      ),
      dividerTheme: const DividerThemeData(color: Tokens.border, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tokens.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: Type.body(15, color: Tokens.inkMuted),
        labelStyle: Type.body(15, color: Tokens.inkMuted),
        border: ob(Tokens.border),
        enabledBorder: ob(Tokens.border),
        focusedBorder: ob(Tokens.forest, 1.6),
        errorBorder: ob(Tokens.danger),
        focusedErrorBorder: ob(Tokens.danger, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          backgroundColor: Tokens.forest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: Type.body(15, weight: FontWeight.w700, spacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          foregroundColor: Tokens.ink,
          side: const BorderSide(color: Tokens.border, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: Type.body(15, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Tokens.forest, textStyle: Type.body(14, weight: FontWeight.w700))),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Tokens.paper,
        selectedColor: Tokens.forest,
        side: const BorderSide(color: Tokens.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: Type.body(13, weight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Tokens.ivory,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radiusLg))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Tokens.ivory,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusLg)),
        titleTextStyle: Type.display(22),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Tokens.forestDeep,
        contentTextStyle: Type.body(14, color: Colors.white, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
