import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:latlong2/latlong.dart';

import '../l10n/app_words.dart';
import '../services/device_monitor.dart';

AppWords words(DeviceMonitor m) =>
    AppWords(m.settings['language'] as String? ?? 'en');
String stamp(DeviceMonitor m, dynamic value) => DateFormat(
  'yyyy-MM-dd  HH:mm',
  words(m).language,
).format(DateTime.fromMillisecondsSinceEpoch((value as num).toInt()).toLocal());
String durationText(num seconds) {
  final d = Duration(seconds: seconds.toInt());
  return d.toString().split('.').first;
}

Widget panel(BuildContext context, Widget child, {Color? color}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Card(
    color: color,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);
Widget titleText(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: 12, bottom: 12),
  child: Text(
    text,
    style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700),
  ),
);
Widget note(
  BuildContext context,
  String title,
  String body, {
  IconData icon = Icons.info_outline,
  bool caution = false,
}) {
  final c = Theme.of(context).colorScheme;
  return panel(
    context,
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: caution ? const Color(0xFFAC6D12) : c.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(color: c.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
    color: caution ? c.tertiaryContainer.withValues(alpha: 0.45) : null,
  );
}

Widget actionButton(
  String title,
  VoidCallback? callback, {
  IconData icon = Icons.arrow_forward,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: FilledButton.icon(
    onPressed: callback,
    icon: Icon(icon),
    label: Text(title),
  ),
);
Widget pageList(List<Widget> children) => Align(
  alignment: Alignment.topCenter,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: children,
    ),
  ),
);
Future<bool> confirm(
  BuildContext context,
  AppWords w,
  String title,
  String detail,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(w('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

String cameraText(DeviceMonitor m) {
  final w = words(m);
  return w(
    switch (m.state['cameraPhase']) {
      'checking' => 'cameraCurrent',
      'face_missing' => 'faceMissing',
      'eyes_hidden' => 'eyesHidden',
      'failed' => 'cameraFailed',
      'permission' => 'cameraPermission',
      'hot' => 'cameraHot',
      'off' => 'cameraOff',
      'resting' => 'cameraRest',
      'starting' => 'cameraStarting',
      'analysis_wait' => 'cameraAnalysisWait',
      _ => 'cameraIdle',
    },
    {'seconds': m.number('cameraWait').toInt()},
  );
}

Future<void> enableChecks(DeviceMonitor m, {bool camera = true}) async {
  await m.command('permissions', arguments: {'camera': camera});
  await m.command('start');
  await m.refresh();
}

class FirstRunFlow extends StatefulWidget {
  const FirstRunFlow({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  State<FirstRunFlow> createState() => _FirstRunFlowState();
}

class _FirstRunFlowState extends State<FirstRunFlow> {
  bool busy = false;
  String vehicle = 'motorcycle';
  DeviceMonitor get m => widget.monitor;
  Future<void> prepare({bool skip = false}) async {
    setState(() => busy = true);
    await m.save({
      ...m.settings,
      'vehicle': vehicle,
      'camera': !skip,
      'resumeChecks': true,
      'autoDispatch': false,
    });
    if (skip) {
      await enableChecks(m, camera: false);
      await m.save({...m.settings, 'onboarded': true});
    } else {
      await enableChecks(m);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CameraCheckPage(monitor: m, setup: true),
          ),
        );
      }
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = words(m);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('DriveSense')),
      body: SafeArea(
        child: pageList([
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.shield_outlined, size: 44, color: c.primary),
            ),
          ),
          const SizedBox(height: 28),
          if (m.settings['languageChosen'] != true) ...[
            Text(
              w('chooseLanguage'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(w('chooseHint')),
            const SizedBox(height: 28),
            for (final language in ['en', 'si'])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => m.save({
                    ...m.settings,
                    'language': language,
                    'languageChosen': true,
                  }),
                  child: Text(
                    language == 'en' ? 'English' : 'සිංහල',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
          ] else ...[
            Text(
              w('welcome'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Text(w('welcomeBody'), style: const TextStyle(height: 1.6)),
            titleText(context, w('vehicleQuestion')),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'motorcycle',
                  label: Text(w('motorcycle')),
                  icon: const Icon(Icons.two_wheeler),
                ),
                ButtonSegment(
                  value: 'three_wheeler',
                  label: Text(w('threeWheeler')),
                  icon: const Icon(Icons.local_taxi_outlined),
                ),
              ],
              selected: {vehicle},
              onSelectionChanged: (v) => setState(() => vehicle = v.first),
            ),
            const SizedBox(height: 24),
            note(
              context,
              w('setupPermissions'),
              w('setupPermissionsBody'),
              icon: Icons.verified_user_outlined,
            ),
            actionButton(
              w('allowAndCheck'),
              busy ? null : () => prepare(),
              icon: Icons.camera_alt_outlined,
            ),
            TextButton(
              onPressed: busy ? null : () => prepare(skip: true),
              child: Text(w('skipCamera')),
            ),
          ],
        ]),
      ),
    );
  }
}

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int tab = 0;
  bool busy = false;
  DeviceMonitor get m => widget.monitor;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (m.settings['resumeChecks'] != false && !m.running) {
        await m.command('start');
      }
    });
  }

  Future<void> run(String method) async {
    if (busy) return;
    setState(() => busy = true);
    await m.command(method);
    await m.refresh();
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = words(m);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tab == 0
              ? 'DriveSense'
              : w(['drive', 'trips', 'map', 'settings'][tab]),
        ),
        actions: [
          IconButton(
            tooltip: w('help'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => HelpPage(monitor: m)),
            ),
            icon: const Icon(Icons.help_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (m.number('countdown') >= 0 && m.state.containsKey('countdown'))
              EmergencyBanner(monitor: m),
            if ((m.state['warning'] as String? ?? '').isNotEmpty &&
                m.number('countdown') < 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: note(
                  context,
                  w.warning(m.state['warning'] as String),
                  '',
                  icon: Icons.warning_amber_rounded,
                  caution: true,
                ),
              ),
            Expanded(
              child: switch (tab) {
                0 => drivePage(context),
                1 => TripsView(monitor: m),
                2 => MapViewPage(monitor: m),
                _ => SettingsView(monitor: m),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.directions_car_outlined),
            selectedIcon: const Icon(Icons.directions_car),
            label: w('drive'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: w('trips'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: w('map'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune),
            label: w('settings'),
          ),
        ],
      ),
    );
  }

  Widget drivePage(BuildContext context) {
    final w = words(m);
    final c = Theme.of(context).colorScheme;
    final trip = m.state['tripActive'] == true;
    final gps = (m.state['gpsStatus'] as String? ?? '').startsWith('GPS ±');
    return pageList([
      panel(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  m.running
                      ? Icons.shield_outlined
                      : Icons.pause_circle_outline,
                  color: c.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    w(
                      trip
                          ? 'duringTrip'
                          : m.running
                          ? 'goodToGo'
                          : 'checksOff',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              w(m.running ? 'autoHint' : 'startHint'),
              style: TextStyle(color: c.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                w('speed'),
                style: TextStyle(color: c.onSurfaceVariant),
              ),
            ),
            Center(
              child: Text(
                gps ? m.number('speed').round().toString() : '—',
                style: TextStyle(
                  fontFamily: 'NotoSinhala',
                  fontSize: 86,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: c.onSurface,
                ),
              ),
            ),
            const Center(child: Text('km/h')),
            if (!gps)
              Center(
                child: Text(
                  w('speedUnavailable'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: metricBox(
                    context,
                    w('distance'),
                    '${(m.number('distance') / 1000).toStringAsFixed(2)} km',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: metricBox(
                    context,
                    w('time'),
                    durationText(m.number('duration')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (m.error != null || (m.state['issue'] as String? ?? '').isNotEmpty)
        note(
          context,
          w('somethingStopped'),
          w('recovering'),
          icon: Icons.info_outline,
          caution: true,
        ),
      actionButton(
        w(m.running ? 'stopChecks' : 'startChecks'),
        busy
            ? null
            : () async {
                if (m.running) {
                  await run('stop');
                } else {
                  setState(() => busy = true);
                  await enableChecks(m);
                  if (mounted) setState(() => busy = false);
                }
              },
        icon: m.running ? Icons.pause : Icons.shield_outlined,
      ),
      if (m.running)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: busy ? null : () => run('trip'),
            icon: Icon(trip ? Icons.flag_outlined : Icons.route),
            label: Text(w(trip ? 'endTrip' : 'startTrip')),
          ),
        ),
      note(
        context,
        cameraText(m),
        w('cameraCheckBody'),
        icon: Icons.visibility_outlined,
        caution:
            m.state['cameraPhase'] == 'failed' ||
            m.state['cameraPhase'] == 'eyes_hidden',
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => CameraCheckPage(monitor: m),
            ),
          ),
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(w('cameraCheck')),
        ),
      ),
      panel(
        context,
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(w('moreDetails')),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(w(gps ? 'locationReady' : 'locationNeeded')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mic_none),
              title: Text(
                w(
                  (m.state['audioStatus'] as String? ?? '').startsWith(
                        'Microphone active',
                      )
                      ? 'soundReady'
                      : 'soundUnavailable',
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sensors_outlined),
              title: Text(
                w(
                  (m.state['sensorStatus'] as String? ?? '').startsWith(
                            'Accelerometer active',
                          ) ||
                          (m.state['sensorStatus'] as String? ?? '').startsWith(
                            'Accelerometer +',
                          )
                      ? 'movementReady'
                      : 'movementUnavailable',
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.battery_5_bar),
              title: Text(
                '${w('phoneBattery')} • ${m.number('battery').toInt()}%',
              ),
              subtitle: Text(
                w(m.state['charging'] == true ? 'charging' : 'notCharging'),
              ),
            ),
          ],
        ),
      ),
      OutlinedButton.icon(
        onPressed: () => startEmergency(context, m),
        icon: const Icon(Icons.sos),
        label: Text(w('emergency')),
      ),
    ]);
  }
}

