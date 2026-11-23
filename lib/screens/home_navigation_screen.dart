import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/device_monitor.dart';
import '../theme/app_theme.dart';
import '../widgets/hud_gauge_widget.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});
  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  final monitor = DeviceMonitor();
  int tab = 0;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    monitor.addListener(changed);
    monitor.initialize();
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    monitor.removeListener(changed);
    monitor.dispose();
    super.dispose();
  }

  Future<void> action(String name) async {
    if (busy) return;
    setState(() => busy = true);
    await monitor.command(name);
    await monitor.refresh();
    if (mounted) setState(() => busy = false);
  }

  Future<void> start() async {
    await action('permissions');
    await action('start');
  }

  Widget card(
    String title,
    String detail, {
    IconData icon = Icons.info_outline,
    Color color = AppTheme.cyanAccent,
  }) => Card(
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(detail),
    ),
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
  Widget button(
    String text,
    VoidCallback? callback, {
    IconData icon = Icons.play_arrow,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: FilledButton.icon(
      onPressed: callback,
      icon: Icon(icon),
      label: Text(text),
    ),
  );
  List<dynamic> get hotspots => monitor.state['hotspots'] as List? ?? [];
  List<dynamic> get trips => monitor.history['trips'] as List? ?? [];
  List<dynamic> get events => monitor.history['events'] as List? ?? [];
  String metric(String key, [int decimals = 1]) =>
      monitor.number(key).toStringAsFixed(decimals);
  String clock(num seconds) =>
      Duration(seconds: seconds.toInt()).toString().split('.').first;
  String time(dynamic millis) =>
      DateTime.fromMillisecondsSinceEpoch((millis as num).toInt())
          .toLocal()
          .toString()
          .split('.')
          .first;
  @override
  Widget build(BuildContext context) {
    final countdown = (monitor.state['countdown'] as num?)?.toInt() ?? -1;
    final warning = monitor.state['warning'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            'DriveSense • Live HUD',
            'Drowsiness',
            'Crash hotspots',
            'Trips & safety',
            'Local profile',
          ][tab],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: monitor.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (monitor.error != null)
              MaterialBanner(
                content: Text(monitor.error!),
                actions: [
                  TextButton(
                    onPressed: monitor.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (countdown >= 0)
              Container(
                width: double.infinity,
                color: AppTheme.redDanger,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'POSSIBLE CRASH • $countdown seconds',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Emergency destination is your personal TEST number.',
                    ),
                    button(
                      "I’m OK — cancel & keep monitoring",
                      () => action('cancel'),
                      icon: Icons.check_circle,
                    ),
                  ],
                ),
              ),
            if (warning.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppTheme.amberWarning.withValues(alpha: 0.2),
                child: Text(warning),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: switch (tab) {
                  0 => hud(),
                  1 => camera(),
                  2 => hotspotPage(),
                  3 => historyPage(),
                  _ => profile(),
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (v) => setState(() => tab = v),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Live HUD'),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'Drowsiness',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Hotspots'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  List<Widget> hud() => [
    card(
      monitor.running ? 'Monitoring armed' : 'Monitoring stopped',
      monitor.state['tripActive'] == true ? 'Trip active • real hardware data' : 'Arm monitoring. Trips start after sustained driving, or start one manually.',
      icon: monitor.running ? Icons.sensors : Icons.sensors_off,
      color: monitor.running ? AppTheme.greenEco : AppTheme.textMuted,
    ),
    HudSpeedometerGauge(
      currentSpeed: monitor.number('speed'),
      gForce: monitor.number('gForce'),
    ),
    card(
      '${(monitor.number('distance') / 1000).toStringAsFixed(2)} km • ${clock(monitor.number('duration'))}',
      'Current recorded trip',
      icon: Icons.route,
    ),
    button(
      monitor.running
          ? 'Stop monitoring & save trip'
          : 'Grant permissions & arm monitoring',
      busy ? null : () => monitor.running ? action('stop') : start(),
      icon: monitor.running ? Icons.stop : Icons.shield,
    ),
    if (monitor.running)
      button(
        monitor.state['tripActive'] == true
            ? 'End current trip'
            : 'Start trip manually',
        () => action('trip'),
        icon: Icons.route,
      ),
    card(
      'Location',
      monitor.state['gpsStatus'] as String? ?? 'Not active',
      icon: Icons.gps_fixed,
    ),
    card(
      'Motion • ${metric('gForce', 2)} G',
      monitor.state['sensorStatus'] as String? ?? 'Not active',
      icon: Icons.sensors,
    ),
    card(
      'Impact audio • ${(monitor.number('audioPeak') * 100).toStringAsFixed(1)}%',
      monitor.state['audioStatus'] as String? ?? 'Not active',
      icon: Icons.mic,
    ),
    card(
      'Power • ${metric('battery', 0)}%',
      '${metric('temperature')} °C battery • ${monitor.state['charging'] == true ? 'charging' : 'unplugged'}',
      icon: Icons.battery_charging_full,
    ),
    if (monitor.state['candidate'] == true)
      card(
        'Impact candidate',
        'Checking independent signals and 30 s of stillness before countdown.',
        color: AppTheme.amberWarning,
      ),
    heading('Emergency workflow'),
    card(
      'Dispatch status',
      monitor.state['dispatch'] as String? ?? 'Not attempted',
    ),
    button(
      'Test alarm / speech / vibration',
      monitor.running ? () => action('alarm') : null,
      icon: Icons.volume_up,
    ),
    button(
      'Stationary countdown test',
      monitor.running ? confirmCountdown : null,
      icon: Icons.timer,
    ),
    const Text(
      'This build never automatically contacts 119. Automatic test SMS/calls are off until enabled in Local profile. Thresholds require device evaluation.',
    ),
  ];
  Future<void> confirmCountdown() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start stationary SOS test?'),
        content: Text(
          monitor.settings['autoDispatch'] == true
              ? 'If not cancelled, this may SMS your saved contact and placeholder, then request a call to that test number. Carrier charges may apply.'
              : 'Automatic dispatch is off. Test countdown and cancellation without sending messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start test'),
          ),
        ],
      ),
    );
    if (ok == true) await action('testCountdown');
  }

  List<Widget> camera() => [
    if (monitor.running)
      const SizedBox(
        height: 280,
        child: AndroidView(viewType: 'drivesense/camera'),
      ),
    card(
      'On-device ML Kit',
      monitor.state['cameraStatus'] as String? ?? 'Arm monitoring to begin',
      icon: Icons.visibility,
      color: AppTheme.amberWarning,
    ),
    const Text(
      'Front camera uses adaptive 8-second bursts, with longer gaps at low battery. No images or recordings saved. Between bursts, eyes are not observed.',
    ),
    card(
      '${metric('fps', 0)} analyzed FPS • ${metric('faces', 0)} faces',
      'Below 5 FPS means reduced temporal coverage.',
    ),
    card('Left eye openness', eye('leftEye')),
    card('Right eye openness', eye('rightEye')),
    card(
      'Head pitch',
      '${metric('pitch')}° • repeated downward movement checked',
    ),
    card('Mouth-opening candidates', metric('yawns', 0)),
    card(
      'Driver selection',
      'Camera region: ${monitor.settings['driverSide']?.toString() ?? 'center'}. Configure in Local profile. Keep only the driver in that region.',
    ),
    card(
      'Coverage limits',
      '1.5-second closure needs valid observations inside a burst. Sunglasses, darkness or a hidden face reduce coverage.',
    ),
    card(
      'Motion fallback',
      'Braking, speed changes and turning/phone irregularities can suggest risk; they do not establish sleep or a lane change.',
    ),
    const Text(
      'Sit still and face the front camera to check eye probabilities. Never test eye closure while driving.',
    ),
  ];
  String eye(String key) {
    final n = monitor.state[key] as num?;
    return n == null
        ? 'Unavailable — not assumed open or closed'
        : '${(n * 100).toStringAsFixed(0)}%';
  }

  List<Widget> hotspotPage() => [
    card(
      '${hotspots.length} imported hotspot locations',
      hotspots.isEmpty
          ? 'No verified dataset installed. Demo locations and crash counts are not used.'
          : 'Local dataset. Check sources and observation periods.',
      icon: Icons.radar,
      color: AppTheme.purpleRadar,
    ),
    if (monitor.state['nearestDistance'] != null)
      card(
        monitor.state['nearestName'] as String? ?? 'Nearest',
        '${metric('nearestDistance', 0)} m away',
      ),
    button('Import hotspot JSON from phone', () async {
      final result = await monitor.command('importHotspots');
      if (mounted && result != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.toString())));
      }
      await monitor.refresh();
    }, icon: Icons.file_open),
    const Text(
      'Warnings: 100 m entry regardless of direction, plus earlier speed-based caution. Monitoring and trip must be active. JSON needs id, name, latitude, longitude, source; period is optional.',
    ),
    const SizedBox(height: 12),
    mapView(),
    for (final h in hotspots)
      card(h['name'] as String, '${h['source']}\n${h['period']}'),
  ];
  Widget mapView({List<dynamic>? recordedRoute, int? tripId}) {
    final route = (recordedRoute ?? monitor.state['route'] as List? ?? [])
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    final lat = monitor.state['latitude'] as num?;
    final lon = monitor.state['longitude'] as num?;
    final center = route.isNotEmpty
        ? route.first
        : lat != null && lon != null
        ? LatLng(lat.toDouble(), lon.toDouble())
        : const LatLng(6.9271, 79.8612);
    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.drivesense_app',
            ),
            if (route.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    color: AppTheme.cyanAccent,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (lat != null && lon != null)
                  Marker(
                    point: LatLng(lat.toDouble(), lon.toDouble()),
                    child: const Icon(
                      Icons.my_location,
                      color: AppTheme.cyanAccent,
                    ),
                  ),
                for (final e in events.where(
                  (e) =>
                      tripId != null &&
                      e['trip'] == tripId &&
                      e['lat'] is num &&
                      e['lon'] is num,
                ))
                  Marker(
                    point: LatLng(
                      (e['lat'] as num).toDouble(),
                      (e['lon'] as num).toDouble(),
                    ),
                    child: Tooltip(
                      message: e['message'].toString(),
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.amberWarning,
                      ),
                    ),
                  ),
                for (final h in hotspots)
                  Marker(
                    point: LatLng(
                      (h['latitude'] as num).toDouble(),
                      (h['longitude'] as num).toDouble(),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: AppTheme.redDanger,
                    ),
                  ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: ColoredBox(
                color: Colors.black87,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    '© OpenStreetMap contributors • online basemap',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> historyPage() => [
    card(
      'Local trip history',
      'Only actual recorded trips. Data stays on this phone.',
      icon: Icons.storage,
    ),
    if (trips.isEmpty)
      const Text('No recorded trips yet. Arm monitoring and start a trip.'),
    for (final trip in trips)
      Card(
        child: ListTile(
          leading: const Icon(Icons.route, color: AppTheme.greenEco),
          title: Text(
            '${((trip['distance'] as num) / 1000).toStringAsFixed(2)} km • ${clock(trip['duration'] as num)}',
          ),
          subtitle: Text(
            '${time(trip['id'])}\n${trip['vehicle']} • ${trip['complete'] == true ? 'completed' : 'active/interrupted'} • score ${trip['score']} (experimental)',
          ),
          onTap: () => openTrip(trip),
        ),
      ),
    button('Copy local test report', () async {
      final report = {
        'generated': DateTime.now().toIso8601String(),
        'vehicle': monitor.settings['vehicle'],
        'snapshot': monitor.state,
        'history': monitor.history,
      };
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(report)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report copied. It contains trip locations.'),
          ),
        );
      }
    }, icon: Icons.copy),
    heading('Recent events'),
    for (final e in events.take(60))
      card(e['type'] as String, '${time(e['time'])}\n${e['message']}'),
  ];
  Future<void> openTrip(dynamic trip) async {
    final raw = await monitor.command(
      'route',
      arguments: (trip['id'] as num).toInt(),
    );
    final route = raw is String ? jsonDecode(raw) as List : <dynamic>[];
    if (!mounted) return;
    final km = (trip['distance'] as num) / 1000;
    final economy = (monitor.settings['kmPerLitre'] as num?)?.toDouble() ?? 35;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Trip ${time(trip['id'])}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              mapView(
                recordedRoute: route,
                tripId: (trip['id'] as num).toInt(),
              ),
              card(
                'Eye observation coverage',
                '${trip['eyeObservedSeconds'] ?? 0} observed seconds of ${trip['duration']} trip seconds. Gaps are not alertness.',
              ),
              card(
                'Score ${trip['score']} • experimental',
                '${trip['events']} motion events • ${trip['fatigue']} fatigue events. Not comparable when coverage differs.',
              ),
              card(
                'Estimated fuel ${(km / economy).toStringAsFixed(2)} L',
                'Assumes $economy km/L, not measured. Petrol CO₂ estimate ${(km / economy * 2.31).toStringAsFixed(2)} kg at 2.31 kg/L.',
              ),
              const Text(
                'Basemap needs internet; GPS route points remain local.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> profile() => [
    card(
      monitor.settings['name']?.toString().isNotEmpty == true
          ? monitor.settings['name'] as String
          : 'Set up your local profile',
      'No account or server • ${monitor.settings['vehicle']?.toString() ?? 'motorcycle'}',
      icon: Icons.person,
    ),
    button(
      'Edit profile, vehicle & emergency settings',
      editProfile,
      icon: Icons.edit,
    ),
    button(
      'Review camera, microphone & location permissions',
      () => action('permissions'),
      icon: Icons.security,
    ),
    button(
      'Open Android app permission settings',
      () => action('appSettings'),
      icon: Icons.settings,
    ),
    button(
      'Grant optional SMS / call permissions',
      () => action('dispatchPermissions'),
      icon: Icons.phone,
    ),
    button(
      'Open personal test number in dialler',
      () => action('dialTest'),
      icon: Icons.dialpad,
    ),
    card(
      'Emergency test destination',
      'placeholder • automatic test dispatch ${monitor.settings['autoDispatch'] == true ? 'enabled' : 'disabled'}',
    ),
    card(
      'Platform limits',
      '119 SMS support is unverified. This build never automatically contacts 119. Prerecorded speech cannot be injected into normal cellular calls. Background calls may be blocked; use the dialler fallback.',
    ),
    card(
      'Privacy',
      'No camera/video/audio recordings. Trips, events and hotspots stay local. Map tiles are fetched online.',
    ),
    button(
      'Delete local trips & events',
      monitor.running
          ? null
          : () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete local trip history?'),
                  content: const Text(
                    'Permanently removes recorded routes and safety events from this phone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) await action('deleteHistory');
            },
      icon: Icons.delete_outline,
    ),
  ];
  Future<void> editProfile() async {
    final value = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => ProfileEditor(settings: Map.of(monitor.settings)),
      ),
    );
    if (value != null) await monitor.save(value);
  }
}

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.settings});
  final Map<String, dynamic> settings;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final form = GlobalKey<FormState>();
  late final Map<String, dynamic> values = Map.of(widget.settings);
  late final controllers = {
    for (final key in ['name', 'phone', 'plate', 'contact', 'kmPerLitre'])
      key: TextEditingController(
        text: (widget.settings[key] ?? (key == 'kmPerLitre' ? 35 : ''))
            .toString(),
      ),
  };
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Local setup')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final entry in {
            'name': 'Driver name',
            'phone': 'Callback phone',
            'plate': 'Vehicle registration',
            'contact': 'Personal emergency contact',
            'kmPerLitre': 'Estimated fuel economy (km/L)',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: controllers[entry.key],
                decoration: InputDecoration(
                  labelText: entry.value,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: ['phone', 'contact'].contains(entry.key)
                    ? TextInputType.phone
                    : entry.key == 'kmPerLitre'
                    ? TextInputType.number
                    : TextInputType.text,
                validator: (text) {
                  if (['phone', 'contact'].contains(entry.key) &&
                      text!.isNotEmpty &&
                      !RegExp(r'^\+?[0-9 ]{9,18}$').hasMatch(text)) {
                    return 'Enter a full phone number, not an emergency short code';
                  }
                  if (entry.key == 'kmPerLitre' &&
                      ((double.tryParse(text ?? '') ?? 0) <= 0 ||
                          (double.tryParse(text ?? '') ?? 0) > 150)) {
                    return 'Use a value above 0 and at most 150';
                  }
                  return null;
                },
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: values['vehicle'] as String? ?? 'motorcycle',
            decoration: const InputDecoration(labelText: 'Vehicle profile'),
            items: const [
              DropdownMenuItem(value: 'motorcycle', child: Text('Motorcycle')),
              DropdownMenuItem(
                value: 'three_wheeler',
                child: Text('Three-wheeler'),
              ),
            ],
            onChanged: (v) => values['vehicle'] = v,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: values['driverSide'] as String? ?? 'center',
            decoration: const InputDecoration(
              labelText: 'Driver position in camera image',
            ),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left region')),
              DropdownMenuItem(value: 'center', child: Text('Centre region')),
              DropdownMenuItem(value: 'right', child: Text('Right region')),
            ],
            onChanged: (v) => values['driverSide'] = v,
          ),
          SwitchListTile(
            title: const Text('Periodic camera monitoring'),
            value: values['camera'] != false,
            onChanged: (v) => setState(() => values['camera'] = v),
          ),
          SwitchListTile(
            title: const Text('Enable automatic test SMS / call'),
            subtitle: const Text(
              'Countdown expiry can SMS your saved contact and placeholder, then request a call to that test number. Carrier charges may apply.',
            ),
            value: values['autoDispatch'] == true,
            onChanged: (v) => setState(() => values['autoDispatch'] = v),
          ),
          Text(
            'Countdown: ${values['countdown'] ?? 30} seconds (initial test setting)',
          ),
          Slider(
            value: ((values['countdown'] as num?)?.toDouble() ?? 30).clamp(
              15,
              60,
            ),
            min: 15,
            max: 60,
            divisions: 9,
            onChanged: (v) => setState(() => values['countdown'] = v.round()),
          ),
          const Text('Speech volume (alarm also follows phone alarm volume)'),
          Slider(
            value: ((values['volume'] as num?)?.toDouble() ?? 0.8).clamp(0, 1),
            onChanged: (v) => setState(() => values['volume'] = v),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              for (final entry in controllers.entries) {
                values[entry.key] = entry.value.text.trim();
              }
              values['kmPerLitre'] = double.parse(
                controllers['kmPerLitre']!.text,
              );
              Navigator.pop(context, values);
            },
            child: const Text('Save on this phone'),
          ),
        ],
      ),
    ),
  );
}
