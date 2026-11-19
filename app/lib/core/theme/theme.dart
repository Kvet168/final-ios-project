import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WAYFARER design tokens, following the Holafly look: warm coral for brand highlights and active states, mint green for
/// primary call-to-action buttons (always with dark text), charcoal text and soft grey-white surfaces.
/// Semantic colours (danger, warning, success) stay separate from the brand palette and are always paired with text or an icon.
class Tokens {
  // Brand
  /// Coral: fills, icons, selected states and large text.
  static const primary = Color(0xFFE6485C);

  /// Deeper coral for small coral text and pressed states (4.5:1 or better on white, page and tint backgrounds).
  static const primaryText = Color(0xFFC7364B);
  static const primaryPressed = Color(0xFFC7364B);

  /// Brand highlight colour (AI button, hero highlights). Same coral as [primary].
  static const accent = primary;
  static const accentDeep = Color(0xFFC7364B);
  static const onAccent = Color(0xFFFFFFFF);

  /// Lighter coral for small labels and highlighted words on charcoal bands and photo scrims.
  static const onDarkAccent = Color(0xFFFF8896);

  // Primary call-to-action: mint with dark text
  static const cta = Color(0xFF48EC86);
  static const ctaHover = Color(0xFF32A45E);
  static const ctaPressed = Color(0xFF206B43);
  static const onCta = Color(0xFF292B2E);

  // Surfaces and text
  static const pageBg = Color(0xFFF8F8FB);
  static const surface = Color(0xFFFFFFFF);

  /// Pale coral wash for icon circles, selected pills and quiet highlights.
  static const tint = Color(0xFFFFEEF0);

  /// Neutral fill for skeletons, placeholders and tracks.
  static const neutralTint = Color(0xFFEFF0F4);
  static const border = Color(0xFFE4E6EA);
  static const ink = Color(0xFF292B2E);
  static const inkSoft = Color(0xFF3E4044);
  static const inkMuted = Color(0xFF56575A);

  /// Deep red for the darkest brand surfaces (launch screen, onboarding backdrop).
  static const deepRed = Color(0xFF7F1F2E);

  /// Charcoal used for dark bands, overlays, scrims and shadows.
  static const charcoal = Color(0xFF292B2E);

  /// Disabled controls.
  static const disabledFill = Color(0xFFE4E6EA);
  static const disabledInk = Color(0xFF8A8D93);

  /// Secondary chart colour (Holafly link blue).
  static const sky = Color(0xFF327DF0);

  /// Rating stars.
  static const star = Color(0xFFF5A524);

  /// Soft amber wash for promos and notices (pair with [warning] text).
  static const promo = Color(0xFFFFEAC0);

  /// Secondary text on charcoal bands and scrims.
  static const onDarkMuted = Color(0xFFFFE8EB);

  // Semantic
  static const danger = Color(0xFF841C05);
  static const warning = Color(0xFF835617);
  static const success = Color(0xFF206B43);

  /// Favourite hearts.
  static const heart = primary;

  static const s1 = 4.0,
      s2 = 8.0,
      s3 = 12.0,
      s4 = 16.0,
      s5 = 24.0,
      s6 = 32.0,
      s7 = 48.0;
  static const radius = 20.0;
  static const radiusLg = 28.0;
  static const maxContent = 720.0;

