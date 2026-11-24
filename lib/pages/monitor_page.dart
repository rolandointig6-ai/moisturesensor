import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  bool? _wasDry;
  bool? _wasPumpOn;

  DocumentReference _docRef() {
    return FirebaseFirestore.instance
        .collection('plant_monitor')
        .doc('plant_01');
  }

  void _showNotification(String message, {required bool isWarning}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                isWarning ? Colors.amber.shade900 : Colors.teal.shade800,
            content: Row(
              children: [
                Icon(
                  isWarning ? Icons.warning_amber_rounded : Icons.water_drop,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _docRef().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rawData = snapshot.data?.data();
        final Map<String, dynamic> data =
            rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};

        final int moisture = ((data['moisture_percent'] ?? 0) as num).toInt();
        final int rawValue = ((data['raw_value'] ?? 0) as num).toInt();
        final int threshold = ((data['threshold_percent'] ?? 35) as num).toInt();
        final bool pumpOn = (data['pump_on'] ?? false) as bool;
        final bool autoMode = (data['auto_mode'] ?? true) as bool;
        final bool isDry = moisture < threshold;

        if (_wasDry != null && isDry && !_wasDry!) {
          _showNotification(
            'Alert: Soil moisture dropped to $moisture% (below $threshold%).',
            isWarning: true,
          );
        }
        if (_wasPumpOn != null && pumpOn && !_wasPumpOn!) {
          _showNotification(
            'Watering started: Water pump is now ON.',
            isWarning: false,
          );
        }
        _wasDry = isDry;
        _wasPumpOn = pumpOn;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (isDry || pumpOn) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: pumpOn
                          ? Colors.cyan.withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pumpOn ? Colors.cyanAccent : Colors.amberAccent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pumpOn
                              ? Icons.water_drop
                              : Icons.notifications_active,
                          color: pumpOn ? Colors.cyanAccent : Colors.amberAccent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pumpOn
                                ? 'Active Watering: Pump is currently watering the plant.'
                                : 'Low Moisture Warning: Soil is at $moisture% (threshold: $threshold%).',
                            style: TextStyle(
                              color: pumpOn
                                  ? Colors.cyanAccent
                                  : Colors.amberAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'SOIL MOISTURE',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                letterSpacing: 1.2,
                                color: Colors.tealAccent,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$moisture%',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDry
                              ? 'Soil is dry — needs water'
                              : 'Soil moisture is healthy',
                          style: TextStyle(
                            color: isDry
                                ? Colors.amberAccent
                                : Colors.lightGreenAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        LinearProgressIndicator(
                          value: (moisture.clamp(0, 100)) / 100,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Raw ADC Value: $rawValue',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.tune),
                        title: const Text('Operating Mode'),
                        trailing: Text(autoMode ? 'AUTO' : 'MANUAL'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.water_drop,
                          color: pumpOn ? Colors.cyanAccent : Colors.grey,
                        ),
                        title: const Text('Water Pump Status'),
                        trailing: Text(pumpOn ? 'RUNNING' : 'OFF'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.thermostat_auto),
                        title: const Text('Dry Threshold'),
                        trailing: Text('$threshold%'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}