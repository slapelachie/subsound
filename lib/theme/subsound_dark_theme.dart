import 'package:flutter/material.dart';

var bgColor = Colors.black;
var primaryColor = Colors.cyan;


ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.dark,
    backgroundColor: Colors.black,
    cardColor: Color(0xFF0f0f0f),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: bgColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: bgColor,
  ),
  tabBarTheme: TabBarTheme(labelColor: Colors.white),
);
