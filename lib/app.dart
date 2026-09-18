import 'package:flutter/material.dart';

import 'core/app/app_dependencies.dart';
import 'features/auth/presentation/app_bootstrap_screen.dart';
import 'features/auth/presentation/auth_loading_screen.dart';

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key, AppDependencies? dependencies})
    : dependencies = dependencies ?? const AppDependencies();

  final AppDependencies dependencies;

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isThemeReady = false;

  @override
  void initState() {
    super.initState();
    _restoreThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finanse osobiste',
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: _isThemeReady
          ? AppBootstrapScreen(
              dependencies: widget.dependencies,
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
            )
          : const AuthLoadingScreen(
              title: 'Przygotowanie interfejsu',
              description:
                  'Odtwarzanie preferencji motywu i uruchamianie aplikacji.',
            ),
    );
  }

  Future<void> _restoreThemeMode() async {
    ThemeMode? savedThemeMode;
    try {
      savedThemeMode = await widget.dependencies.themePreferencesRepository
          .loadThemeMode();
    } catch (_) {
      savedThemeMode = null;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = savedThemeMode ?? ThemeMode.light;
      _isThemeReady = true;
    });
  }

  void _setThemeMode(ThemeMode value) {
    if (_themeMode == value) {
      return;
    }

    setState(() {
      _themeMode = value;
    });

    widget.dependencies.themePreferencesRepository
        .saveThemeMode(value)
        .catchError((_) {});
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    final buttonForeground = colorScheme.primary;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );
    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4F1EA),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: dialogShape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: dialogShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: dialogShape,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.78),
          fontSize: 15,
          height: 1.45,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: dialogShape,
        headerBackgroundColor: colorScheme.primaryContainer,
        headerForegroundColor: colorScheme.onPrimaryContainer,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.onSurface;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        todayForegroundColor: WidgetStatePropertyAll(colorScheme.primary),
        todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: buttonForeground,
        ),
        confirmButtonStyle: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: buttonForeground),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonForeground,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: focusedInputBorder,
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.8),
          ),
        ),
        focusedErrorBorder: focusedInputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const darkScaffold = Color(0xFF101412);
    const darkSurface = Color(0xFF171C1A);
    const darkSurfaceLow = Color(0xFF1B211F);
    const darkSurfaceContainer = Color(0xFF202724);
    const darkSurfaceContainerHigh = Color(0xFF26302C);
    const darkSurfaceContainerHighest = Color(0xFF303A35);
    const darkOutline = Color(0xFF66746D);
    const darkOutlineVariant = Color(0xFF3B4943);
    const darkPrimary = Color(0xFF74D5C4);
    const darkPrimaryContainer = Color(0xFF154A42);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: darkPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: darkPrimary,
          onPrimary: const Color(0xFF05251F),
          primaryContainer: darkPrimaryContainer,
          onPrimaryContainer: const Color(0xFFC2F4EA),
          secondary: const Color(0xFFD7C38B),
          onSecondary: const Color(0xFF2B220A),
          secondaryContainer: const Color(0xFF463A1F),
          onSecondaryContainer: const Color(0xFFF2E3B4),
          tertiary: const Color(0xFF94C9FF),
          onTertiary: const Color(0xFF062237),
          tertiaryContainer: const Color(0xFF173A56),
          onTertiaryContainer: const Color(0xFFD5EAFF),
          error: const Color(0xFFFFB3AD),
          onError: const Color(0xFF4F0D0D),
          errorContainer: const Color(0xFF7A211E),
          onErrorContainer: const Color(0xFFFFDAD6),
          surface: darkSurface,
          onSurface: const Color(0xFFE3E8E3),
          surfaceContainerLowest: const Color(0xFF0C100E),
          surfaceContainerLow: darkSurfaceLow,
          surfaceContainer: darkSurfaceContainer,
          surfaceContainerHigh: darkSurfaceContainerHigh,
          surfaceContainerHighest: darkSurfaceContainerHighest,
          onSurfaceVariant: const Color(0xFFC4CEC7),
          outline: darkOutline,
          outlineVariant: darkOutlineVariant,
          inverseSurface: const Color(0xFFDCE5DF),
          onInverseSurface: const Color(0xFF26302C),
          inversePrimary: const Color(0xFF006B5E),
          surfaceTint: Colors.transparent,
        );
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    final buttonForeground = colorScheme.primary;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.78),
      ),
    );
    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkScaffold,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: dialogShape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: dialogShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: dialogShape,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
          fontSize: 15,
          height: 1.45,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: dialogShape,
        headerBackgroundColor: darkPrimaryContainer,
        headerForegroundColor: colorScheme.onPrimaryContainer,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.onSurface;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        todayForegroundColor: WidgetStatePropertyAll(colorScheme.primary),
        todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: buttonForeground,
        ),
        confirmButtonStyle: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      dividerColor: darkOutlineVariant.withValues(alpha: 0.68),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: darkPrimaryContainer.withValues(alpha: 0.78),
        surfaceTintColor: Colors.transparent,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: buttonForeground),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonForeground,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainer,
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: focusedInputBorder,
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.82),
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.52),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.85),
          ),
        ),
        focusedErrorBorder: focusedInputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
      ),
    );
  }
}
