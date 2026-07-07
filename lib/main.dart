import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────
//  CYBERPUNK INDUSTRIAL PALETTE  —  team 1023
// ─────────────────────────────────────────────────────────────────────────
const Color kBg = Color(0xFF07080B); // near-black base
const Color kBgTop = Color(0xFF0E1118); // top of the screen wash
const Color kSurface = Color(0xFF12151C); // panel / card
const Color kSurfaceHi = Color(0xFF1A1E27); // raised panel
const Color kNeon = Color(0xFF18E0D0); // electric cyan accent
const Color kMagenta = Color(0xFFFF2BD6); // hot magenta accent
const Color kAmber = Color(0xFFFFC233); // warning amber
const Color kLine = Color(0xFF252B38); // hairline borders
const Color kTextHi = Color(0xFFE7F6F4); // primary text
const Color kTextLo = Color(0xFF8C99A8); // muted text

// Shared dark background wash used on every screen.
const BoxDecoration kScreenBg = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [kBgTop, kBg],
  ),
);
/*To find backup:
  first time on device
    go to files
    three dots in top right
    show internal storage
  Every time
    go to (divice name)/android/data/com.example.scouting_app/files*/

//use to format data: https://docs.google.com/spreadsheets/d/1iNFZfvdpcp4n5n6IF6cnOiV0ktBfgCo4h3O141TNBsE/edit?gid=0#gid=0
List red1 = [
'858','9671','7809','7808','4325','6081','5166','2771','4325','10181','2075','7221','11399','7809','10181','904','7289','9206','5166','9685','7658','8285','7221','5980','8767','7808','2075','7289','9638','10664','10181','5980','7808','7220','7818','9206','7658','8767','10664','4325','3620','10642','9566','8423','9671','10664','3234','858','10642','5256','8423','7656','7818','9566','9685','9756','3875','904','9685','4967','2075','9549','3875','6081','7289','9549','10664','10633','10642','9638','7818','9756','3875','9208','5256','904','2771','1023','3302','6610',];

List red2 = [
'10181','9756','9208','9549','2075','904','5256','9671','7220','7818','1023','8423','5166','3875','3234','2075','10664','11399','9756','7256','858','5256','9671','4325','9638','10633','5256','9208','7656','9566','1023','9549','6081','3620','2771','5980','7221','10633','904','7289','7658','858','7809','4967','7656','7808','7221','5166','3875','7808','8285','8767','4967','858','1023','9208','5166','5980','7656','3620','9671','7220','2771','3234','8767','9206','4325','8285','11399','8423','7809','8767','7256','9549','7658','7809','9685','8423','11457','3707',];

List red3 = [
'8285','7658','3234','3875','7221','9566','3620','10642','4967','6081','5980','9566','10664','7658','4967','7818','10633','6081','10642','7809','7818','9549','10181','11399','904','7256','3875','7221','3620','3234','904','9756','7289','2075','7656','3234','9638','11399','9756','9685','6081','8767','8285','9206','5256','2771','9685','4967','1023','5980','10664','7256','7221','3620','9206','7256','9671','7220','10633','9208','8423','9638','10633','5166','10181','9671','7656','1023','7220','7808','7289','9566','4325','5166','7220','9206','9638','8767','11462','7225',];

List blue1 = [
'3620','7220','10642','8767','4967','1023','8423','9206','7809','9638','7289','904','5256','858','8285','8423','5256','3620','7656','7220','2075','9206','7656','1023','3620','2771','6081','7658','9671','8767','10633','858','4967','9208','4325','9685','7809','7256','5166','9208','1023','7221','10633','7256','3875','9756','9566','9208','11399','9671','7220','9549','3234','10181','9638','7658','9549','8285','7808','7256','9566','8285','5980','11399','7818','7256','5980','6081','5166','2771','3234','4967','7221','10633','3234','9756','11399','7656','11486','4362',];

List blue2 = [
'7256','9685','7656','7818','10633','7289','7256','9756','9549','858','8285','7808','9685','2771','4325','5980','9638','7808','7221','3875','10664','9566','6081','5166','9685','3234','4967','9206','7220','2771','8423','11399','10642','9566','1023','10181','10642','9671','8285','10181','3234','7220','7818','9638','11399','2075','10633','9206','9638','3620','9756','7658','2075','10642','10664','8767','7289','6081','9206','10664','4325','904','7658','7809','5256','9566','7221','3875','10181','9208','904','5980','6081','10642','7818','3620','4967','7289','67','6566',];

