import 'package:flutter/material.dart';

const ink = Color(0xFF101313);
const panel = Color(0xFF1B2020);
const lime = Color(0xFFD7FF72);
const muted = Color(0xFF9BA9A4);
const paper = Color(0xFFF2F3EA);

ThemeData soundifyTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Vazirmatn',
  scaffoldBackgroundColor: ink,
  colorScheme: const ColorScheme.dark(
    primary: lime,
    onPrimary: ink,
    secondary: Color(0xFFC4B5FD),
    surface: panel,
    onSurface: paper,
    error: Color(0xFFFF9E9E),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: ink,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: 'Vazirmatn',
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: panel,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF303A35)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: lime),
    ),
    errorMaxLines: 2,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: lime,
      foregroundColor: ink,
      minimumSize: const Size(48, 54),
      textStyle: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: paper,
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF33413A),
    contentTextStyle: const TextStyle(fontFamily: 'Vazirmatn', color: paper),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF2B3530)),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: panel,
    showDragHandle: true,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ink,
    indicatorColor: lime.withValues(alpha: .13),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (s) => TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 11,
        color: s.contains(WidgetState.selected) ? lime : muted,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? lime : muted),
    ),
  ),
);
