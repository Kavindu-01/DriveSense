import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/release_ui.dart';
import 'services/device_monitor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Sans Sinhala',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await initializeDateFormatting('si');
  runApp(const DriveSenseApp());
}

ThemeData driveTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF20714D),
    brightness: brightness,
    primary: dark ? const Color(0xFF8CD9AF) : const Color(0xFF216D49),
    surface: dark ? const Color(0xFF18231C) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF101A14)
        : const Color(0xFFF4F7F3),
    fontFamily: 'NotoSinhala',
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF101A14) : const Color(0xFFF4F7F3),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      space: 24,
    ),
  );
}

class DriveSenseApp extends StatefulWidget {
  const DriveSenseApp({super.key});
  @override
  State<DriveSenseApp> createState() => _DriveSenseAppState();
}

class _DriveSenseAppState extends State<DriveSenseApp> {
  final monitor = DeviceMonitor();
  @override
  void initState() {
    super.initState();
    monitor.initialize();
  }

  @override
  void dispose() {
    monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: monitor,
    builder: (context, _) {
      final language = monitor.settings['language'] as String? ?? 'en';
      return MaterialApp(
        title: 'DriveSense',
        debugShowCheckedModeBanner: false,
        theme: driveTheme(Brightness.light),
        darkTheme: driveTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        locale: Locale(language),
        supportedLocales: const [Locale('en'), Locale('si')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: !monitor.ready
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : monitor.settings['onboarded'] == true
            ? HomeNavigationScreen(monitor: monitor)
            : FirstRunFlow(monitor: monitor),
      );
    },
  );
}
