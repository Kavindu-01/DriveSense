import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable banner card displaying whether the module's background
/// daemon/service is currently running, with a direct toggle control.
class BackgroundServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isRunning;
  final ValueChanged<bool> onToggle;
  final Color activeColor;

  const BackgroundServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.isRunning,
    required this.onToggle,
    this.activeColor = AppTheme.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRunning ? activeColor.withOpacity(0.5) : AppTheme.borderSubtle,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isRunning ? activeColor : AppTheme.textMuted).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRunning ? Icons.sensors : Icons.sensors_off,
              color: isRunning ? activeColor : AppTheme.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isRunning
                            ? AppTheme.greenEco.withOpacity(0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isRunning ? "ACTIVE" : "STANDBY",
                        style: TextStyle(
                          color: isRunning ? AppTheme.greenEco : AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isRunning,
            activeColor: activeColor,
            onChanged: (val) {
              onToggle(val);
              // TODO: Team Member: Invoke native background service start/stop here
              // e.g. FlutterBackgroundService().startService() / invoke("stopService")
            },
          ),
        ],
      ),
    );
  }
}
