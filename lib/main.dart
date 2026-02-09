import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

dynamic apiUrl =
    'https://www.thebluealliance.com/api/v3/'; //key: KpymR5pSlmnb7unCIORN3QHS0kpFA2J5KLa4znriGhtDXR5OPSuinxrhH9VyZfq5
// schedule format: 
String event_key = '2026';

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
  int matchNumber;
  String teamNumber;
  String alliance;

  // Autonomous
  int autoFuelScored = 0;
  int autoFuelFed = 0;
  bool climb = false;
  List<String> pickupLocations = [];

  // Teleop
  int teleopFuelScored = 0;
  int teleopFuelFed = 0;
  int defense = 0;

  // Endgame
  String climbLevel = 'None'; // None, Failed, L1, L2, L3
  bool broke = false;
  bool permanentlyImmobilized = false;
  bool temporarilyImmobilized = false;
  bool wasDefended = false;
  List<String> robotRoles = [];

  ScoutData({
    required this.initials,
    required this.matchNumber,
    required this.teamNumber,
    required this.alliance,
  });

  List<excel.CellValue> toRow() {
    return [
      excel.TextCellValue(initials),
      excel.IntCellValue(matchNumber),
      excel.TextCellValue(teamNumber),
      excel.TextCellValue(alliance),
      excel.IntCellValue(autoFuelScored),
      excel.IntCellValue(autoFuelFed),
      excel.TextCellValue(climb ? 'Yes' : 'No'),
      excel.TextCellValue(pickupLocations.join(', ')),
      excel.IntCellValue(teleopFuelScored),
      excel.IntCellValue(teleopFuelFed),
      excel.IntCellValue(defense),
      excel.TextCellValue(climbLevel),
      excel.TextCellValue(broke ? 'Yes' : 'No'),
      excel.TextCellValue(permanentlyImmobilized ? 'Yes' : 'No'),
      excel.TextCellValue(temporarilyImmobilized ? 'Yes' : 'No'),
      excel.TextCellValue(wasDefended ? 'Yes' : 'No'),
      excel.TextCellValue(robotRoles.join(', ')),
    ];
  }

  static List<excel.CellValue> getHeaders() {
    return [
      excel.TextCellValue('Initials'),
      excel.TextCellValue('Match'),
      excel.TextCellValue('Team'),
      excel.TextCellValue('Alliance'),
      excel.TextCellValue('A Fuel Scored'),
      excel.TextCellValue('A Fuel Fed'),
      excel.TextCellValue('Climb'),
      excel.TextCellValue('Pick up location?'),
      excel.TextCellValue('T Fuel Scored'),
      excel.TextCellValue('T Fuel Fed'),
      excel.TextCellValue('Defense'),
      excel.TextCellValue('Climb Level'),
      excel.TextCellValue('Broke'),
      excel.TextCellValue('Permanently Immobilized'),
      excel.TextCellValue('Temporarily Immobilized'),
      excel.TextCellValue('Was defended'),
      excel.TextCellValue('Robot Role'),
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

  //TODO: Add get match data button
  Future<http.Response> getMatchData() async {
    final response = await http.get(Uri.parse(apiUrl/'event'/event_key/'matches/simple'), 
    headers: {
      'X-TBA-Auth-Key': 'KpymR5pSlmnb7unCIORN3QHS0kpFA2J5KLa4znriGhtDXR5OPSuinxrhH9VyZfq5',
    });
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to load match data');
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
                            foregroundColor:
                                const Color.fromARGB(255, 255, 0, 0),
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
                            foregroundColor:
                                const Color.fromARGB(255, 255, 0, 0),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 211, 23, 23),
                                width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                        ),
                      ),
                      //TODO: Add get match data button
                      // const SizedBox(height: 20), 
                      // SizedBox(
                      //   width: 350,
                      //   height: 70,
                      //   child: OutlinedButton.icon(
                      //     onPressed: getMatchData,
                      //     icon: const Icon(Icons.data_usage, size: 28),
                      //     label: const Text('Get Match Data',
                      //         style: TextStyle(
                      //             fontSize: 22, fontWeight: FontWeight.bold)),
                      //     style: OutlinedButton.styleFrom(
                      //       foregroundColor:
                      //           const Color.fromARGB(255, 255, 0, 0),
                      //       side: const BorderSide(
                      //           color: Color.fromARGB(255, 211, 23, 23),
                      //           width: 2),
                      //       shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(50)),
                      //     ),
                      //   ),
                      // ),
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
  late TextEditingController _initialsController;
  late TextEditingController _matchController;
  late TextEditingController _teamController;
  String? _alliance;
  // Static variables to persist data
  static String _savedInitials = '';
  static String _savedMatch = '1';
  static String? _savedAlliance;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with saved data
    _initialsController = TextEditingController(text: _savedInitials);
    _matchController = TextEditingController(text: _savedMatch);
    _teamController = TextEditingController();
    _alliance = _savedAlliance;
  }

  @override
  void dispose() {
    _initialsController.dispose();
    _matchController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  void _saveCurrentData() {
    _savedInitials = _initialsController.text;
    _savedMatch = _matchController.text;
    _savedAlliance = _alliance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In', style: TextStyle(fontSize: 28)),
        backgroundColor: const Color.fromARGB(255, 141, 36, 221),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 219, 179, 246), Colors.white],
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
                                color: Color.fromARGB(255, 141, 36, 221)),
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
                        backgroundColor:
                            const Color.fromARGB(255, 141, 36, 221),
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
                        backgroundColor:
                            const Color.fromARGB(255, 141, 36, 221),
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

    // Parse match number as int
    final matchNumber = int.tryParse(_matchController.text);
    if (matchNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match number must be a valid number')));
      return;
    }

    // Save the current data before navigating
    _saveCurrentData();

    final scoutData = ScoutData(
      initials: _initialsController.text,
      matchNumber: matchNumber,
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous', style: TextStyle(fontSize: 28)),
        backgroundColor: const Color.fromARGB(255, 67, 51, 158),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 193, 189, 254), Colors.white],
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
                      _buildAdvancedCounter(
                          'A Fuel Scored', widget.data.autoFuelScored, (val) {
                        setState(() => widget.data.autoFuelScored = val);
                      }, const Color.fromARGB(255, 67, 51, 158)),
                      const SizedBox(height: 20),
                      _buildAdvancedCounter(
                          'A Fuel Fed', widget.data.autoFuelFed, (val) {
                        setState(() => widget.data.autoFuelFed = val);
                      }, const Color.fromARGB(255, 67, 51, 158)),
                      const SizedBox(height: 20),
                      _buildToggle('Climb', widget.data.climb, (val) {
                        setState(() => widget.data.climb = val);
                      }, Icons.hiking),
                      const SizedBox(height: 20),
                      _buildPickupLocationSelector(),
                    ],
                  ),
                ),
              ),
              _buildNavButtons(() => Navigator.pop(context), () {
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
            _infoItem('Match', widget.data.matchNumber.toString()),
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

  Widget _buildAdvancedCounter(
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
            // Main counter with MUCH BIGGER buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Subtract buttons row
                Row(
                  children: [
                    _advancedCounterButton('-10', () {
                      if (value >= 10) onChanged(value - 10);
                    }, Colors.red.shade500),
                    const SizedBox(width: 16),
                    _advancedCounterButton('-5', () {
                      if (value >= 5) onChanged(value - 5);
                    }, Colors.red.shade600),
                    const SizedBox(width: 16),
                    _advancedCounterButton('-1', () {
                      if (value >= 1) onChanged(value - 1);
                    }, Colors.red.shade700),
                  ],
                ),
                const SizedBox(width: 50),
                // Display value
                Container(
                  width: 160,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(value.toString(),
                        style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ),
                const SizedBox(width: 50),
                // Add buttons row
                Row(
                  children: [
                    _advancedCounterButton('+1', () => onChanged(value + 1),
                        Colors.green.shade700),
                    const SizedBox(width: 16),
                    _advancedCounterButton('+5', () => onChanged(value + 5),
                        Colors.green.shade600),
                    const SizedBox(width: 16),
                    _advancedCounterButton('+10', () => onChanged(value + 10),
                        Colors.green.shade500),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _advancedCounterButton(
      String label, VoidCallback onPressed, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 110,
          height: 85,
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
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

  Widget _buildPickupLocationSelector() {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pick up location?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Human Player', style: TextStyle(fontSize: 20)),
              value: widget.data.pickupLocations.contains('Human Player'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    widget.data.pickupLocations.add('Human Player');
                  } else {
                    widget.data.pickupLocations.remove('Human Player');
                  }
                });
              },
              activeColor: Colors.green,
            ),
            CheckboxListTile(
              title: const Text('Neutral Zone', style: TextStyle(fontSize: 20)),
              value: widget.data.pickupLocations.contains('Neutral Zone'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    widget.data.pickupLocations.add('Neutral Zone');
                  } else {
                    widget.data.pickupLocations.remove('Neutral Zone');
                  }
                });
              },
              activeColor: Colors.green,
            ),
            CheckboxListTile(
              title: const Text('Depot', style: TextStyle(fontSize: 20)),
              value: widget.data.pickupLocations.contains('Depot'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    widget.data.pickupLocations.add('Depot');
                  } else {
                    widget.data.pickupLocations.remove('Depot');
                  }
                });
              },
              activeColor: Colors.green,
            ),
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
              backgroundColor: const Color.fromARGB(255, 67, 51, 158),
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
              backgroundColor: const Color.fromARGB(255, 67, 51, 158),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teleop', style: TextStyle(fontSize: 28)),
        backgroundColor: const Color.fromARGB(255, 217, 10, 172),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 233, 197, 228), Colors.white],
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
                      _buildAdvancedCounter(
                          'T Fuel Scored', widget.data.teleopFuelScored, (val) {
                        setState(() => widget.data.teleopFuelScored = val);
                      }, const Color.fromARGB(255, 217, 10, 172)),
                      const SizedBox(height: 20),
                      _buildAdvancedCounter(
                          'T Fuel Fed', widget.data.teleopFuelFed, (val) {
                        setState(() => widget.data.teleopFuelFed = val);
                      }, const Color.fromARGB(255, 217, 10, 172)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                          child: _buildActionButton(
                            'Defense',
                            Icons.shield,
                            widget.data.defense,
                            const Color.fromARGB(255, 217, 10, 172),
                            () {
                              setState(() => widget.data.defense++);
                            },
                          ),
                        )
                      ])
                    ],
                  ),
                ),
              ),
              _buildNavButtons(() => Navigator.pop(context), () {
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
          : Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoItem('Team', widget.data.teamNumber),
            _infoItem('Match', widget.data.matchNumber.toString()),
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

  Widget _buildAdvancedCounter(
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
            // Main counter with MUCH BIGGER buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Subtract buttons row
                Row(
                  children: [
                    _advancedCounterButton('-10', () {
                      if (value >= 10) onChanged(value - 10);
                    }, Colors.red.shade500),
                    const SizedBox(width: 16),
                    _advancedCounterButton('-5', () {
                      if (value >= 5) onChanged(value - 5);
                    }, Colors.red.shade600),
                    const SizedBox(width: 16),
                    _advancedCounterButton('-1', () {
                      if (value >= 1) onChanged(value - 1);
                    }, Colors.red.shade700),
                  ],
                ),
                const SizedBox(width: 50),
                // Display value
                Container(
                  width: 160,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(value.toString(),
                        style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ),
                const SizedBox(width: 50),
                // Add buttons row
                Row(
                  children: [
                    _advancedCounterButton('+1', () => onChanged(value + 1),
                        Colors.green.shade700),
                    const SizedBox(width: 16),
                    _advancedCounterButton('+5', () => onChanged(value + 5),
                        Colors.green.shade600),
                    const SizedBox(width: 16),
                    _advancedCounterButton('+10', () => onChanged(value + 10),
                        Colors.green.shade500),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _advancedCounterButton(
      String label, VoidCallback onPressed, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 110,
          height: 85,
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, int count, Color color,
      VoidCallback onPressed) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 8),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
                child: Center(
                  child: Text(count.toString(),
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
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
              backgroundColor: const Color.fromARGB(255, 217, 10, 172),
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
              backgroundColor: const Color.fromARGB(255, 217, 10, 172),
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
                      _buildClimbLevel(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              'Broke',
                              Icons.heart_broken,
                              widget.data.broke,
                              Colors.red.shade700,
                              (val) => setState(() => widget.data.broke = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildToggleButton(
                              'Permanently Immobilized',
                              Icons.warning,
                              widget.data.permanentlyImmobilized,
                              Colors.orange.shade700,
                              (val) => setState(() =>
                                  widget.data.permanentlyImmobilized = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              'Temporarily Immobilized',
                              Icons.sentiment_dissatisfied,
                              widget.data.temporarilyImmobilized,
                              Colors.amber.shade700,
                              (val) => setState(() =>
                                  widget.data.temporarilyImmobilized = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildCheckbox('Was defended', widget.data.wasDefended,
                          (val) {
                        setState(() => widget.data.wasDefended = val ?? false);
                      }),
                      const SizedBox(height: 20),
                      _buildRobotRoleSelector(),
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

  Widget _buildRobotRoleSelector() {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Robot Role',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Feeder', style: TextStyle(fontSize: 20)),
              value: widget.data.robotRoles.contains('Feeder'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    widget.data.robotRoles.add('Feeder');
                  } else {
                    widget.data.robotRoles.remove('Feeder');
                  }
                });
              },
              activeColor: Colors.green,
            ),
            CheckboxListTile(
              title: const Text('Scorer', style: TextStyle(fontSize: 20)),
              value: widget.data.robotRoles.contains('Scorer'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    widget.data.robotRoles.add('Scorer');
                  } else {
                    widget.data.robotRoles.remove('Scorer');
                  }
                });
              },
              activeColor: Colors.green,
            ),
            CheckboxListTile(
              title: const Text('Defense', style: TextStyle(fontSize: 20)),
              value: widget.data.robotRoles.contains('Defense'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    widget.data.robotRoles.add('Defense');
                  } else {
                    widget.data.robotRoles.remove('Defense');
                  }
                });
              },
              activeColor: Colors.green,
            ),
          ],
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
            _infoItem('Match', widget.data.matchNumber.toString()),
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

  Widget _buildClimbLevel() {
    final levels = ['None', 'Failed', 'L1', 'L2', 'L3'];
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Climb Level',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: levels.map((level) {
                final isSelected = widget.data.climbLevel == level;
                return GestureDetector(
                  onTap: () => setState(() => widget.data.climbLevel = level),
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
                      child: Text(level,
                          style: TextStyle(
                              fontSize: level == 'Failed' ? 16 : 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.white : Colors.black87)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String title, IconData icon, bool value,
      Color color, Function(bool) onChanged) {
    return Card(
      elevation: 5,
      color: value ? color.withOpacity(0.2) : Colors.white,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 48, color: value ? color : Colors.grey),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: value ? color : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: value ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value ? 'YES' : 'NO',
                  style: TextStyle(
                    color: value ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return Card(
      elevation: 5,
      child: CheckboxListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<void> _saveData() async {
    setState(() => _isSubmitting = true);

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

      // Increment the match number for the next entry
      _SignInPageState._savedMatch = (widget.data.matchNumber + 1).toString();

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
