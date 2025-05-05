import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../widgets/device_control_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, bool> devices = {};
  Map<String, IconData> deviceIcons = {};

  final Map<String, IconData> categoryIcons = {
    'Fan': Icons.air,
    'Light': Icons.lightbulb,
    'AC': Icons.ac_unit,
    'TV': Icons.tv,
    'PLUG': Icons.electrical_services_rounded,
    'Other': Icons.devices_other,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealTimeListener();
    _loadDevices();
  }

  void _loadInitialData() async {
    try {
      DatabaseEvent snapshot = await _database.child('devices').once();
      if (snapshot.snapshot.value is Map) {
        setState(() {
          devices = Map<String, bool>.from(snapshot.snapshot.value as Map);
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _setupRealTimeListener() {
    _database.child('devices').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        setState(() {
          devices = Map<String, bool>.from(data);
        });
      }
    });
  }

  void _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDevices = prefs.getString('devices');
    final storedIcons = prefs.getString('deviceIcons');

    if (storedDevices != null) {
      setState(() {
        devices = Map<String, bool>.from(jsonDecode(storedDevices));
      });
    }

    if (storedIcons != null) {
      setState(() {
        Map<String, String> iconMap =
            Map<String, String>.from(jsonDecode(storedIcons));
        deviceIcons = iconMap.map((key, value) =>
            MapEntry(key, categoryIcons[value] ?? Icons.devices_other));
      });
    }
  }

  void _toggleDevice(String device, bool status) async {
    setState(() {
      devices[device] = status;
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('devices', jsonEncode(devices));

    _database.child('devices/$device').set(status).then((_) {
      print('$device updated to $status');
    }).catchError((error) {
      print('Failed to update $device: $error');
    });
  }

  void _addDevice() {
    showDialog(
      context: context,
      builder: (context) {
        String newDevice = "";
        String? selectedCategory;
        IconData? selectedIcon;

        return AlertDialog(
          title: Text("Add New Device"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) => newDevice = value,
                    decoration: InputDecoration(hintText: "Enter device name"),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text("Select Category"),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                        selectedIcon = categoryIcons[value];
                      });
                    },
                    items: categoryIcons.keys.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(categoryIcons[category],
                                color: Colors.deepPurple),
                            SizedBox(width: 10),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newDevice.isNotEmpty &&
                    !devices.containsKey(newDevice) &&
                    selectedIcon != null) {
                  setState(() {
                    devices[newDevice] = false;
                    deviceIcons[newDevice] = selectedIcon!;
                  });

                  _database.child('devices/$newDevice').set(false).then((_) {
                    print('$newDevice added to Firebase.');
                  }).catchError((error) {
                    print('Failed to add $newDevice: $error');
                  });

                  _saveDevices();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Please enter a valid device name and select a category."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Add"),
            )
          ],
        );
      },
    );
  }

  Future<void> _saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('devices', jsonEncode(devices));
    prefs.setString(
        'deviceIcons',
        jsonEncode(deviceIcons.map(
          (key, value) => MapEntry(
              key,
              categoryIcons.entries
                  .firstWhere((entry) => entry.value == value)
                  .key),
        )));
  }

  void _editDevice() {
    String selectedDevice = devices.keys.first;
    String newDeviceName = selectedDevice;
    String? selectedCategory;
    IconData? selectedIcon = deviceIcons[selectedDevice];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Device"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedDevice,
                    hint: Text("Select Device"),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDevice = value!;
                        newDeviceName = value;
                        selectedIcon = deviceIcons[value];
                      });
                    },
                    items: devices.keys.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text(device),
                      );
                    }).toList(),
                  ),
                  TextField(
                    onChanged: (value) => newDeviceName = value,
                    decoration: InputDecoration(labelText: "New Device Name"),
                    controller: TextEditingController(text: selectedDevice),
                  ),
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text("Select New Icon"),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                        selectedIcon = categoryIcons[value];
                      });
                    },
                    items: categoryIcons.keys.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(categoryIcons[category],
                                color: Colors.deepPurple),
                            SizedBox(width: 10),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newDeviceName.isNotEmpty && selectedIcon != null) {
                  setState(() {
                    devices.remove(selectedDevice);
                    devices[newDeviceName] = false;
                    deviceIcons[newDeviceName] = selectedIcon!;
                  });

                  _database.child('devices/$selectedDevice').remove();
                  _database.child('devices/$newDeviceName').set(false);

                  _saveDevices();
                  Navigator.pop(context);
                }
              },
              child: Text("Save"),
            )
          ],
        );
      },
    );
  }

  void _deleteDevice() {
    if (devices.isNotEmpty) {
      String selectedDevice = devices.keys.first;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete Device"),
            content: Text("Are you sure you want to delete $selectedDevice?"),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    devices.remove(selectedDevice);
                    deviceIcons.remove(selectedDevice);
                  });

                  _database.child('devices/$selectedDevice').remove();
                  _saveDevices();
                  Navigator.pop(context);
                },
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InHomeX',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade500)),
        elevation: 4,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editDevice();
              } else if (value == 'delete') {
                _deleteDevice();
              } else if (value == 'add') {
                _addDevice(); // Call add function
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                ),
              ),
              PopupMenuItem(
                value: 'add',
                child: ListTile(
                  leading: Icon(Icons.add, color: Colors.green),
                  title: Text('Add'),
                ),
              ),
            ],
            icon: Icon(Icons.menu), // Three-line icon (hamburger menu)
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Cards Row
          Container(
            color: Colors.deepPurple.shade100,
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildStatusCard(
                  icon: Icons.thermostat,
                  value: '22°',
                  iconColor: _getTemperatureColor(22),
                ),
                SizedBox(width: 16),
                _buildStatusCard(
                    icon: Icons.water_drop,
                    value: '40%',
                    iconColor: Colors.blue),
                SizedBox(width: 16),
                _buildStatusCard(
                  icon: Icons.air,
                  value: '135',
                  iconColor: Colors.grey,
                ),
              ],
            ),
          ),

          // Existing Grid View
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
                child: devices.isEmpty
                    ? Center(child: Text("No devices added yet!"))
                    : GridView.builder(
                        itemCount: devices.keys.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          String device = devices.keys.elementAt(index);
                          bool isSelected = devices[device]!;
                          IconData icon =
                              deviceIcons[device] ?? Icons.devices_other;

                          return DeviceControlCard(
                            icon: icon,
                            isSelected: isSelected,
                            label: device, // 🔹 Passing the label here!
                            onPressed: () => _toggleDevice(device, !isSelected),
                          );
                        },
                      )),
          ),
        ],
      ),
      // Rest of your scaffold code
    );
  }
}

Widget _buildStatusCard(
    {required IconData icon, required String value, required Color iconColor}) {
  return Container(
    width: 60,
    height: 30,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 6),
        )
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: iconColor),
        SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700)),
      ],
    ),
  );
}

Color _getTemperatureColor(double temperature) {
  if (temperature < 10) {
    return Colors.blue; // Cold
  } else if (temperature >= 10 && temperature <= 30) {
    return Colors.green; // Moderate
  } else {
    return Colors.red; // Hot
  }
}
