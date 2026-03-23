import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

//use to format data: https://docs.google.com/spreadsheets/d/1iNFZfvdpcp4n5n6IF6cnOiV0ktBfgCo4h3O141TNBsE/edit?gid=0#gid=0
List red1 = [
'10285','3538','11486','830','7491','8426','5066','8424','5053','7491','5674','5067','10652','5114','830','5053','7553','2145','308','5674','4362','5067','11457','314','8424','5114','8423','7225','8424','7660','1023','308','4384','5695','1023','11462','7178','10612','308','6615','11462','8424','3707','5695','6078','2145','6566','67','10652','314','7225','3538','2137','6615','67','4362','4384','5114','6078','830','7553','3707','6078','3302','7762','314','10612','6610','7553','11457','3302','7762','2137','11486','4384','11473','7762','8426','3302','6610',
];

List red2 = [
'1023','10612','7225','3302','7178','5067','67','7225','4737','8426','6610','308','11462','6078','6615','7762','1023','7178','11457','8423','3538','5053','5695','10612','6566','67','7491','548','6615','7553','11473','5066','5674','10285','10652','11473','4737','11486','5114','5053','6610','7491','4384','3538','2137','314','11486','4362','3302','8423','10285','548','5066','8426','6566','2145','5067','11462','7660','548','5674','3538','2145','548','4384','2137','5067','10652','8423','7660','8424','10285','4362','6615','3538','5066','1023','2137','11457','3707',
];

List red3 = [
'8423','11462','6078','4362','308','7762','6610','4362','10612','11486','314','11473','7553','8426','314','3707','7491','67','4737','10652','1023','6078','3707','548','6610','7660','3538','5053','11462','6610','6566','8423','7491','830','7660','67','5067','2145','4384','3302','10285','4737','11473','6615','7762','7225','3707','5695','4737','7178','11457','11473','11486','7553','11457','10652','2137','7491','5066','8426','10285','5114','5695','5066','4362','7660','1023','5114','6566','7178','10612','308','3707','5674','7178','2145','830','8424','11462','7225',
];

List blue1 = [
'4737','6615','5695','7660','5053','11473','3707','5695','6078','7660','3538','10285','2145','8423','548','3538','5066','11462','11473','2137','7762','8426','830','10285','6615','7178','11473','11457','10652','67','5067','5114','3707','2137','11457','4362','6610','7491','6566','8423','7660','7178','10652','548','5674','8426','5066','7491','7553','5674','6566','4384','1023','10612','8423','10285','4737','3302','308','1023','11486','5067','6610','7178','6566','7225','2145','5053','548','5066','4737','67','11462','7225','10612','4737','314','548','11486','4362',
];

List blue2 = [
'4384','5114','314','5674','2137','10652','7553','4384','830','7762','11457','3707','1023','4362','6566','3302','10285','5695','5114','6610','5066','7225','11462','2145','308','5674','830','4362','6078','314','11486','7178','4737','7553','8424','8426','7762','3707','7225','5695','830','7553','10612','308','3302','8423','8424','5067','5114','308','2145','7660','6610','3707','7762','5053','11486','11473','10612','7178','11457','67','7491','830','11462','4737','8424','11473','6078','6615','8426','7491','314','10652','6078','7660','5053','5695','67','6566',
];

List blue3 = [
'67','548','8424','2145','6566','11457','548','3302','6566','6615','5066','7178','2137','11486','4384','7660','5067','7225','8424','10612','7553','4384','4737','3302','10652','2137','11486','10612','10285','8426','3302','7762','2145','3538','6078','5066','548','314','5674','2137','5067','4362','67','1023','5114','11457','5053','6615','830','11462','7762','5053','6078','5674','8424','3538','6610','314','5695','7225','5053','8423','11473','10652','8426','6615','308','5695','5674','4384','3538','830','1023','5067','7553','8423','5114','7491','308','10285',
];

int index = 0;
final levels = ['None', 'Failed', 'L1', 'L2', 'L3'];
final levelValues = ['-0', '0', '10', '20', '30'];

  String notes = "";

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

// ---------------------------------------------------------------------------
// In-memory store — all rows live here; we only touch the file at export time
// ---------------------------------------------------------------------------
class ScoutStore {
  ScoutStore._();
  static final ScoutStore instance = ScoutStore._();

  final List<List<excel.CellValue>> _rows = [];

  void addRow(List<excel.CellValue> row) => _rows.add(row);

  bool get hasData => _rows.isNotEmpty;

  /// Serialize everything to xlsx bytes exactly once.
  /// Returns null if there are no rows.
  List<int>? toBytes() {
    if (_rows.isEmpty) return null;

    final excelFile = excel.Excel.createExcel();

    // createExcel() always creates a default sheet – rename it cleanly.
    final sheetName = 'Sheet1';
    excelFile.rename(excelFile.getDefaultSheet()!, sheetName);
    final sheet = excelFile[sheetName];

    sheet.appendRow(ScoutData.getHeaders());
    for (final row in _rows) {
      sheet.appendRow(row);
    }

    final bytes = excelFile.save();
    return bytes;
  }

