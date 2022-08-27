import 'package:flutter/material.dart';
import 'package:subsound/theme/subsound_dark_theme.dart';

import '../screens/main_page.dart';

final NavigatorKey = GlobalKey<NavigatorState>();

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigatorKey,
      title: 'Sub:Sound',
      darkTheme: darkTheme,
      theme: darkTheme,
      home: MainPage(),
    );
  }
}