Widget metricBox(BuildContext context, String label, String value) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
    ),
    const SizedBox(height: 6),
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
    ),
  ],
);

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  Widget build(BuildContext context) {
    final w = words(monitor);
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: c.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            w('areYouSafe'),
            style: TextStyle(
              color: c.onErrorContainer,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            w('respondSeconds', {
              'seconds': monitor.number('countdown').toInt(),
            }),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => monitor.command('cancel'),
            child: Text(w('imSafe')),
          ),
        ],
      ),
    );
  }
}

Future<void> startEmergency(
  BuildContext context,
  DeviceMonitor m, {
  bool practice = false,
}) async {
  final w = words(m);
  final ok = await confirm(
    context,
    w,
    w('confirmAlert'),
    '${w('confirmAlertBody')}\n\n${w(m.settings['autoDispatch'] == true ? 'alertOnHint' : 'alertOffHint')}',
    w('startAlert'),
  );
  if (!ok) return;
  if (!m.running) await enableChecks(m);
  await m.command('testCountdown');
}

class CameraCheckPage extends StatefulWidget {
  const CameraCheckPage({super.key, required this.monitor, this.setup = false});
  final DeviceMonitor monitor;
  final bool setup;
  @override
  State<CameraCheckPage> createState() => _CameraCheckPageState();
}

