import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

// Data Model
class ScoutData {
  String initials;
  String matchNumber;
  String teamNumber;
  String alliance;

  // Autonomous
  int autoFuelScored = 0;
  bool autoTowerLevel1 = false;
  bool autoLeftStartingZone = false;
  String autoNotes = '';

  // Teleop
  int teleopFuelScored = 0;
  int teleopFuelMissed = 0;
  bool crossedBarriers = false;
  int defenseRating = 0;
  String teleopNotes = '';

  // Endgame
  int towerLevel = 0;
  bool parked = false;
  bool harmonyBonus = false;
  int foulCount = 0;
  bool robotBroke = false;
  String endgameNotes = '';

  ScoutData({
    required this.initials,
    required this.matchNumber,
    required this.teamNumber,
    required this.alliance,
  });

  List<excel.CellValue> toRow() {
    return [
      excel.TextCellValue(initials),
      excel.TextCellValue(matchNumber),
      excel.TextCellValue(teamNumber),
      excel.TextCellValue(alliance),
      excel.IntCellValue(autoFuelScored),
      excel.TextCellValue(autoTowerLevel1 ? 'Yes' : 'No'),
      excel.TextCellValue(autoLeftStartingZone ? 'Yes' : 'No'),
      excel.TextCellValue(autoNotes),
      excel.IntCellValue(teleopFuelScored),
      excel.IntCellValue(teleopFuelMissed),
      excel.TextCellValue(crossedBarriers ? 'Yes' : 'No'),
      excel.IntCellValue(defenseRating),
      excel.TextCellValue(teleopNotes),
      excel.IntCellValue(towerLevel),
      excel.TextCellValue(parked ? 'Yes' : 'No'),
      excel.TextCellValue(harmonyBonus ? 'Yes' : 'No'),
      excel.IntCellValue(foulCount),
      excel.TextCellValue(robotBroke ? 'Yes' : 'No'),
      excel.TextCellValue(endgameNotes),
      excel.TextCellValue(DateTime.now().toIso8601String().substring(0, 19)),
    ];
  }

