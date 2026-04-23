import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'router.dart';

/// Root widget. Hands off the theme + Material 3 ColorScheme that the
/// rest of the app composes against. Light + dark schemes both flat
/// (no surfaceTint) so cards stay calm on cream / ink.
class VedgePatientApp extends ConsumerWidget {
  const VedgePatientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(patientRouterProvider);

    return MaterialApp.router(
      title: 'Vedge Companion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(buildVedgeLightScheme()),
      darkTheme: _buildTheme(buildVedgeDarkScheme()),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme(ColorScheme cs) {
    final base = cs.brightness == Brightness.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);

    final textTheme = VedgeTypography.textTheme(cs);

    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      // Ripple-style splashes on cream are noisy; switch to a subtle ink
      // overlay (handled by InkWell defaults) and use clean PageTransitions.
      splashColor: VedgeColors.hover,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VedgeSpacing.space4,
          vertical: 18,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(VedgeSpacing.tapComfortable),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(VedgeSpacing.tapComfortable),
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size.fromHeight(VedgeSpacing.tapMin),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusLg),
          side: BorderSide(color: cs.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: cs.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(VedgeSpacing.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
        actionTextColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: VedgeColors.cream200.withValues(
          alpha: cs.brightness == Brightness.light ? 1.0 : 0.10,
        ),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.onSurface);
          }
          return IconThemeData(color: cs.outline);
        }),
        elevation: 0,
        height: VedgeSpacing.bottomNavHeight,
      ),
    );
  }
}
