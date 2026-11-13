import 'package:flutter/material.dart';

/// Buddy design system — LIGHT THEME ONLY.
/// Do not add dark-mode variants here; ThemeMode is locked to light
/// in main.dart per product decision (Sept 2026).
///
/// Values come from the Figma Make export (index.css). Every constant name that
/// existed before the redesign is kept, so screens that have not been migrated
/// yet still compile — they just pick up the new colors.
class AppColors {
  // Brand (was teal/coral; the design uses one purple for every primary action)
  static const primary = Color(0xFF8C5CEE);
  static const primaryDark = Color(0xFF7042CA);
  static const primaryLight = Color(0xFFA77AEF);
  static const primarySoft = Color(0xFFEEE5FB); // chips, icon tiles, soft banners
  static const primaryBorder = Color(0xFFDAC8F3); // border on soft purple surfaces
  static const accent = primary; // Approve is now the same purple as every CTA
  static const accentDark = primaryDark;

  // Status
  static const success = Color(0xFF347246);
  static const successBg = Color(0xFFE5F2E9);
  static const danger = Color(0xFFA23833);
  static const dangerBg = Color(0xFFFAE0DE);
  static const warning = Color(0xFF876619);
  static const warningBg = Color(0xFFFFF0C6);
  static const info = Color(0xFF185FA5);
  static const infoBg = Color(0xFFE6F1FB);
  static const expired = Color(0xFF6F657D);
  static const expiredBg = Color(0xFFEDEAF2);

  // Neutrals (light surfaces)
  static const bg = Color(0xFFF7F5FD); // page background (the design's "paper")
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF2ECFA);
  static const inputBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF292334);
  // Slightly darker than the design's #82778F / #A195AF so small text stays readable (>= 4.5:1 / ~3.5:1).
  static const textSecondary = Color(0xFF756A83);
  static const textMuted = Color(0xFF8E8399);
  static const border = Color(0xFFE7DFF1);

  // Gradients and shadows
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA77AEF), Color(0xFF8050DF)],
  );

  /// Soft lavender wash behind every screen (CSS: radial-gradient at 50% 32%).
  static const appBackground = RadialGradient(
    center: Alignment(0, -0.36),
    radius: 1.1,
    colors: [Color(0xFFE8E0FC), Color(0xFFF7F5FD), Color(0xFFF4F2FB)],
    stops: [0.0, 0.45, 1.0],
  );

  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F7856A5), blurRadius: 22, offset: Offset(0, 6)),
  ];

  static const buttonShadow = <BoxShadow>[
    BoxShadow(color: Color(0x268C5CEE), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

class AppRadius {
  static const double card = 18;
  static const double control = 16;
  static const double input = 12;
  static const double chip = 20;
}

class AppFonts {
  static const body = 'DM Sans';
  static const heading = 'Manrope';
}

/// Text styles from the design. Sizes are floored for a phone: captions 12sp,
/// uppercase labels 11sp (the Figma used 7–10px, which is unreadable on Android).
class AppText {
  static const display = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.08,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.7,
    color: AppColors.textPrimary,
  );

  static const heading = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const subheading = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const amount = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 35,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1.7,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const bodyStrong = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Small uppercase label above titles and inside cards ("YOUR ASSISTANT").
  /// Pass the text through `.toUpperCase()` or use the Eyebrow widget.
  static const eyebrow = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    height: 1.2,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    // Body text uses DM Sans; headline/title roles use Manrope.
    final applied = base.textTheme.apply(
      fontFamily: AppFonts.body,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    final textTheme = applied.copyWith(
      headlineLarge: applied.headlineLarge
          ?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w800),
      headlineMedium: applied.headlineMedium
          ?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w800),
      headlineSmall: applied.headlineSmall
          ?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w700),
      titleLarge: applied.titleLarge
          ?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w700),
      titleMedium: applied.titleMedium
          ?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w700),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: AppFonts.heading,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: AppText.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          side: const BorderSide(color: AppColors.border, width: 1.4),
          textStyle: AppText.button,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 44),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: AppFonts.body,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: AppFonts.body),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontFamily: AppFonts.body),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      // Kept so the old 5-tab HomeTabs still renders until the new navigation replaces it.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        height: 64,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            fontFamily: AppFonts.body,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primaryDark : AppColors.textSecondary);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySoft,
        labelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontFamily: AppFonts.body,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : const Color(0xFFD8CFE3);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: AppFonts.body,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}