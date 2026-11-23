import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivesense_app/main.dart';
import 'package:drivesense_app/l10n/app_words.dart';
import 'package:drivesense_app/services/device_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  late Map<String, dynamic> saved;
  late Map<String, dynamic> snapshot;
  setUpAll(() async {
    final font = FontLoader('NotoSinhala')
      ..addFont(rootBundle.load('assets/fonts/NotoSansSinhala.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    calls.clear();
    saved = {
      'vehicle': 'motorcycle',
      'camera': true,
      'autoDispatch': false,
      'onboarded': true,
      'languageChosen': true,
      'language': 'en',
      'smsLanguage': 'en',
      'resumeChecks': false,
      'volume': 0.8,
      'countdown': 30,
    };
    snapshot = {
      'running': false,
      'countdown': -1,
      'hotspots': [],
      'route': [],
      'cameraPhase': 'idle',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceMonitor.channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'settings':
              return jsonEncode(saved);
            case 'saveSettings':
              saved = Map<String, dynamic>.from(
                jsonDecode(call.arguments as String) as Map,
              );
              return true;
            case 'snapshot':
              return jsonEncode(snapshot);
            case 'history':
              return jsonEncode({'trips': [], 'events': []});
            default:
              return true;
          }
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceMonitor.channel, null),
  );
  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(392, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const RepaintBoundary(key: ValueKey('capture'), child: DriveSenseApp()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('releases/previews')..createSync(recursive: true);
      File('${dir.path}/$name.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('Home uses simple controls without demo journeys', (
    tester,
  ) async {
    await phone(tester);
    expect(find.text('Safety checks are off'), findsOneWidget);
    expect(find.text('Current speed'), findsOneWidget);
    expect(find.textContaining('FPS'), findsNothing);
    await capture(tester, 'home-english');
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    expect(find.text('Your first journey starts here'), findsOneWidget);
    expect(calls, isNot(contains('testCountdown')));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Sinhala switch leaves SMS language independent', (tester) async {
    await phone(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app-en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('සිංහල').last);
    await tester.pumpAndSettle();
    expect(saved['language'], 'si');
    expect(saved['smsLanguage'], 'en');
    expect(find.text('යෙදුමේ භාෂාව'), findsWidgets);
    expect(find.text('හඬ දැනුම්දීම් ඉංග්‍රීසියෙන් පවතී.'), findsOneWidget);
    await tester.tap(find.text('ගමන').last);
    await tester.pumpAndSettle();
    await capture(tester, 'home-sinhala');
    expect(find.text('ආරක්ෂක පරීක්ෂා නවතා ඇත'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('First launch asks for language before permissions', (
    tester,
  ) async {
    saved['onboarded'] = false;
    saved['languageChosen'] = false;
    await phone(tester);
    expect(find.text('Choose your language'), findsOneWidget);
    expect(calls, isNot(contains('permissions')));
    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();
    expect(find.text('සැහැල්ලුවෙන්, ආරක්ෂිතව ගමන් යන්න'), findsOneWidget);
    expect(calls, isNot(contains('permissions')));
    await capture(tester, 'setup-sinhala');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Camera failure shows a useful message without exception text', (
    tester,
  ) async {
    snapshot['cameraPhase'] = 'failed';
    snapshot['issue'] = 'camera';
    await phone(tester);
    await tester.scrollUntilVisible(find.text('Check your camera'), 200);
    await tester.tap(find.text('Check your camera').last);
    await tester.pumpAndSettle();
    expect(find.text('The camera couldn’t start'), findsWidgets);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('getClass'), findsNothing);
    expect(calls, contains('retryCamera'));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Appearance follows the phone dark setting', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await phone(tester);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    await capture(tester, 'home-dark');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Emergency help requires confirmation before starting an alert', (
    tester,
  ) async {
    await phone(tester);
    await tester.scrollUntilVisible(find.text('Emergency help'), 300);
    await tester.tap(find.text('Emergency help'));
    await tester.pumpAndSettle();
    expect(find.text('Start an alert?'), findsOneWidget);
    expect(calls, isNot(contains('testCountdown')));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls, isNot(contains('testCountdown')));
    await tester.pumpWidget(const SizedBox());
  });
  test('Both languages have complete nonempty wording', () {
    for (final entry in AppWords.phrases.entries) {
      expect(entry.value.length, 2, reason: entry.key);
      expect(
        entry.value.every((v) => v.trim().isNotEmpty),
        isTrue,
        reason: entry.key,
      );
      if (entry.key != 'version') {
        expect(
          RegExp(r'[\u0D80-\u0DFF]').hasMatch(entry.value[1]),
          isTrue,
          reason: entry.key,
        );
      }
    }
    expect(const AppWords('si')('cameraRest', {'seconds': 12}), contains('12'));
    expect(
      const AppWords('en')('cameraRest', {'seconds': 12}),
      'Next camera check in 12s',
    );
  });
  test('Device errors keep codes instead of exposing raw exceptions', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          DeviceMonitor.channel,
          (_) async => throw PlatformException(
            code: 'device',
            message: 'getClass() on a null object reference',
          ),
        );
    final m = DeviceMonitor();
    expect(await m.command('start'), isNull);
    expect(m.error, 'device');
    expect(m.running, isFalse);
    m.dispose();
  });
}
