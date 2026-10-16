import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(const CourtOcrApp());

class CourtOcrApp extends StatelessWidget {
  const CourtOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Court OCR Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173B63)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const RegisterPage(),
    );
  }
}

class FieldSpec {
  final String column;
  final String label;
  final String hint;
  const FieldSpec(this.column, this.label, [this.hint = '']);
}

const fieldSpecs = <FieldSpec>[
  FieldSpec('A', 'SR NO'),
  FieldSpec('B', 'REGISTER NO'),
  FieldSpec('C', 'RECIPT DATE (DD/MM/YYYY)'),
  FieldSpec('D', 'MONTH/YEAR (receipt date)'),
  FieldSpec('E', 'FIR'),
  FieldSpec('F', 'US'),
  FieldSpec('G', 'PS'),
  FieldSpec('H', 'ORDER'),
  FieldSpec('I', 'COURT NAME'),
  FieldSpec('J', 'PESHI DATE (DD/MM/YYYY)'),
  FieldSpec('K', 'MONTH/YEAR (Peshi date)'),
  FieldSpec('P', 'ISSUE DATE (DD/MM/YYYY)'),
  FieldSpec('Q', 'DESIGNATION'),
  FieldSpec('R', 'NAME'),
  FieldSpec('S', 'ADDRESS'),
  FieldSpec('T', 'MOBIEL NO. OF PERSON SUMMONED'),
  FieldSpec('W', 'MARK TO'),
  FieldSpec('AE', 'SUMMON FOR'),
  FieldSpec('AF', 'AREA OF TAMILI'),
  FieldSpec('AM', 'PURPOSE OF SUMMON'),
];

const colLetters = <String>[
  'A','B','C','D','E','F','G','H','I','J','K','P','Q','R','S','T','W','AE','AF','AM'
];

int colIndex(String letters) {
  var result = 0;
  for (final code in letters.codeUnits) {
    result = result * 26 + code - 64;
  }
  return result - 1;
}

String fmtDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

DateTime? parseStrictDate(String date) {
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(date.trim());
  if (match == null) return null;
  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null || year < 1 ||
      month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final parsed = DateTime(year, month, day);
  // DateTime normalizes impossible dates (for example, 31 February); reject them.
  if (parsed.year != year || parsed.month != month || parsed.day != day) return null;
  return parsed;
}

