import 'package:flutter/material.dart';

var bgColor = Colors.black;
var primaryColor = Colors.cyan;


ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    primaryColorDark: primaryColor,
    brightness: Brightness.dark,
    backgroundColor: Colors.black,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: bgColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: bgColor,
  ),
  tabBarTheme: TabBarTheme(labelColor: Colors.white),
);
