import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../widgets/device_control_card.dart';
import '../widgets/status_card.dart';

void main() => runApp(const MaterialApp(home: HomeScreen()));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Map<String, IconData> _categoryIcons = {
    'Light': Icons.lightbulb,
    'Fan': Icons.air,
    'AC': Icons.ac_unit,
    'TV': Icons.tv,
    'Other': Icons.power,
  };

  int _totalRelays = 0;
  double _temperature = 0.0;
  double _humidity = 0.0;
  int _airQuality = 0;

  Map<String, dynamic> _devices = {};
  Map<String, dynamic> _relays = {};

  @override
  void initState() {
    super.initState();
    _setupDatabaseListeners();
  }

  void _setupDatabaseListeners() {
    // Listen for total relay count changes
    _database.child('settings/totalRelays').onValue.listen((event) {
      setState(() => _totalRelays = event.snapshot.value as int? ?? 0);
    });

    _database.child('devices').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      setState(() {
        _devices = data.map((key, value) => MapEntry(
              key.toString(),
              value,
            ));
      });
    });

    // Listen for relay configuration changes
    _database.child('relays').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      setState(() {
        _relays = data.map((key, value) => MapEntry(
              key.toString(),
              Map<String, dynamic>.from(value),
            ));
      });
    });
    _database.child('sensorData/temperature').onValue.listen((event) {
      setState(() {
        _temperature = (event.snapshot.value as num?)?.toDouble() ?? 0.0;
      });
    });

    _database.child('sensorData/humidity').onValue.listen((event) {
      setState(() {
        _humidity = (event.snapshot.value as num?)?.toDouble() ?? 0.0;
      });
    });

    _database.child('sensorData/air_quality').onValue.listen((event) {
      setState(() {
        _airQuality = (event.snapshot.value as int?) ?? 0;
      });
    });
  }

  List<String> get _availableRelays {
    final allRelays = List.generate(_totalRelays, (i) => 'relay${i + 1}');
    return allRelays.where((relay) {
      final name = _relays[relay]?['name']?.toString() ?? '';
      return name.isEmpty;
    }).toList();
  }

  void _toggleRelay(String relayId) {
    final currentStatus = _devices[relayId] ?? false;
    _database.child('devices/$relayId').set(!currentStatus);
  }

  void _showAddDialog() {
    String? selectedRelay;
    String deviceName = '';
    String? selectedCategory = 'Light';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Device'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Available Relays:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableRelays.map((relay) {
                    final isSelected = selectedRelay == relay;
                    return ChoiceChip(
                      label: Text(relay.replaceAll('relay', '')),
                      selected: isSelected,
                      onSelected: (selected) => setState(
                          () => selectedRelay = selected ? relay : null),
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) => deviceName = value,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categoryIcons.keys
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(_categoryIcons[category]),
                                const SizedBox(width: 10),
                                Text(category),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedRelay != null && deviceName.isNotEmpty) {
                  _database.child('relays/$selectedRelay').update({
                    'name': deviceName,
                    'category': selectedCategory,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Device'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String currentRelayId) {
    String? selectedRelay = currentRelayId;
    String deviceName = _relays[currentRelayId]?['name'] ?? '';
    String? selectedCategory = _relays[currentRelayId]?['category'] ?? 'Other';
    final nameController = TextEditingController(text: deviceName);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Device'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Available Relays:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [currentRelayId, ..._availableRelays].map((relay) {
                    final isSelected = selectedRelay == relay;
                    return ChoiceChip(
                      label: Text(relay.replaceAll('relay', '')),
                      selected: isSelected,
                      onSelected: (selected) => setState(
                          () => selectedRelay = selected ? relay : null),
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categoryIcons.keys
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(_categoryIcons[category]),
                                const SizedBox(width: 10),
                                Text(category),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _deleteDevice(currentRelayId),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedRelay != null && nameController.text.isNotEmpty) {
                  final Map<String, dynamic> updates = {};

                  if (selectedRelay != currentRelayId) {
                    updates['relays/$currentRelayId/name'] = '';
                    updates['relays/$currentRelayId/category'] = 'Other';
                    updates['devices/$currentRelayId'] = false;
                  }

                  updates['relays/$selectedRelay/name'] = nameController.text;
                  updates['relays/$selectedRelay/category'] = selectedCategory;
                  updates['devices/$selectedRelay'] =
                      _devices[currentRelayId] ?? false;

                  _database.update(updates);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDevice(String relayId) {
    _database.child('relays/$relayId').update({
      'name': '',
      'category': 'Other',
    });
    _database.child('devices/$relayId').set(false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final assignedRelays = _relays.entries
        .where((e) => (e.value['name'] as String? ?? '').isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('InHomeX',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade500)),
        elevation: 4,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _availableRelays.isNotEmpty ? _showAddDialog : null,
            tooltip:
                _availableRelays.isEmpty ? 'No available relays' : 'Add device',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Cards Row
          Container(
            color: Colors.deepPurple.shade100,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                statuscard(
                    icon: Icons.thermostat,
                    value: '${_temperature.toStringAsFixed(1)}°',
                    iconColor: _getTemperatureColor(_temperature)),
                const SizedBox(width: 16),
                statuscard(
                    icon: Icons.water_drop,
                    value: '${_humidity.toStringAsFixed(0)}%',
                    iconColor: Colors.blue),
                const SizedBox(width: 16),
                statuscard(
                  icon: Icons.air,
                  value: '$_airQuality',
                  iconColor: _getAirQualityColor(_airQuality),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.deepPurple.shade100, Colors.white],
                ),
              ),
              padding: EdgeInsets.all(10),
              child: _totalRelays == 0
                  ? const Center(child: Text('No relays configured'))
                  : assignedRelays.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No devices added yet!'),
                              const SizedBox(height: 20),
                              Text(
                                'Available Relays: ${_availableRelays.length}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: assignedRelays.length,
                          itemBuilder: (context, index) {
                            final entry = assignedRelays[index];
                            final relayId = entry.key;
                            final relayData = entry.value;
                            final name = relayData['name'] ?? 'Unnamed Device';
                            final status = _devices[relayId] ?? false;
                            final category =
                                _relays[relayId]?['category'] ?? 'Other';

                            return GestureDetector(
                              onLongPress: () => _showEditDialog(relayId),
                              child: DeviceControlCard(
                                icon: _categoryIcons[category]!,
                                isActive: status,
                                label: name,
                                onPressed: () => _toggleRelay(relayId),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 20) return Colors.blue;
    if (temperature <= 30) return Colors.green;
    return Colors.red;
  }

  Color _getAirQualityColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }
}
