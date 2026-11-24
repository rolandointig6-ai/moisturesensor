import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ControlsPage extends StatelessWidget {
  const ControlsPage({super.key});

  DocumentReference _docRef() {
    return FirebaseFirestore.instance
        .collection('plant_monitor')
        .doc('plant_01');
  }

  Future<void> _updateField(Map<String, dynamic> data) async {
    await _docRef().set(data, SetOptions(merge: true));
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

        final bool autoMode = (data['auto_mode'] ?? true) as bool;
        final bool pumpOn = (data['pump_on'] ?? false) as bool;
        final int threshold = ((data['threshold_percent'] ?? 35) as num).toInt();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Automated Watering'),
                        subtitle: Text(
                          autoMode
                              ? 'Pump turns ON automatically below $threshold%'
                              : 'Manual pump control is active',
                        ),
                        value: autoMode,
                        onChanged: (val) => _updateField({'auto_mode': val}),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Dry Moisture Threshold'),
                        subtitle: Text('Trigger watering below $threshold% soil moisture'),
                        trailing: Text('$threshold%'),
                      ),
                      Slider(
                        value: threshold.toDouble().clamp(10, 80),
                        min: 10,
                        max: 80,
                        divisions: 14,
                        label: '$threshold%',
                        onChanged: (val) => _updateField({
                          'threshold_percent': val.round(),
                        }),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Manual Water Pump'),
                        subtitle: Text(
                          autoMode
                              ? 'Switch to Manual mode to control pump directly'
                              : (pumpOn ? 'Pump is currently RUNNING' : 'Pump is OFF'),
                        ),
                        secondary: Icon(
                          Icons.water_drop,
                          color: pumpOn ? Colors.cyanAccent : Colors.grey,
                        ),
                        value: pumpOn,
                        onChanged: autoMode
                            ? null
                            : (val) => _updateField({'pump_on': val}),
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