String monthYear(String date) {
  final parsed = parseStrictDate(date);
  if (parsed == null) return '';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[parsed.month - 1]}${parsed.year}';
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _picker = ImagePicker();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _values = {};
  final List<String> _defaultAssignees = [
    'SHO CITY', 'SHO BAHIN', 'EHC SUBHASH CHAND', 'SPO RAMESH 246',
    'CT RAVI 1497 PWL', 'EHC KARTAR 118', 'CT AJAY 99',
    'CT NASEEM KHAN 473', 'EHC HASAN'
  ];
  List<String> _assignees = [];
  String _cloudVisionEndpoint = '';
  String _jurisdiction = 'WITHIN DISTRICT';
  String _personRole = 'ACCUSED';
  String _rawText = '';
  String? _workbookPath;
  Uint8List? _workbookBytes;
  bool _busy = false;
  String _status = 'Configure Cloud Vision backend, then scan a document or open an Excel register.';

  @override
  void initState() {
    super.initState();
    for (final spec in fieldSpecs) {
      _controllers[spec.column] = TextEditingController();
      _values[spec.column] = '';
    }
    _values['AE'] = 'PRIVATE PERSON';
    _values['AF'] = 'WITHIN DISTRICT';
    _values['AM'] = 'ACCUSED';
    _loadSettings();
    _loadCloudVisionEndpoint();
    _setDefaultDates();
    _loadBundledWorkbook();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    _values['C'] = fmtDate(now);
    _values['D'] = monthYear(fmtDate(now));
    _values['P'] = fmtDate(now);
    _syncControllers();
  }

  Future<void> _loadBundledWorkbook() async {
    try {
      final data = await rootBundle.load('assets/GH.xlsx');
      if (!mounted) return;
      setState(() {
        _workbookBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        _workbookPath = 'GH.xlsx (built-in template)';
        _status = 'GH.xlsx loaded. Scan a document, review fields, and export a new register copy.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Open GH.xlsx to begin. Built-in workbook could not load: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('assignees');
    if (!mounted) return;
    setState(() => _assignees = saved == null ? List.of(_defaultAssignees) : saved);
  }


  Future<void> _loadCloudVisionEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _cloudVisionEndpoint = prefs.getString('cloudVisionEndpoint') ?? '');
  }

  Future<void> _configureCloudVision() async {
    final controller = TextEditingController(text: _cloudVisionEndpoint);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Google Cloud Vision OCR'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your secure backend HTTPS URL ending in /ocr. Do not put a Google Cloud API key in this app. The backend must call Cloud Vision with language hints en and hi.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Cloud Vision backend HTTPS URL',
                  hintText: 'https://your-service.run.app/ocr',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == null) {
      controller.dispose();
      return;
    }
    final endpoint = saved.trim();
    if (endpoint.isNotEmpty) {
      final uri = Uri.tryParse(endpoint);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Use a valid HTTPS backend URL.')),
          );
        }
        controller.dispose();
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloudVisionEndpoint', endpoint);
    if (mounted) {
      setState(() => _cloudVisionEndpoint = endpoint);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(endpoint.isEmpty ? 'Cloud Vision endpoint cleared.' : 'Cloud Vision endpoint saved.')),
      );
    }
    controller.dispose();
  }

  Future<String> _recognizeWithCloudVision(String imagePath) async {
    if (_cloudVisionEndpoint.trim().isEmpty) {
      throw Exception('Cloud Vision is not configured. Open the OCR settings and save your secure backend HTTPS URL.');
    }
    final uri = Uri.parse(_cloudVisionEndpoint.trim());
    final bytes = await File(imagePath).readAsBytes();
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'imageBase64': base64Encode(bytes),
        'languageHints': ['en', 'hi'],
      }),
    ).timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloud Vision backend returned HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from Cloud Vision backend.');
    }
    final text = decoded['text'];
    if (text is! String) {
      throw Exception('Cloud Vision backend response is missing the text field.');
    }
    return text;
  }

  Future<void> _saveAssignees() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('assignees', _assignees);
  }

  void _syncControllers() {
    for (final spec in fieldSpecs) {
      _controllers[spec.column]?.text = _values[spec.column] ?? '';
    }
  }

  void _setValue(String column, String value) {
    _values[column] = value;
    if (_controllers[column]?.text != value) _controllers[column]?.text = value;
    if (column == 'C') _values['D'] = monthYear(value);
    if (column == 'J') _values['K'] = monthYear(value);
    if (column == 'I' && value.trim().isNotEmpty) {
      _values['B'] = _registrationForCourt(value.trim());
    }
    if (column == 'P' && value.trim().isEmpty) _values['P'] = _values['C'] ?? '';
    if (mounted) setState(() {});
  }

  String _registrationForCourt(String court) {
    if (_workbookBytes == null) return '1';
    try {
      final excel = Excel.decodeBytes(_workbookBytes!);
      final sheet = excel.tables['Sheet1'];
      if (sheet == null) return '1';
      var highest = 0;
      for (var r = 1; r < sheet.maxRows; r++) {
        final existingCourt = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex('I'), rowIndex: r)).value?.toString().trim();
        if (existingCourt?.toLowerCase() != court.toLowerCase()) continue;
        final raw = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex('B'), rowIndex: r)).value?.toString().trim() ?? '';
        final number = int.tryParse(raw);
        if (number != null && number > highest) highest = number;
      }
      return '${highest + 1}';
    } catch (_) {
      return '1';
    }
  }

  Future<void> _scan(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 95);
      if (image == null) return;
      setState(() { _busy = true; _status = 'Reading document text…'; });
      final recognizedText = await _recognizeWithCloudVision(image.path);
      _rawText = recognizedText;
      _applyOcr(recognizedText);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = recognizedText.trim().isEmpty
            ? 'No text detected. Enter the details manually.'
            : 'Google Cloud Vision OCR complete (English/Hindi). Review and correct every field before saving.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _busy = false; _status = 'Scan failed: $e'; });
    }
  }

  void _applyOcr(String text) {
    // Start a fresh OCR record so fields from a previous document do not leak into this one.
    for (final key in _values.keys.toList()) {
      _values[key] = '';
    }
    _values['AE'] = 'PRIVATE PERSON';
    _values['AF'] = 'WITHIN DISTRICT';
    _values['AM'] = 'ACCUSED';
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final all = lines.join('\n');
    final now = fmtDate(DateTime.now());
    _values['C'] = now;
    _values['D'] = monthYear(now);
    _values['P'] = now;

    final fir = RegExp(r'\b(?:FIR\s*(?:NO\.?|NUMBER)?\s*[:#-]?\s*)?(\d{1,5}\s*/\s*\d{4})\b', caseSensitive: false).firstMatch(all);
    if (fir != null) {
      _values['E'] = fir.group(1)!.replaceAll(RegExp(r'\s+'), '');
    } else {
      final caseNo = RegExp(r'\b(?:COMI|CR|CRM|CNR|CASE)\s*[/.-]\s*[A-Z0-9/-]+\b', caseSensitive: false).firstMatch(all);
      _values['E'] = caseNo?.group(0)?.replaceAll(RegExp(r'\s+'), '') ?? '';
    }

    final section = RegExp(r'(?:U/S|UNDER\s+SECTION|SECTIONS?)\s*[:.-]?\s*([0-9A-Z ,./()\-]{1,45})', caseSensitive: false).firstMatch(all);
    if (section != null) _values['F'] = section.group(1)!.trim().split('\n').first;

    final ps = RegExp(r'(?:P\.?S\.?|POLICE\s+STATION)\s*[:.-]?\s*([A-Z][A-Z .-]{2,35})', caseSensitive: false).firstMatch(all);
    if (ps != null) {
      final name = ps.group(1)!.trim().split(RegExp(r'\s{2,}|,|FIR|DATE|CASE', caseSensitive: false)).first.trim();
      _values['G'] = name.toUpperCase().startsWith('PS ') ? name.toUpperCase() : 'PS ${name.toUpperCase()}';
    }

    const orderTypes = [
      'NON BAILABLE WARRANT', 'NON-BAILABLE WARRANT', 'NONBAILABLE WARRANT',
      'BAILABLE WARRANT', 'WARRANT OF ARREST', 'ARREST WARRANT',
      'WARRANT OF ARREST SUMMON', 'SUMMONS', 'SUMMON', 'PROCLAMATION',
      'NOTICE', 'BAIL',
    ];
    for (final order in orderTypes) {
      if (all.toLowerCase().contains(order.toLowerCase())) {
        _values['H'] = order.replaceAll('-', ' ');
        break;
      }
    }

    final datePattern = r'(\d{1,2}[./-]\d{1,2}[./-]\d{4})';
    String normalizeDate(String s) {
      final p = s.replaceAll('-', '/').replaceAll('.', '/').split('/');
      if (p.length != 3) return s;
      return '${p[0].padLeft(2, '0')}/${p[1].padLeft(2, '0')}/${p[2]}';
    }
    // Prefer labelled dates: warrants commonly list PREVIOUS DATE, NEXT DATE,
    // and the issue date separately. Do not accidentally use PREVIOUS DATE as Peshi.
    final nextDate = RegExp('NEXT\\s+DATE\\s*[:：-]?\\s*$datePattern', caseSensitive: false).firstMatch(all);
    if (nextDate != null) _values['J'] = normalizeDate(nextDate.group(1)!);
    final issueDate = RegExp(
      '(?:DATED\\s*,?\\s*THIS\\s+DAY\\s+OF|GIVEN\\s+UNDER[^\\n]{0,100}?THIS)\\s*$datePattern',
      caseSensitive: false,
    ).firstMatch(all);
    if (issueDate != null) _values['P'] = normalizeDate(issueDate.group(1)!);
    final dateMatches = RegExp('\\b$datePattern\\b').allMatches(all).toList();
    if ((_values['P'] ?? '').isEmpty && dateMatches.isNotEmpty) {
      _values['P'] = normalizeDate(dateMatches.last.group(1)!);
    }
    if ((_values['J'] ?? '').isEmpty && dateMatches.isNotEmpty) {
      _values['J'] = normalizeDate(dateMatches.last.group(1)!);
    }
    _values['K'] = monthYear(_values['J'] ?? '');

    final courtLine = lines.firstWhere(
      (line) => RegExp(r'\b(JMIC|CJ[M]?|ACJM|CJM|ADJ|SESSIONS|DISTRICT JUDGE|JMFC)\b', caseSensitive: false).hasMatch(line),
      orElse: () => '',
    );
    if (courtLine.isNotEmpty) _values['I'] = courtLine;
    final designation = RegExp(
      r'\b(LEGAL\s+ADVISOR|NODAL\s+OFFICER|DIRECTOR\s+RFSL|DIRECTOR\s+READER|HEAD\s+MASTER|HOME\s+GUARD|ADVOCATE|SHO|DSP|SP|SI|LSI|PSI|ASI|ESI|EHC|LHC|L\s*/\s*ASI|L\s*/\s*CT|RCT|HC|CT|MHC|SPO|MM|HGH|CLERK)\b',
      caseSensitive: false,
    ).firstMatch(all);
    if (designation != null) _values['Q'] = designation.group(0)!.toUpperCase().replaceAll(RegExp(r'\s*/\s*'), '/');

    final nameLine = lines.firstWhere(
      (line) => RegExp(r'\b(?:VERSUS|VS\.?|STATE OF|IN THE MATTER OF|S/O|D/O|W/O|F/O|SON OF|DAUGHTER OF|WIFE OF)\b', caseSensitive: false).hasMatch(line),
      orElse: () => '',
    );
    if (nameLine.isNotEmpty) _values['R'] = nameLine;

    // GH.xlsx column T is the mobile number field, not a present-address field.
    final mobileMatch = RegExp(r'\b[6-9]\d{9}\b').firstMatch(all);
    if (mobileMatch != null) _values['T'] = mobileMatch.group(0)!;
    final addressMatch = RegExp(
      r'(?:ADDRESS|R/O|RESIDENT\s+OF|RESIDENCE)\s*[:.-]?\s*([^\n]{5,180})',
      caseSensitive: false,
    ).firstMatch(all);
    if (addressMatch != null) {
      _values['S'] = addressMatch.group(1)!.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
    }

    final roleText = all.toLowerCase();
    if (roleText.contains('witness')) _values['AM'] = 'WITNESS';
    if (roleText.contains('accused') || roleText.contains('accused person')) _values['AM'] = 'ACCUSED';
    if (RegExp(r'\bpolice\b|\bsh[o0]\b|\bconstable\b|\bhead constable\b', caseSensitive: false).hasMatch(all)) {
      _values['AE'] = 'POLICE';
    }

    // Show likely missing/uncertain case identifiers for manual correction.
    if ((_values['E'] ?? '').isEmpty) _values['E'] = '*NOTE* CASE NO NOT FOUND';
    _syncControllers();
  }

  Future<void> _chooseWorkbook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['xlsx'], withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _workbookPath = result.files.single.name;
      _workbookBytes = result.files.single.bytes!;
      _status = 'Loaded ${result.files.single.name}. New records will be appended.';
    });
  }

  Future<void> _saveExcel() async {
    try {
      setState(() { _busy = true; _status = 'Preparing Excel workbook…'; });
      for (final column in ['C', 'J', 'P']) {
        final value = (_values[column] ?? '').trim();
        if (value.isNotEmpty && parseStrictDate(value) == null) {
          throw FormatException('Invalid date in column $column: "$value". Use DD/MM/YYYY.');
        }
      }
      final Excel excel;
      if (_workbookBytes != null) {
        excel = Excel.decodeBytes(_workbookBytes!);
      } else {
        excel = Excel.createExcel();
      }
      final sheet = excel.tables['Sheet1'];
      if (sheet == null) {
        throw Exception('The selected workbook must contain the GH.xlsx target sheet named Sheet1.');
      }
      const expectedHeaders = <String, String>{
        'A': 'SR NO', 'B': 'REGISTER NO', 'C': 'RECIPT DATE', 'D': 'MONTH/YEAR',
        'E': 'FIR', 'F': 'US', 'G': 'PS', 'H': 'ORDER', 'I': 'COURT NAME',
        'J': 'PESHI DATE', 'K': 'MONTH/YEAR', 'P': 'ISSUE DATE', 'Q': 'DESIGNATION',
        'R': 'NAME', 'S': 'ADDRESS', 'T': 'MOBIEL NO. OF PERSON SUMMONED',
        'W': 'MARK TO', 'AE': 'SUMMON FOR', 'AF': 'AREA OF TAMILI', 'AM': 'PURPOSE OF SUMMON',
      };
      for (final entry in expectedHeaders.entries) {
        final actual = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: colIndex(entry.key), rowIndex: 0,
        )).value?.toString().trim() ?? '';
        if (actual.toUpperCase() != entry.value) {
          throw Exception('Sheet1 column ${entry.key} must be "${entry.value}"; found "$actual". Please select the original GH.xlsx workbook.');
        }
      }
      final row = sheet.maxRows;
      final scanDate = (_values['C'] ?? '').trim().isEmpty ? fmtDate(DateTime.now()) : _values['C']!.trim();
      _values['C'] = scanDate;
      _values['D'] = monthYear(scanDate);
      if ((_values['P'] ?? '').trim().isEmpty) _values['P'] = scanDate;
      _values['K'] = monthYear(_values['J'] ?? '');

      // Serial number restarts each scan date; registration is counted per court.
      var dailyCount = 0;
      for (var r = 1; r < sheet.maxRows; r++) {
        final existingValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex('C'), rowIndex: r)).value;
        String existingDate = existingValue?.toString().trim() ?? '';
        if (existingValue is DateTime) existingDate = fmtDate(existingValue);
        final parsedExisting = DateTime.tryParse(existingDate);
        if 