  static List<excel.CellValue> getHeaders() {
    return [
      excel.TextCellValue('Initials'),
      excel.TextCellValue('Match'),
      excel.TextCellValue('Team'),
      excel.TextCellValue('Alliance'),
      excel.TextCellValue('Auto Fuel'),
      excel.TextCellValue('Auto Tower L1'),
      excel.TextCellValue('Auto Left Zone'),
      excel.TextCellValue('Auto Notes'),
      excel.TextCellValue('Teleop Fuel'),
      excel.TextCellValue('Teleop Missed'),
      excel.TextCellValue('Crossed Barriers'),
      excel.TextCellValue('Defense (0-5)'),
      excel.TextCellValue('Teleop Notes'),
      excel.TextCellValue('Tower Level'),
      excel.TextCellValue('Parked'),
      excel.TextCellValue('Harmony'),
      excel.TextCellValue('Fouls'),
      excel.TextCellValue('Robot Broke'),
      excel.TextCellValue('Endgame Notes'),
      excel.TextCellValue('Timestamp'),
    ];
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _fileName = 'BEDFORD_SCOUT_V12.xlsx';

  Future<void> _exportData() async {
    final password = await _showPasswordDialog('Export to USB');
    if (password != 'strategy1023') return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');

      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export')),
          );
        }
        return;
      }

      var bytes = await file.readAsBytes();

      await FileSaver.instance.saveAs(
        name: 'BedfordScout_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Exported successfully!'),
              backgroundColor: Color.fromARGB(255, 254, 60, 60)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final password = await _showPasswordDialog('Clear Cache');
    if (password != 'strategy1023') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Clear Cache'),
        content:
            const Text('This will delete all stored match data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_fileName');
        if (await file.exists()) {
          await file.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cache cleared!'),
                backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<String?> _showPasswordDialog(String action) async {
    final passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action - Password Required'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final password = passwordController.text;
              Navigator.pop(context, password);
              if (password != 'strategy1023') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Incorrect password'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 255, 230, 230),
                  Color.fromARGB(255, 234, 213, 213),
                  Color.fromARGB(255, 255, 213, 213)
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bedford Express',
                          style: GoogleFonts.libreFranklin(
                            fontSize: 67,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 211, 23, 23),
                          )),
                      const SizedBox(height: 20),

                      const SizedBox(height: 50),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(350, 90),
                          backgroundColor:
                              const Color.fromARGB(255, 211, 23, 23),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignInPage())),
                        child: const Text('START SCOUTING',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 40),
                      // Export to USB Button
                      SizedBox(
                        width: 350,
                        height: 70,
                        child: OutlinedButton.icon(
                          onPressed: _exportData,
                          icon: const Icon(Icons.usb, size: 28),
                          label: const Text('EXPORT TO USB',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(255, 255, 0, 0),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 211, 23, 23),
                                width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Clear Cache Button
                      SizedBox(
                        width: 350,
                        height: 70,
                        child: OutlinedButton.icon(
                          onPressed: _clearCache,
                          icon: const Icon(Icons.delete_forever, size: 28),
                          label: const Text('CLEAR CACHE',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(255, 255, 0, 0),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 211, 23, 23),
                                width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                        ),
                      ),
                    ]),
              ),
            )));
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _initialsController = TextEditingController();
  final _matchController = TextEditingController();
  final _teamController = TextEditingController();
  String? _alliance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In', style: TextStyle(fontSize: 28)),
        backgroundColor: const Color.fromARGB(255, 248, 152, 43),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 255, 200, 154), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      TextField(
                        controller: _initialsController,
                        decoration: InputDecoration(
                          labelText: 'Scouter Initials',
                          labelStyle: const TextStyle(fontSize: 20),
                          prefixIcon: const Icon(Icons.person, size: 30),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                                color: Color.fromARGB(255, 248, 152, 43)),
                          ),
                        ),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _matchController,
                              decoration: InputDecoration(
                                labelText: 'Match #',
                                labelStyle: const TextStyle(fontSize: 20),
                                prefixIcon: const Icon(Icons.numbers, size: 30),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              style: const TextStyle(fontSize: 22),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextField(
                              controller: _teamController,
                              decoration: InputDecoration(
                                labelText: 'Team #',
                                labelStyle: const TextStyle(fontSize: 20),
                                prefixIcon: const Icon(Icons.groups, size: 30),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              style: const TextStyle(fontSize: 22),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text('Select Alliance',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAllianceButton(
                                'Red', Colors.red.shade700),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildAllianceButton(
                                'Blue', Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 28),
                      label: const Text('BACK',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 248, 152, 43),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _navigateToAuto,
                      label: const Text('NEXT',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      icon: const Icon(Icons.arrow_forward, size: 28),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 248, 152, 43),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllianceButton(String alliance, Color color) {
    final isSelected = _alliance == alliance;
    return GestureDetector(
      onTap: () => setState(() => _alliance = alliance),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isSelected ? 4 : 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ]
              : [],
        ),
        child: Center(
          child: Text(alliance.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _navigateToAuto() {
    if (_initialsController.text.isEmpty ||
        _matchController.text.isEmpty ||
        _teamController.text.isEmpty ||
        _alliance == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all fields and select alliance')));
      return;
    }

    final scoutData = ScoutData(
      initials: _initialsController.text,
      matchNumber: _matchController.text,
      teamNumber: _teamController.text,
      alliance: _alliance!,
    );

    Navigator.push(context,
        MaterialPageRoute(builder: (_) => AutonomousPage(data: scoutData)));
  }
}

class AutonomousPage extends StatefulWidget {
  final ScoutData data;
  const AutonomousPage({super.key, required this.data});
  @override
  State<AutonomousPage> createState() => _AutonomousPageState();
}

class _AutonomousPageState extends State<AutonomousPage> {
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous', style: TextStyle(fontSize: 28)),
        backgroundColor: const Color.fromARGB(255, 244, 212, 72),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 250, 240, 168), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildCounter('Fuel Scored', widget.data.autoFuelScored,
                          (val) {
                        setState(() => widget.data.autoFuelScored = val);
                      }, const Color.fromARGB(255, 244, 212, 72)),
                      const SizedBox(height: 20),
                      _buildToggle('Tower Level 1', widget.data.autoTowerLevel1,
                          (val) {
                        setState(() => widget.data.autoTowerLevel1 = val);
                      }, Icons.stairs),
                      const SizedBox(height: 20),
                      _buildToggle('Left Starting Zone',
                          widget.data.autoLeftStartingZone, (val) {
                        setState(() => widget.data.autoLeftStartingZone = val);
                      }, Icons.directions_run),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              _buildNavButtons(() => Navigator.pop(context), () {
                widget.data.autoNotes = _notesController.text;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TeleopPage(data: widget.data)));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 5,
      color: widget.data.alliance == 'Red'
          ? Colors.red.shade100
          : Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoItem('Team', widget.data.teamNumber),
            _infoItem('Match', widget.data.matchNumber),
            _infoItem('Alliance', widget.data.alliance),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCounter(
      String title, int value, Function(int) onChanged, Color color) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _counterButton(Icons.remove, () {
                  if (value > 0) onChanged(value - 1);
                }, Colors.red),
                const SizedBox(width: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(value.toString(),
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ),
                const SizedBox(width: 40),
                _counterButton(
                    Icons.add, () => onChanged(value + 1), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onPressed, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Icon(icon, color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildToggle(
      String title, bool value, Function(bool) onChanged, IconData icon) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: value ? Colors.green : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold))),
              Transform.scale(
                scale: 1.5,
                child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons(VoidCallback onBack, VoidCallback onNext) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 28),
            label: const Text('BACK',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 244, 212, 72),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onNext,
            label: const Text('NEXT',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.arrow_forward, size: 28),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 244, 212, 72),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class TeleopPage extends StatefulWidget {
  final ScoutData data;
  const TeleopPage({super.key, required this.data});
  @override
  State<TeleopPage> createState() => _TeleopPageState();
}

class _TeleopPageState extends State<TeleopPage> {
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teleop', style: TextStyle(fontSize: 28)),
        backgroundColor: const Color.fromARGB(255, 16, 147, 47),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 199, 233, 197), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildCounter('Fuel Scored', widget.data.teleopFuelScored,
                          (val) {
                        setState(() => widget.data.teleopFuelScored = val);
                      }, Colors.green),
                      const SizedBox(height: 20),
                      _buildCounter('Fuel Missed', widget.data.teleopFuelMissed,
                          (val) {
                        setState(() => widget.data.teleopFuelMissed = val);
                      }, Colors.red),
                      const SizedBox(height: 20),
                      _buildToggle(
                          'Crossed Barriers', widget.data.crossedBarriers,
                          (val) {
                        setState(() => widget.data.crossedBarriers = val);
                      }, Icons.terrain),
                      const SizedBox(height: 20),
                      _buildDefenseRating(),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              _buildNavButtons(() => Navigator.pop(context), () {
                widget.data.teleopNotes = _notesController.text;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EndgamePage(data: widget.data)));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 5,
      color: widget.data.alliance == 'Red'
          ? Colors.red.shade100
          // APPEND THIS TO THE END OF THE PREVIOUS CODE
// Starting from where _buildInfoCard() in TeleopPage was cut off:

          : Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoItem('Team', widget.data.teamNumber),
            _infoItem('Match', widget.data.matchNumber),
            _infoItem('Alliance', widget.data.alliance),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCounter(
      String title, int value, Function(int) onChanged, Color color) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _counterButton(Icons.remove, () {
                  if (value > 0) onChanged(value - 1);
                }, Colors.red),
                const SizedBox(width: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(value.toString(),
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ),
                const SizedBox(width: 40),
                _counterButton(
                    Icons.add, () => onChanged(value + 1), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onPressed, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Icon(icon, color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildToggle(
      String title, bool value, Function(bool) onChanged, IconData icon) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: value ? Colors.green : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold))),
              Transform.scale(
                scale: 1.5,
                child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefenseRating() {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Defense Rating',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final isSelected = widget.data.defenseRating == index;
                return GestureDetector(
                  onTap: () =>
                      setState(() => widget.data.defenseRating = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.deepOrange : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.deepOrange, width: isSelected ? 3 : 1),
                    ),
                    child: Center(
                      child: Text(index.toString(),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.white : Colors.black87)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text('0 = No Defense | 5 = Excellent Defense',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButtons(VoidCallback onBack, VoidCallback onNext) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 28),
            label: const Text('BACK',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onNext,
            label: const Text('NEXT',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.arrow_forward, size: 28),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ENDGAME PAGE
class EndgamePage extends StatefulWidget {
  final ScoutData data;
  const EndgamePage({super.key, required this.data});
  @override
  State<EndgamePage> createState() => _EndgamePageState();
}

class _EndgamePageState extends State<EndgamePage> {
  final _notesController = TextEditingController();
  static const String _fileName = 'BEDFORD_SCOUT_V12.xlsx';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endgame', style: TextStyle(fontSize: 28)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildTowerLevel(),
                      const SizedBox(height: 20),
                      _buildToggle('Parked', widget.data.parked, (val) {
                        setState(() => widget.data.parked = val);
                      }, Icons.local_parking),
                      const SizedBox(height: 20),
                      _buildToggle('Harmony Bonus', widget.data.harmonyBonus,
                          (val) {
                        setState(() => widget.data.harmonyBonus = val);
                      }, Icons.music_note),
                      const SizedBox(height: 20),
                      _buildCounter('Foul Count', widget.data.foulCount, (val) {
                        setState(() => widget.data.foulCount = val);
                      }, Colors.orange),
                      const SizedBox(height: 20),
                      _buildToggle('Robot Broke', widget.data.robotBroke,
                          (val) {
                        setState(() => widget.data.robotBroke = val);
                      }, Icons.build),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _saveData,
                          icon: const Icon(Icons.check_circle, size: 36),
                          label: const Text('SUBMIT',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 28),
                    label: const Text('BACK',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 5,
      color: widget.data.alliance == 'Red'
          ? Colors.red.shade100
          : Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoItem('Team', widget.data.teamNumber),
            _infoItem('Match', widget.data.matchNumber),
            _infoItem('Alliance', widget.data.alliance),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTowerLevel() {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Tower Level',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(5, (index) {
                final isSelected = widget.data.towerLevel == index;
                final label = index == 0 ? 'None' : 'L$index';
                return GestureDetector(
                  onTap: () => setState(() => widget.data.towerLevel = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.purple, width: isSelected ? 3 : 1),
                    ),
                    child: Center(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.white : Colors.black87)),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(
      String title, int value, Function(int) onChanged, Color color) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _counterButton(Icons.remove, () {
                  if (value > 0) onChanged(value - 1);
                }, Colors.red),
                const SizedBox(width: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(value.toString(),
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ),
                const SizedBox(width: 40),
                _counterButton(
                    Icons.add, () => onChanged(value + 1), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onPressed, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Icon(icon, color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildToggle(
      String title, bool value, Function(bool) onChanged, IconData icon) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: value ? Colors.green : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold))),
              Transform.scale(
                scale: 1.5,
                child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    setState(() => _isSubmitting = true);
    widget.data.endgameNotes = _notesController.text;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');

      excel.Excel excelFile;
      if (await file.exists()) {
        var bytes = await file.readAsBytes();
        excelFile = excel.Excel.decodeBytes(bytes);
      } else {
        excelFile = excel.Excel.createExcel();
      }

      excel.Sheet sheet = excelFile['Sheet1'];
      if (sheet.maxRows == 0) {
        sheet.appendRow(ScoutData.getHeaders());
      }

      sheet.appendRow(widget.data.toRow());

      var fileBytes = excelFile.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data saved successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
