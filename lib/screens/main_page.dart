import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/settings_page.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  Text _title = Text("Home");

  final screens = [
    HomeScreen(),
    SettingsPage(),
  ];

  final titles = [
    Text("Home"),
    Text("Settings"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: screens[_selectedIndex],
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: _title,
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.background,
        child: Column(
          children: <Widget>[
            DrawerHeader(
              child: Text(
                'Subsound',
                style: TextStyle(
                  //color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.home,
                color: _selectedIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                "Home",
                style: TextStyle(
                  color: _selectedIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: _selectedIndex == 1
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                "Settings",
                style: TextStyle(
                  color: _selectedIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