  void clear() => _rows.clear();
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
      excel.TextCellValue(climb ? '1' : '0'),
      excel.TextCellValue(pickupLocations.join(', ')),
      excel.IntCellValue(teleopFuelScored),
      excel.IntCellValue(teleopFuelFed),
      excel.IntCellValue(defense),
      excel.TextCellValue(levelValues.elementAt(levels.indexOf(climbLevel))),
      excel.TextCellValue(broke ? '1' : '0'),
      excel.TextCellValue(permanentlyImmobilized ? '1' : '0'),
      excel.TextCellValue(temporarilyImmobilized ? '1' : '0'),
      excel.TextCellValue(wasDefended ? '1' : '0'),
      excel.TextCellValue(robotRoles.join(', ')),
      excel.TextCellValue(notes),
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
      excel.TextCellValue('notes'),
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
      if (!ScoutStore.instance.hasData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export')),
          );
        }
        return;
      }

      final bytes = ScoutStore.instance.toBytes();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to serialize data'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      final alliance = _SignInPageState._savedAlliance ?? 'Unknown';
      final match = _SignInPageState._savedMatch;
      await FileSaver.instance.saveAs(
        name: alliance+'_'+match,
        bytes: Uint8List.fromList(bytes),
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
      ScoutStore.instance.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cache cleared!'), backgroundColor: Colors.orange),
        );
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
    _alliance = _savedAlliance;
    if (_savedAlliance == 'Red1') {
      _teamController =
          TextEditingController(text: red1.elementAtOrNull(index));
    } else if (_savedAlliance == 'Red2') {
      _teamController =
          TextEditingController(text: red2.elementAtOrNull(index));
    } else if (_savedAlliance == 'Red3') {
      _teamController =
          TextEditingController(text: red3.elementAtOrNull(index));
    } else if (_savedAlliance == 'Blue1') {
      _teamController =
          TextEditingController(text: blue1.elementAtOrNull(index));
    } else if (_savedAlliance == 'Blue2') {
      _teamController =
          TextEditingController(text: blue2.elementAtOrNull(index));
    } else if (_savedAlliance == 'Blue3') {
      _teamController =
          TextEditingController(text: blue3.elementAtOrNull(index));
    } else {
      _teamController = TextEditingController();
    }
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
                                'Red1', Colors.red.shade700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildAllianceButton(
                                'Red2', Colors.red.shade700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildAllianceButton(
                                'Red3', Colors.red.shade700),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildAllianceButton(
                                'Blue1', Colors.blue.shade700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildAllianceButton(
                                'Blue2', Colors.blue.shade700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildAllianceButton(
                                'Blue3', Colors.blue.shade700),
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
    if (matchNumber == null || matchNumber < 1) {
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
      color: widget.data.alliance.startsWith('Red')
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
            CheckboxListTile(
              title:
                  const Text('Alliance Zone', style: TextStyle(fontSize: 20)),
              value: widget.data.pickupLocations.contains('Alliance Zone'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    widget.data.pickupLocations.add('Alliance Zone');
                  } else {
                    widget.data.pickupLocations.remove('Alliance Zone');
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
                      _buildCounter('Defense', widget.data.defense, (val) {
                        setState(() => widget.data.defense = val);
                      }, const Color.fromARGB(255, 217, 10, 172)),
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
      color: widget.data.alliance.startsWith('Red')
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
                Row(
                  children: [
                    _counterButton('-1', () {
                      if (value >= 1) onChanged(value - 1);
                    }, Colors.red.shade700),
                  ],
                ),
                const SizedBox(width: 50),
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
                Row(
                  children: [
                    _counterButton('+1', () => onChanged(value + 1),
                        Colors.green.shade700),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

  Widget _counterButton(String label, VoidCallback onPressed, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 400,
          height: 100,
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
          height: 100,
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
    late TextEditingController _notes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
  }

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
                      const SizedBox(height: 20),
                      TextField(
                        controller: _notes,
                        decoration: InputDecoration(
                          labelText: 'notes',
                          labelStyle: const TextStyle(fontSize: 20),
                          prefixIcon: const Icon(Icons.note, size: 30),
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

//TODO

  Widget _buildInfoCard() {
    return Card(
      elevation: 5,
      color: widget.data.alliance.startsWith('Red')
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

  // -------------------------------------------------------------------------
  // Submit: just push the row into memory — no file I/O at all.
  // -------------------------------------------------------------------------
  Future<void> _saveData() async {
    setState(() => _isSubmitting = true);
    notes = _notes.text;

    try {
      ScoutStore.instance.addRow(widget.data.toRow());

      // Advance match number and match-list index for the next entry.
      _SignInPageState._savedMatch = (widget.data.matchNumber + 1).toString();
      index = widget.data.matchNumber;

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
