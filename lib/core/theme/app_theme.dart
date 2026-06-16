import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
}

class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppCurves {
  static const spring = Cubic(0.22, 1.0, 0.36, 1.0);
  static const springBounce = Cubic(0.34, 1.56, 0.64, 1.0);
  static const decelerate = Cubic(0.0, 0.0, 0.2, 1.0);
}

class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 500);
  static const reveal = Duration(milliseconds: 600);
}

class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 1)),
          ]
        : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2), spreadRadius: -1),
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
          ];
  }

  static List<BoxShadow> elevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
          ]
        : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2),
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ];
  }
}

class AppColors {
  // Brand — Fiscalize teal
  static const primary      = Color(0xFF0D9488);
  static const primaryDark  = Color(0xFF0F766E);
  static const primaryLight = Color(0xFFCCFBF1);
  static const accent       = Color(0xFF10B981);

  // Light surfaces
  static const background   = Color(0xFFF2F2F7);
  static const surface      = Colors.white;
  static const card         = Colors.white;
  static const surfaceDim   = Color(0xFFEFEFF4);
  static const border       = Color(0xFFD1D5DB);
  static const divider      = Color(0xFFE5E7EB);

  // Light text
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF5B6578);
  static const textMuted     = Color(0xFF78849E);
  static const textHint      = Color(0xFFCBD5E1);

  // Dark surfaces
  static const darkBackground  = Color(0xFF0F172A);
  static const darkSurface     = Color(0xFF1E293B);
  static const darkCard        = Color(0xFF1E293B);
  static const darkSurfaceDim  = Color(0xFF172033);
  static const darkBorder      = Color(0xFF3B4963);
  static const darkDivider     = Color(0xFF2D3A4F);

  // Dark text
  static const darkTextPrimary   = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFFA1B1C7);
  static const darkTextMuted     = Color(0xFF7A8BA0);
  static const darkTextHint      = Color(0xFF475569);

  // Status
  static const success      = Color(0xFF059669);
  static const successLight = Color(0xFFD1FAE5);
  static const successDark  = Color(0xFF34D399);
  static const error        = Color(0xFFDC2626);
  static const errorLight   = Color(0xFFFEE2E2);
  static const errorDark    = Color(0xFFF87171);
  static const warning      = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const warningDark  = Color(0xFFFBBF24);
}

extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.darkBackground : AppColors.background;
  Color get surf => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.card;
  Color get surfDim => isDark ? AppColors.darkSurfaceDim : AppColors.surfaceDim;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.border;
  Color get dividerColor => isDark ? AppColors.darkDivider : AppColors.divider;
  Color get textP => isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textS => isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textM => isDark ? AppColors.darkTextMuted : AppColors.textMuted;
  Color get successBg => isDark ? AppColors.success.withValues(alpha: 0.15) : AppColors.successLight;
  Color get errorBg => isDark ? AppColors.error.withValues(alpha: 0.15) : AppColors.errorLight;
  Color get warningBg => isDark ? AppColors.warning.withValues(alpha: 0.15) : AppColors.warningLight;
  Color get primaryBg => isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight;
}

class AppTextStyles {
  static TextStyle display(BuildContext context) => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: context.textP, letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle heading(BuildContext context) => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600,
    color: context.textP, letterSpacing: -0.2,
  );
  static TextStyle subheading(BuildContext context) => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: context.textP,
  );
  static TextStyle body(BuildContext context) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: context.textS, height: 1.5,
  );
  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500, color: context.textP,
  );
  static TextStyle label(BuildContext context) => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, color: context.textS,
  );
  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500, color: context.textM, letterSpacing: 0.3,
  );
  static TextStyle mono(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w400, color: context.textP,
  );
  static TextStyle monoSmall(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 11, fontWeight: FontWeight.w400, color: context.textS,
  );
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final card = isDark ? AppColors.darkCard : AppColors.card;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textS = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textH = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final surfDim = isDark ? AppColors.darkSurfaceDim : AppColors.surfaceDim;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primary, secondary: AppColors.accent,
            surface: AppColors.darkSurface, error: AppColors.error,
            onPrimary: Colors.white, onSurface: AppColors.darkTextPrimary,
          )
        : const ColorScheme.light(
            primary: AppColors.primary, secondary: AppColors.accent,
            surface: AppColors.surface, error: AppColors.error,
            onPrimary: Colors.white, onSurface: AppColors.textPrimary,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0, scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: textP),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: textP),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surfDim,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: const BorderSide(color: AppColors.error)),
        labelStyle: GoogleFonts.inter(color: textS),
        hintStyle: GoogleFonts.inter(color: textH, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          elevation: 0, padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary, side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: card, elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textP,
        contentTextStyle: GoogleFonts.inter(
          color: isDark ? AppColors.textPrimary : Colors.white, fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : textH),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? (isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primaryLight)
              : surfDim),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// Legacy compat — used in main.dart and app.dart
final appTheme = AppTheme.light();
final appThemeDark = AppTheme.dark();