  /// Brand-red header/hero fill behind photos and on header bands. White text keeps 4.5:1 or better on it.
  static const dusk = LinearGradient(
    colors: [Color(0xFFC7364B), Color(0xFFA82C40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const sunrise = LinearGradient(
    colors: [Color(0xFFE6485C), Color(0xFFC7364B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> softShadow([double a = 0.10]) => [
    BoxShadow(
      color: charcoal.withValues(alpha: a),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: charcoal.withValues(alpha: a * 0.5),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

/// Typography. English is set in Poppins (bundled, Regular to ExtraBold plus italics). Khmer is set in
/// MiSans Khmer by Xiaomi (bundled Regular and Semibold): weights up to 500 use Regular, heavier ones Semibold.
/// Every style names the fallback so Khmer text anywhere in the app uses MiSans Khmer.
enum Script { latin, khmer }

class Type {
  static const _en = 'Poppins';
  static const _km = ['MiSansKhmer'];

  /// Set from the app's locale. In Khmer, MiSans Khmer leads (so numbers and punctuation match the Khmer text) and
  /// lines get extra height for stacked vowels and subscript consonants.
  static Script script = Script.latin;
  static bool get _isKm => script == Script.khmer;
  static String get _family => _isKm ? 'MiSansKhmer' : _en;
  static List<String> get _fallback => _isKm ? const [_en] : _km;

  /// Nothing is set heavier than SemiBold: Bold and ExtraBold requests render as SemiBold.
  static FontWeight _w(FontWeight w) => w.value > 600 ? FontWeight.w600 : w;

  static double _h(double latin) => _isKm ? latin + 0.35 : latin;

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = Tokens.ink,
    double? height,
    double? spacing,
    bool italic = false,
  }) => TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: size,
    fontWeight: _w(weight),
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: _h(height ?? 1.1),
    letterSpacing: _isKm ? 0 : spacing ?? -size * 0.008,
    fontVariations: [
      FontVariation('wght', _w(weight).value.toDouble()),
      FontVariation('opsz', size.clamp(14, 32).toDouble()),
    ],
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = Tokens.ink,
    double? height,
    double? spacing,
  }) => TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: size,
    fontWeight: _w(weight),
    color: color,
    height: _h(height ?? 1.4),
    letterSpacing: _isKm ? 0 : spacing,
    fontVariations: [
      FontVariation('wght', _w(weight).value.toDouble()),
      FontVariation('opsz', size.clamp(14, 32).toDouble()),
    ],
  );

  static TextStyle label(
    double size, {
    Color color = Tokens.inkMuted,
    FontWeight weight = FontWeight.w700,
  }) => body(size, weight: weight, color: color, spacing: 1.2, height: 1.2);
}

class WayfarerTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Tokens.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: Tokens.primary,
          onPrimary: Colors.white,
          primaryContainer: Tokens.tint,
          onPrimaryContainer: Tokens.primaryText,
          secondary: Tokens.cta,
          onSecondary: Tokens.onCta,
          surface: Tokens.surface,
          onSurface: Tokens.ink,
          error: Tokens.danger,
          outline: Tokens.border,
          surfaceContainerHighest: Tokens.neutralTint,
          surfaceTint: Colors.transparent,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Tokens.pageBg,
      // The full-screen range picker paints its own background (and the strip under the last month) from the colour
      // scheme's container colour, which is pink here. Pin it to the page colour so no band shows under the calendar.
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Tokens.pageBg,
        rangePickerBackgroundColor: Tokens.pageBg,
        rangePickerSurfaceTintColor: Colors.transparent,
        rangeSelectionBackgroundColor: Tokens.tint,
      ),
      fontFamily: Type._family,
      fontFamilyFallback: Type._fallback,
    );
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
      labelSmall: Type.body(12, weight: FontWeight.w600),
    );
    OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: w),
    );
    return base.copyWith(
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Tokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: Type.display(22),
      ),
      cardTheme: CardThemeData(
        color: Tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radius),
          side: const BorderSide(color: Tokens.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Tokens.border,
        space: 1,
        thickness: 1,
      ),
      // Dropdown menus: a clean white card (not the tinted Material default), compact rows and a soft shadow.
      popupMenuTheme: PopupMenuThemeData(
        color: Tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: Tokens.charcoal.withValues(alpha: .22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Tokens.border),
        ),
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
        textStyle: Type.body(14.5, weight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        hintStyle: Type.body(16, color: Tokens.inkMuted),
        labelStyle: Type.body(16, color: Tokens.inkMuted),
        prefixIconColor: Tokens.inkMuted,
        suffixIconColor: Tokens.inkMuted,
        border: ob(Tokens.border),
        enabledBorder: ob(Tokens.border),
        disabledBorder: ob(Tokens.border),
        focusedBorder: ob(Tokens.primary, 1.6),
        errorBorder: ob(Tokens.danger),
        focusedErrorBorder: ob(Tokens.danger, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(48, 50),
              foregroundColor: Tokens.onCta,
              backgroundColor: Tokens.cta,
              disabledBackgroundColor: Tokens.disabledFill,
              disabledForegroundColor: Tokens.disabledInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: Type.body(14.5, weight: FontWeight.w700, spacing: 0.2),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.disabled)) {
                  return Tokens.disabledFill;
                }
                if (s.contains(WidgetState.pressed)) return Tokens.ctaPressed;
                if (s.contains(WidgetState.hovered)) return Tokens.ctaHover;
                return Tokens.cta;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.disabled)) return Tokens.disabledInk;
                return s.contains(WidgetState.pressed)
                    ? Colors.white
                    : Tokens.onCta;
              }),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size(48, 50),
              foregroundColor: Tokens.ink,
              disabledForegroundColor: Tokens.disabledInk,
              side: const BorderSide(color: Tokens.border, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: Type.body(15, weight: FontWeight.w700),
            ).copyWith(
              side: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.focused) ||
                    s.contains(WidgetState.pressed)) {
                  return const BorderSide(color: Tokens.primary, width: 1.6);
                }
                return const BorderSide(color: Tokens.border, width: 1.4);
              }),
              overlayColor: WidgetStateProperty.all(
                Tokens.primary.withValues(alpha: 0.08),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: Tokens.primaryText,
              disabledForegroundColor: Tokens.disabledInk,
              textStyle: Type.body(14, weight: FontWeight.w700),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                Tokens.primary.withValues(alpha: 0.08),
              ),
            ),
      ),
      iconTheme: const IconThemeData(color: Tokens.ink),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Tokens.primary,
        linearTrackColor: Tokens.neutralTint,
        circularTrackColor: Tokens.neutralTint,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.white : Tokens.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Tokens.primary : Tokens.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Tokens.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Tokens.inkMuted, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Tokens.primary
              : Tokens.inkMuted,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Tokens.primary,
        inactiveTrackColor: Tokens.border,
        thumbColor: Tokens.primary,
        overlayColor: Tokens.primary.withValues(alpha: 0.12),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Tokens.primary,
        selectionColor: Tokens.primary.withValues(alpha: 0.2),
        selectionHandleColor: Tokens.primary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Tokens.primaryText,
        unselectedLabelColor: Tokens.inkMuted,
        indicatorColor: Tokens.primary,
        dividerColor: Tokens.border,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Tokens.surface,
        selectedColor: Tokens.primaryText,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: Tokens.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: Type.body(13, weight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Tokens.pageBg,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tokens.radiusLg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Tokens.pageBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusLg),
        ),
        titleTextStyle: Type.display(22),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Tokens.charcoal,
        contentTextStyle: Type.body(
          14,
          color: Colors.white,
          weight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