class _CameraCheckPageState extends State<CameraCheckPage> {
  DeviceMonitor get m => widget.monitor;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => prepare());
  }

  Future<void> prepare({bool force = false}) async {
    if (busy) return;
    setState(() => busy = true);
    await m.save({...m.settings, 'camera': true});
    if (!m.running || m.state['cameraPhase'] == 'permission') {
      await enableChecks(m);
    }
    await m.command('retryCamera', arguments: {'force': force});
    await m.refresh();
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: m,
    builder: (context, _) {
      final w = words(m);
      final frame =
          m.number('frameAge') >= 0 &&
          m.number('frameAge') < 6000 &&
          m.state.containsKey('frameAge');
      final eyes =
          m.state['cameraPhase'] == 'checking' &&
          frame &&
          m.number('analysisAge') >= 0 &&
          m.number('analysisAge') < 3000;
      return Scaffold(
        appBar: AppBar(title: Text(w('cameraCheck'))),
        body: SafeArea(
          child: pageList([
            Text(w('cameraAdvice'), style: const TextStyle(height: 1.6)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 340,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0xFF152019)),
                    if (m.running) const DriverCameraView(),
                    if (!frame)
                      IgnorePointer(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  m.state['cameraPhase'] == 'failed'
                                      ? Icons.videocam_off_outlined
                                      : Icons.camera_alt_outlined,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  cameraText(m),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            note(
              context,
              eyes ? w('cameraReady') : cameraText(m),
              w(
                eyes
                    ? 'cameraSafeTest'
                    : m.state['cameraPhase'] == 'failed'
                    ? 'cameraRetryBody'
                    : 'cameraAdvice',
              ),
              icon: eyes ? Icons.check_circle_outline : Icons.info_outline,
              caution: !eyes,
            ),
            actionButton(
              w('retry'),
              busy ? null : () => prepare(force: true),
              icon: Icons.refresh,
            ),
            if (m.state['cameraPhase'] == 'permission')
              TextButton(
                onPressed: () => m.command('appSettings'),
                child: Text(w('phoneSettings')),
              ),
            Text(
              w('cameraPrivacy'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            if (widget.setup)
              actionButton(
                w(eyes ? 'finishSetup' : 'continueForNow'),
                () async {
                  await m.save({
                    ...m.settings,
                    'onboarded': true,
                    'cameraConfirmed': eyes,
                    'resumeChecks': true,
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                icon: Icons.check,
              ),
          ]),
        ),
      );
    },
  );
}

class DriverCameraView extends StatelessWidget {
  const DriverCameraView({super.key});
  @override
  Widget build(BuildContext context) => PlatformViewLink(
    viewType: 'drivesense/camera',
    surfaceFactory: (context, controller) => AndroidViewSurface(
      controller: controller as AndroidViewController,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      gestureRecognizers: const {},
    ),
    onCreatePlatformView: (params) =>
        PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: 'drivesense/camera',
            layoutDirection: TextDirection.ltr,
            onFocus: () => params.onFocusChanged(true),
          )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create(),
  );
}

class TripsView extends StatelessWidget {
  const TripsView({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  Widget build(BuildContext context) {
    final m = monitor;
    final w = words(m);
    final trips = m.history['trips'] as List? ?? [];
    return pageList([
      Text(
        w('tripHistory'),
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(w('tripHistoryHint')),
      const SizedBox(height: 24),
      if (trips.isEmpty)
        note(context, w('noTrips'), w('noTripsBody'), icon: Icons.route),
      for (final trip in trips)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: Icon(
                Icons.route,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                '${((trip['distance'] as num) / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${stamp(m, trip['id'])}\n${durationText(trip['duration'] as num)} • ${w(trip['complete'] == true ? 'completed' : 'interrupted')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final raw = await m.command('route', arguments: trip['id']);
                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TripPage(
                        monitor: m,
                        trip: Map<String, dynamic>.from(trip),
                        route: raw is String ? jsonDecode(raw) as List : [],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
    ]);
  }
}

class TripPage extends StatelessWidget {
  const TripPage({
    super.key,
    required this.monitor,
    required this.trip,
    required this.route,
  });
  final DeviceMonitor monitor;
  final Map<String, dynamic> trip;
  final List route;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: monitor,
    builder: (context, _) {
      final m = monitor;
      final w = words(m);
      final km = (trip['distance'] as num) / 1000;
      final economy = (m.settings['kmPerLitre'] as num?)?.toDouble() ?? 35;
      final events = (m.history['events'] as List? ?? [])
          .where(
            (e) =>
                e['trip'] == trip['id'] &&
                e['type'] != 'diagnostic' &&
                e['type'] != 'error',
          )
          .toList();
      return Scaffold(
        appBar: AppBar(title: Text(w('tripSummary'))),
        body: SafeArea(
          child: pageList([
            Text(
              stamp(m, trip['id']),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            JourneyMap(monitor: m, route: route, events: events),
            const SizedBox(height: 20),
            panel(
              context,
              Row(
                children: [
                  Expanded(
                    child: metricBox(
                      context,
                      w('distance'),
                      '${km.toStringAsFixed(2)} km',
                    ),
                  ),
                  Expanded(
                    child: metricBox(
                      context,
                      w('time'),
                      durationText(trip['duration'] as num),
                    ),
                  ),
                ],
              ),
            ),
            note(
              context,
              '${w('drivingScore')} • ${trip['score']}',
              w('scoreHint'),
              icon: Icons.shield_outlined,
            ),
            panel(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${w('drivingEvents')}: ${trip['events']}'),
                  const SizedBox(height: 10),
                  Text('${w('tiredEvents')}: ${trip['fatigue']}'),
                  const SizedBox(height: 10),
                  Text(
                    w('eyeCoverage', {
                      'seconds': trip['eyeObservedSeconds'] as num? ?? 0,
                    }),
                  ),
                ],
              ),
            ),
            panel(
              context,
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(w('fuelEstimate')),
                children: [
                  ListTile(
                    title: Text('${(km / economy).toStringAsFixed(2)} L'),
                    subtitle: Text(w('fuelHint')),
                  ),
                  ListTile(
                    title: Text(
                      '${w('carbonEstimate')} • ${(km / economy * 2.31).toStringAsFixed(2)} kg',
                    ),
                    subtitle: const Text('2.31 kg CO₂/L'),
                  ),
                ],
              ),
            ),
            if (events.isNotEmpty) titleText(context, w('recentEvents')),
            for (final e in events)
              ListTile(
                leading: const Icon(Icons.circle_outlined, size: 18),
                title: Text(w.event(e['type'] as String)),
                subtitle: Text(stamp(m, e['time'])),
              ),
          ]),
        ),
      );
    },
  );
}

class JourneyMap extends StatelessWidget {
  const JourneyMap({
    super.key,
    required this.monitor,
    this.route = const [],
    this.events = const [],
  });
  final DeviceMonitor monitor;
  final List route;
  final List events;
  @override
  Widget build(BuildContext context) {
    final m = monitor;
    final points = route
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    final zones = m.state['hotspots'] as List? ?? [];
    final lat = m.state['latitude'] as num?;
    final lon = m.state['longitude'] as num?;
    final center = points.isNotEmpty
        ? points.first
        : lat != null && lon != null
        ? LatLng(lat.toDouble(), lon.toDouble())
        : const LatLng(6.9271, 79.8612);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.drivesense_app',
            ),
            if (points.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    color: const Color(0xFF22734D),
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (route.isEmpty && lat != null && lon != null)
                  Marker(
                    point: LatLng(lat.toDouble(), lon.toDouble()),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF22734D),
                    ),
                  ),
                for (final h in zones)
                  Marker(
                    point: LatLng(
                      (h['latitude'] as num).toDouble(),
                      (h['longitude'] as num).toDouble(),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFA36416),
                    ),
                  ),
                for (final e in events.where(
                  (e) => e['lat'] is num && e['lon'] is num,
                ))
                  Marker(
                    point: LatLng(
                      (e['lat'] as num).toDouble(),
                      (e['lon'] as num).toDouble(),
                    ),
                    child: Tooltip(
                      message: words(m).event(e['type'] as String),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFA36416),
                      ),
                    ),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => m.command('osmAttribution'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  Widget build(BuildContext context) {
    final m = monitor;
    final w = words(m);
    Future<void> save(String key, Object value) =>
        m.save({...m.settings, key: value});
    return pageList([
      titleText(context, w('profile')),
      panel(
        context,
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(
            (m.settings['name'] as String? ?? '').isEmpty
                ? w('profile')
                : m.settings['name'] as String,
          ),
          subtitle: Text(
            w(
              m.settings['vehicle'] == 'three_wheeler'
                  ? 'threeWheeler'
                  : 'motorcycle',
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => DetailsPage(monitor: m)),
          ),
        ),
      ),
      titleText(context, w('language')),
      panel(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('app-${w.language}'),
              initialValue: w.language,
              decoration: InputDecoration(labelText: w('language')),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'si', child: Text('සිංහල')),
              ],
              onChanged: (v) {
                if (v != null) save('language', v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'sms-${m.settings['smsLanguage'] as String? ?? 'en'}',
              ),
              initialValue: m.settings['smsLanguage'] as String? ?? 'en',
              decoration: InputDecoration(labelText: w('smsLanguage')),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'si', child: Text('සිංහල')),
              ],
              onChanged: (v) {
                if (v != null) save('smsLanguage', v);
              },
            ),
            const SizedBox(height: 14),
            Text(
              w('voiceEnglish'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      titleText(context, w('automatic')),
      panel(
        context,
        Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(w('autoArm')),
              subtitle: Text(w('autoArmHint')),
              value: m.settings['resumeChecks'] != false,
              onChanged: (v) => save('resumeChecks', v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(w('cameraSwitch')),
              value: m.settings['camera'] != false,
              onChanged: (v) => save('camera', v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(w('cameraCheck')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CameraCheckPage(monitor: m),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security_outlined),
              title: Text(w('permissions')),
              subtitle: Text(w('permissionsHint')),
              onTap: () => m.command('permissions'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(w('phoneSettings')),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => m.command('appSettings'),
            ),
          ],
        ),
      ),
      titleText(context, w('alarmTest')),
      panel(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w('alarmHint')),
            const SizedBox(height: 12),
            actionButton(w('alarmTest'), () async {
              if (!m.running) await enableChecks(m);
              await m.command('alarm');
            }, icon: Icons.volume_up_outlined),
            Text(w('speechVolume')),
            Slider(
              value: ((m.settings['volume'] as num?)?.toDouble() ?? 0.8).clamp(
                0,
                1,
              ),
              onChanged: (v) => m.previewSetting('volume', v),
              onChangeEnd: (v) => save('volume', v),
            ),
          ],
        ),
      ),
      titleText(context, w('emergencySettings')),
      panel(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(w('practiceDispatch')),
              subtitle: Text(w('practiceHint')),
              value: m.settings['autoDispatch'] == true,
              onChanged: (v) async {
                if (v &&
                    !await confirm(
                      context,
                      w,
                      w('practiceDispatch'),
                      w('practiceHint'),
                      w('continue'),
                    )) {
                  return;
                }
                if (v) await m.command('dispatchPermissions');
                await save('autoDispatch', v);
              },
            ),
            const SizedBox(height: 10),
            Text(
              '${w('testNumber')}: placeholder',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Text(
              w('noPublicCalls'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              w('countdownSetting', {
                'seconds': (m.settings['countdown'] as num? ?? 30).toInt(),
              }),
            ),
            Slider(
              value: ((m.settings['countdown'] as num?)?.toDouble() ?? 30)
                  .clamp(15, 60),
              min: 15,
              max: 60,
              divisions: 9,
              onChanged: (v) => m.previewSetting('countdown', v.round()),
              onChangeEnd: (v) => save('countdown', v.round()),
            ),
          ],
        ),
      ),
      ListTile(
        title: Text(w('help')),
        leading: const Icon(Icons.help_outline),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => HelpPage(monitor: m)),
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(w('version'), style: Theme.of(context).textTheme.bodySmall),
      ),
    ]);
  }
}

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final form = GlobalKey<FormState>();
  late final fields = {
    for (final key in ['name', 'phone', 'plate', 'contact', 'kmPerLitre'])
      key: TextEditingController(
        text: (widget.monitor.settings[key] ?? (key == 'kmPerLitre' ? 35 : ''))
            .toString(),
      ),
  };
  late String vehicle =
      widget.monitor.settings['vehicle'] as String? ?? 'motorcycle';
  late String position =
      widget.monitor.settings['driverSide'] as String? ?? 'center';
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.monitor,
    builder: (context, _) {
      final m = widget.monitor;
      final w = words(m);
      return Scaffold(
        appBar: AppBar(title: Text(w('profile'))),
        body: SafeArea(
          child: Form(
            key: form,
            child: pageList([
              Text(w('profileHint')),
              const SizedBox(height: 20),
              for (final key in fields.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: fields[key],
                    decoration: InputDecoration(
                      labelText: w(key == 'kmPerLitre' ? 'economy' : key),
                    ),
                    keyboardType: key == 'phone' || key == 'contact'
                        ? TextInputType.phone
                        : key == 'kmPerLitre'
                        ? TextInputType.number
                        : TextInputType.text,
                    validator: (value) {
                      if ((key == 'phone' || key == 'contact') &&
                          value!.trim().isNotEmpty &&
                          !RegExp(r'^\+?[0-9]{9,15}$')
                              .hasMatch(value.replaceAll(' ', ''))) {
                        return w('phoneNumberError');
                      }
                      if (key == 'kmPerLitre' &&
                          ((double.tryParse(value ?? '') ?? 0) < 1 ||
                              (double.tryParse(value ?? '') ?? 0) > 150)) {
                        return w('economyError');
                      }
                      return null;
                    },
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: vehicle,
                decoration: InputDecoration(labelText: w('vehicle')),
                items: [
                  DropdownMenuItem(
                    value: 'motorcycle',
                    child: Text(w('motorcycle')),
                  ),
                  DropdownMenuItem(
                    value: 'three_wheeler',
                    child: Text(w('threeWheeler')),
                  ),
                ],
                onChanged: (v) => vehicle = v ?? vehicle,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: position,
                decoration: InputDecoration(labelText: w('driverPosition')),
                items: [
                  for (final side in ['left', 'center', 'right'])
                    DropdownMenuItem(value: side, child: Text(w(side))),
                ],
                onChanged: (v) => position = v ?? position,
              ),
              const SizedBox(height: 24),
              actionButton(w('save'), () async {
                if (!form.currentState!.validate()) return;
                await m.save({
                  ...m.settings,
                  for (final e in fields.entries) e.key: e.value.text.trim(),
                  'kmPerLitre': double.parse(fields['kmPerLitre']!.text),
                  'vehicle': vehicle,
                  'driverSide': position,
                });
                if (context.mounted) Navigator.pop(context);
              }, icon: Icons.check),
            ]),
          ),
        ),
      );
    },
  );
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: monitor,
    builder: (context, _) {
      final m = monitor;
      final w = words(m);
      return Scaffold(
        appBar: AppBar(title: Text(w('help'))),
        body: SafeArea(
          child: pageList([
            Text(
              w('helpTitle'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            for (final item in [
              ('helpCamera', 'helpCameraBody'),
              ('helpAutomatic', 'helpAutomaticBody'),
              ('helpEmergency', 'helpEmergencyBody'),
              ('privacy', 'privacyBody'),
            ])
              panel(
                context,
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(w(item.$1)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        w(item.$2),
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            actionButton(w('shareReport'), () async {
              if (await confirm(
                context,
                w,
                w('shareReport'),
                w('shareHint'),
                w('share'),
              )) {
                await m.command('shareReport');
              }
            }, icon: Icons.ios_share_outlined),
            OutlinedButton.icon(
              onPressed: () => startEmergency(context, m, practice: true),
              icon: const Icon(Icons.timer_outlined),
              label: Text(w('practiceAlert')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => m.command('dialTest'),
              icon: const Icon(Icons.phone_outlined),
              label: Text(w('callTest')),
            ),
            const SizedBox(height: 16),
            Text(
              w('noPublicCalls'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: m.running
                  ? null
                  : () async {
                      if (await confirm(
                        context,
                        w,
                        w('deleteConfirm'),
                        w('deleteHint'),
                        w('delete'),
                      )) {
                        await m.command('deleteHistory');
                        await m.refresh();
                      }
                    },
              child: Text(w('deleteHistory')),
            ),
            Text(w('deleteHint'), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
    },
  );
}

class MapViewPage extends StatelessWidget {
  const MapViewPage({super.key, required this.monitor});
  final DeviceMonitor monitor;
  @override
  Widget build(BuildContext context) {
    final m = monitor;
    final w = words(m);
    final zones = m.state['hotspots'] as List? ?? [];
    return pageList([
      Text(
        w('mapTitle'),
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      JourneyMap(monitor: m, route: m.state['route'] as List? ?? []),
      const SizedBox(height: 12),
      Text(w('mapHint'), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 20),
      note(
        context,
        w(zones.isEmpty ? 'noZones' : 'zoneCount', {'count': zones.length}),
        w(zones.isEmpty ? 'noZonesHint' : 'zoneHint'),
        icon: Icons.location_on_outlined,
      ),
      actionButton(w('importZones'), () async {
        final result = await m.command('importHotspots');
        if (result == 'Import cancelled') return;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(w(result == null ? 'importError' : 'imported')),
            ),
          );
        }
        await m.refresh();
      }, icon: Icons.file_open_outlined),
      for (final z in zones)
        panel(
          context,
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(z['name'] as String),
            children: [
              ListTile(
                title: Text(w('source')),
                subtitle: Text(z['source'] as String),
              ),
              ListTile(
                title: Text(w('period')),
                subtitle: Text(
                  z['period'] == 'Unknown observation period'
                      ? w('unknownPeriod')
                      : z['period'] as String,
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}
