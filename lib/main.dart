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