List blue3 = [
'2771','10664','9206','5980','9638','11399','7658','3875','10633','9208','3234','7656','8767','9549','9671','9208','9566','8767','1023','8423','4967','7289','9208','7220','10642','9756','7809','8285','7818','5166','4325','9685','7256','3875','5256','9549','8423','858','7808','2075','9549','2771','5166','5980','904','7289','10181','4325','7818','7809','6081','904','11399','5256','7809','4325','8423','2771','858','1023','10642','7221','7656','7808','9756','2075','3620','9685','7658','5256','858','8285','10664','2075','7808','10181','9671','858','308','10285',];

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
    final darkText = ThemeData(brightness: Brightness.dark).textTheme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        canvasColor: kBg,
        cardColor: kSurface,
        dividerColor: kLine,
        colorScheme: const ColorScheme.dark(
          primary: kNeon,
          secondary: kMagenta,
          surface: kSurface,
          onPrimary: Color(0xFF03110F),
          onSecondary: Color(0xFF1A0016),
          onSurface: kTextHi,
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(darkText)
            .apply(bodyColor: kTextHi, displayColor: kTextHi),
        iconTheme: const IconThemeData(color: kTextHi),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: kSurfaceHi,
          contentTextStyle: TextStyle(color: kTextHi),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurfaceHi,
          labelStyle: const TextStyle(color: kTextLo),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: kNeon, width: 2),
          ),
        ),
      ),
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

  final List<List<dynamic>> _rows = [];

  void addRow(List<dynamic> row) => _rows.add(row);

  bool get hasData => _rows.isNotEmpty;

  int get rowCount => _rows.length;

  /// Serialize everything to UTF-8 CSV bytes.
  /// Returns null if there are no rows.
  List<int>? toBytes() {
    if (_rows.isEmpty) return null;

    final rows = <List<dynamic>>[
      ScoutData.getHeaders(),
      ..._rows,
    ];

    final csvString = const ListToCsvConverter().convert(rows);
    return utf8.encode(csvString);
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

  List<dynamic> toRow() {
    return [
      initials,
      matchNumber,
      teamNumber,
      alliance,
      autoFuelScored,
      autoFuelFed,
      climb ? 1 : 0,
      pickupLocations.join(', '),
      teleopFuelScored,
      teleopFuelFed,
      defense,
      levelValues.elementAt(levels.indexOf(climbLevel)),
      broke ? 1 : 0,
      permanentlyImmobilized ? 1 : 0,
      temporarilyImmobilized ? 1 : 0,
      wasDefended ? 1 : 0,
      robotRoles.join(', '),
      notes,
    ];
  }

  static List<dynamic> getHeaders() {
    return [
      'Initials',
      'Match',
      'Team',
      'Alliance',
      'A Fuel Scored',
      'A Fuel Fed',
      'Climb',
      'Pick up location?',
      'T Fuel Scored',
      'T Fuel Fed',
      'Defense',
      'Climb Level',
      'Broke',
      'Permanently Immobilized',
      'Temporarily Immobilized',
      'Was defended',
      'Robot Role',
      'notes',
    ];
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future<void> _exportData() async {
    final password = await _showPasswordDialog('Export to USB');
    if (password != 'strategy1023') return;

    bool progressOpen = false;
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
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to serialize data (no bytes)'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      final alliance = _SignInPageState._savedAlliance ?? 'Unknown';
      final match = _SignInPageState._savedMatch;

      // Readable, sortable filename: team + position + match + timestamp.
      String two(int n) => n.toString().padLeft(2, '0');
      final now = DateTime.now();
      final stamp =
          '${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}${two(now.minute)}';
      final baseName = 'Scout1023_${alliance}_m${match}_$stamp';
      final rowCount = ScoutStore.instance.rowCount;

      // Blocking "writing in progress" indicator so scouts know NOT to pull
      // the drive yet. It stays up until the transfer actually finishes.
      if (mounted) {
        progressOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Saving to USB…\nDo NOT remove the drive.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // 1) GUARANTEED, VERIFIED on-device copy. Write with an explicit flush,
      //    then read the file length back off disk to confirm every byte
      //    actually landed. This copy is the source of truth for "did the
      //    export work" — it cannot be lost to a half-finished USB write.
      String savedPath = '';
      int verifiedBytes = 0;
      try {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final file = File('${dir.path}/$baseName.csv');
          await file.writeAsBytes(bytes, flush: true);
          verifiedBytes = await file.length(); // read back = proof on disk
          savedPath = file.path;
        }
      } catch (_) {}

      // If the guaranteed copy did not verify byte-for-byte, do NOT claim
      // success. The in-memory data is untouched, so the scout can retry.
      if (verifiedBytes != bytes.length) {
        if (progressOpen && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          progressOpen = false;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Save NOT verified ($verifiedBytes of ${bytes.length} bytes). '
                'Your data is still in the app — tap Export again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ));
        }
        return;
      }

      /*To find backup:
        first time on device
          go to files
          three dots in top right
          show internal storage
        Every time
        go to (divice name)/android/data/com.example.scouting_app/files*/
      // 2) Best-effort copies via FileSaver: an internal backup and the USB
      //    picker. Android's picker write to a removable drive cannot be
      //    force-flushed from Dart, so the VERIFIED copy above is the guarantee.
      await FileSaver.instance.saveFile(
        name: '${baseName}_backup',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      await FileSaver.instance.saveAs(
        name: baseName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );

      // Tear down the "saving" spinner.
      if (progressOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressOpen = false;
      }

      // Hold "do NOT remove" for a few seconds with a live countdown so the
      // USB write has time to flush before we ever say it is safe to unplug.
      // (Android's removable-drive write cannot be force-flushed from Dart.)
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _SafeRemoveCountdown(seconds: 10),
        );
      }

      // Confirmation. The on-device copy is VERIFIED; the USB copy is best
      // effort, so we tell the scout exactly how to be 100% sure.
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: kSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: kNeon, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.verified, color: kNeon, size: 28),
                SizedBox(width: 8),
                Text('SAVED & VERIFIED',
                    style: TextStyle(
                        color: kNeon,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
              ],
            ),
            content: Text(
              '$rowCount match${rowCount == 1 ? '' : 'es'}  •  $verifiedBytes bytes verified on the tablet.\n\n'
              '${savedPath.isNotEmpty ? 'Guaranteed copy on tablet:\n$savedPath\n\n' : ''}'
              'A copy was also sent to the USB drive. Before unplugging, open '
              'the USB file and check it is NOT empty. If it is empty, copy the '
              'tablet file above onto the USB with the Files app, then eject.',
              style: const TextStyle(color: kTextHi),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK',
                    style: TextStyle(
                        color: kNeon, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Make sure the progress dialog never gets stuck open on error.
      if (progressOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressOpen = false;
      }
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
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.3,
            colors: [Color(0xFF13212C), kBg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Section tag chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: kNeon.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('FRC  //  TEAM 1023',
                        style: GoogleFonts.shareTechMono(
                            fontSize: 15, color: kNeon, letterSpacing: 3)),
                  ),
                  const SizedBox(height: 26),
                  Text('BEDFORD',
                      style: GoogleFonts.orbitron(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          color: kTextHi,
                          letterSpacing: 4)),
                  Text('EXPRESS',
                      style: GoogleFonts.orbitron(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          color: kNeon,
                          letterSpacing: 4)),
                  const SizedBox(height: 12),
                  Text('SCOUTING SYSTEM',
                      style: GoogleFonts.shareTechMono(
                          fontSize: 17, color: kTextLo, letterSpacing: 6)),
                  const SizedBox(height: 14),
                  Container(width: 220, height: 2, color: kNeon.withOpacity(0.5)),
                  const SizedBox(height: 44),
                  // START SCOUTING — solid neon
                  SizedBox(
                    width: 360,
                    height: 86,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignInPage())),
                      icon: const Icon(Icons.radar, size: 30),
                      label: const Text('START SCOUTING',
                          style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeon,
                        foregroundColor: kBg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _homeOutlineButton(
                      Icons.usb, 'EXPORT TO USB', kNeon, _exportData),
                  const SizedBox(height: 14),
                  _homeOutlineButton(
                      Icons.delete_forever, 'CLEAR CACHE', kMagenta, _clearCache),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _homeOutlineButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 360,
      height: 64,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
        label: Text(label,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.7), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
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
        decoration: kScreenBg,
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
                          fillColor: kSurfaceHi,
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
                                fillColor: kSurfaceHi,
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
                                fillColor: kSurfaceHi,
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
        decoration: kScreenBg,
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
          ? const Color(0xFF2A1217)
          : const Color(0xFF0F1D2C),
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
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 14,
                color: kTextLo,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
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
        decoration: kScreenBg,
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
          ? const Color(0xFF2A1217)
          : const Color(0xFF0F1D2C),
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
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 14,
                color: kTextLo,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
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
        decoration: kScreenBg,
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
                          fillColor: kSurfaceHi,
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
                color: kSurface,
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
          ? const Color(0xFF2A1217)
          : const Color(0xFF0F1D2C),
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
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 14,
                color: kTextLo,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
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
            const Text('CLIMB LEVEL',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: kNeon)),
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
                      color: isSelected ? kNeon : kSurfaceHi,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: isSelected ? kNeon : kLine,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Center(
                      child: Text(level,
                          style: TextStyle(
                              fontSize: level == 'Failed' ? 16 : 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? kBg : kTextHi)),
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
      color: value ? color.withOpacity(0.22) : kSurfaceHi,
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
                  color: value ? color : kTextHi,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: value ? color : kLine,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value ? 'YES' : 'NO',
                  style: TextStyle(
                    color: value ? Colors.white : kTextLo,
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

// ───────────────────────────────────────────────────────────────────────────
// "Finalizing USB write" dialog: counts down so the removable-drive write has
// time to flush, and the scout can see it is still working (not frozen). It
// auto-closes when the countdown reaches zero.
// ───────────────────────────────────────────────────────────────────────────
class _SafeRemoveCountdown extends StatefulWidget {
  final int seconds;
  const _SafeRemoveCountdown({required this.seconds});

  @override
  State<_SafeRemoveCountdown> createState() => _SafeRemoveCountdownState();
}

class _SafeRemoveCountdownState extends State<_SafeRemoveCountdown> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(strokeWidth: 5),
                ),
                Text('$_remaining',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Finishing the USB write…\nDo NOT remove the drive yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ],
      ),
    );
  }
}
