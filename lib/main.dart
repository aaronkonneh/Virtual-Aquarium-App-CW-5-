import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aaron Konneh Virtual Aquarium',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Database _database;
  List<Fish> fishList = [];
  Color selectedColor = Colors.green;
  double selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this)
      ..addListener(() {
        setState(() {
          fishList.forEach((fish) {
            fish.updatePosition();
          });
        });
      });
    _controller.repeat();
    _initDatabase();
    _loadSettings();
  }

  Future<void> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'aquarium_settings.db');
    _database = await openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE settings (id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color TEXT)');
    });
  }

  Future<void> _loadSettings() async {
    List<Map> settings = await _database.query('settings');
    if (settings.isNotEmpty) {
      setState(() {
        selectedSpeed = settings[0]['speed'];
        selectedColor = Color(int.parse(settings[0]['color']));
        int fishCount = settings[0]['fishCount'];
        for (int i = 0; i < fishCount; i++) {
          _addFish();
        }
      });
    }
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  void _saveSettings() async {
    await _database.delete('settings');
    await _database.insert('settings', {
      'fishCount': fishList.length,
      'speed': selectedSpeed,
      'color': selectedColor.value
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aaron Konneh Virtual Aquarium')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.blue,
                ),
                ...fishList.map((fish) => fish.buildFish()),
                Positioned(
                  bottom: 50,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: _addFish,
                    child: Text('Add Fish'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _saveSettings();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Settings saved')));
                  },
                  child: Text('Save Settings'),
                ),
                SizedBox(height: 20),
                Text('Speed'),
                Slider(
                  min: 0.1,
                  max: 10.0,
                  value: selectedSpeed,
                  onChanged: (value) {
                    setState(() {
                      selectedSpeed = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                Text('Color'),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: [
                    DropdownMenuItem(
                        child:
                            Container(color: Colors.red, width: 20, height: 20),
                        value: Colors.red),
                    DropdownMenuItem(
                        child: Container(
                            color: Colors.green, width: 20, height: 20),
                        value: Colors.green),
                    DropdownMenuItem(
                        child: Container(
                            color: Colors.blue, width: 20, height: 20),
                        value: Colors.blue),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedColor = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Fish {
  Color color;
  double speed;
  double x = Random().nextDouble() * 250;
  double y = Random().nextDouble() * 250;
  double dx = Random().nextBool() ? 1 : -1;
  double dy = Random().nextBool() ? 1 : -1;
  double angle = 0;

  Fish({required this.color, required this.speed});

  void updatePosition() {
    x += dx * speed;
    y += dy * speed;

    if (x <= 0 || x >= 280) {
      dx = -dx;
      angle += 3.14;
    }
    if (y <= 0 || y >= 280) {
      dy = -dy;
      angle += 3.14;
    }
  }

  Widget buildFish() {
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(
          size: Size(20, 20),
          painter: FishPainter(color),
        ),
      ),
    );
  }
}

class FishPainter extends CustomPainter {
  final Color color;

  FishPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
