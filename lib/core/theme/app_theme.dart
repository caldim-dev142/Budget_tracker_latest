import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Material 3 AppTheme seeded from deep teal #0E7C7B (doc 08 §2).
/// One seed → both light and dark ColorScheme via ColorScheme.fromSeed.
/// Semantic extension tokens added for income/spending/protection/saving/overBudget.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF0E7C7B);

  // Semantic layer colours (light)
  static const incomeColorLight = Color(0xFF2E7D32);       // green 600
  static const spendingColorLight = Color(0xFFD32F2F);     // red 700
  static const protectionColorLight = Color(0xFF3949AB);   // indigo 500
  static const savingColorLight = Color(0xFFB45309);       // amber 700
  static const overBudgetColorLight = Color(0xFFC62828);   // warm red 700

  // Semantic layer colours (dark)
  static const incomeColorDark = Color(0xFF81C784);        // green 300
  static const spendingColorDark = Color(0xFFEF5350);      // red 400
  static const protectionColorDark = Color(0xFF7986CB);    // indigo 300
  static const savingColorDark = Color(0xFFFCD34D);        // amber 300
  static const overBudgetColorDark = Color(0xFFEF9A9A);    // red 200

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return _build(base);
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _build(base);
  }

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F1413) : const Color(0xFFF6F8F8),

      textTheme: _buildTextTheme(scheme),

      // Card: 18px radius, subtle border & clean shadow for Toshl-inspired layout
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 0.5,
        shadowColor: scheme.shadow.withValues(alpha: 0.08),
        color: isDark ? const Color(0xFF1B2220) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark
                ? scheme.outlineVariant.withValues(alpha: 0.15)
                : scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // AppBar: clean title & transparent background
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),

      // FAB: primary surface with subtle shadow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // NavigationBar (bottom nav)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF141A19) : Colors.white,
        elevation: 3,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF18201E) : scheme.surfaceContainerLowest,
      ),

      // Chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
      ),

      // Button Themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      // Spacing constants available via extension
      extensions: [
        AppSpacing.instance,
        AppLayerColors.forBrightness(scheme.brightness),
      ],
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    // doc 08 §3 — tabular figures for money (feature numbers)
    const tabularFigures = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

    return TextTheme(
      displayLarge: tabularFigures.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600, // Display — hero balances
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600, // Headline — screen titles, layer totals
      ),
      titleMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600, // Title — card headers
      ),
      bodyMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400, // Body — rows, notes
      ),
      labelMedium: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500, // Label — chips, captions, budget %
      ),
    );
  }
}

/// Spacing tokens (8pt grid per doc 04 §Layout)
class AppSpacing extends ThemeExtension<AppSpacing> {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static final AppSpacing instance = AppSpacing._();
  AppSpacing._();

  @override
  AppSpacing copyWith() => this;

  @override
  AppSpacing lerp(AppSpacing? other, double t) => this;
}

/// Semantic layer colour tokens per doc 08 §2.
class AppLayerColors extends ThemeExtension<AppLayerColors> {
  final Color income;
  final Color spending;
  final Color protection;
  final Color saving;
  final Color overBudget;

  const AppLayerColors({
    required this.income,
    required this.spending,
    required this.protection,
    required this.saving,
    required this.overBudget,
  });

  factory AppLayerColors.forBrightness(Brightness b) {
    return b == Brightness.light
        ? const AppLayerColors(
            income: AppTheme.incomeColorLight,
            spending: AppTheme.spendingColorLight,
            protection: AppTheme.protectionColorLight,
            saving: AppTheme.savingColorLight,
            overBudget: AppTheme.overBudgetColorLight,
          )
        : const AppLayerColors(
            income: AppTheme.incomeColorDark,
            spending: AppTheme.spendingColorDark,
            protection: AppTheme.protectionColorDark,
            saving: AppTheme.savingColorDark,
            overBudget: AppTheme.overBudgetColorDark,
          );
  }

  @override
  AppLayerColors copyWith({
    Color? income,
    Color? spending,
    Color? protection,
    Color? saving,
    Color? overBudget,
  }) {
    return AppLayerColors(
      income: income ?? this.income,
      spending: spending ?? this.spending,
      protection: protection ?? this.protection,
      saving: saving ?? this.saving,
      overBudget: overBudget ?? this.overBudget,
    );
  }

  @override
  AppLayerColors lerp(AppLayerColors? other, double t) {
    if (other == null) return this;
    return AppLayerColors(
      income: Color.lerp(income, other.income, t)!,
      spending: Color.lerp(spending, other.spending, t)!,
      protection: Color.lerp(protection, other.protection, t)!,
      saving: Color.lerp(saving, other.saving, t)!,
      overBudget: Color.lerp(overBudget, other.overBudget, t)!,
    );
  }
}

// Convenience extension on BuildContext
extension AppLayerColorsX on BuildContext {
  AppLayerColors get layerColors =>
      Theme.of(this).extension<AppLayerColors>()!;
}
