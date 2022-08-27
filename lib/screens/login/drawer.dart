import 'package:flutter/material.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/screens/login/settings_page.dart';

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            leading: Icon(Icons.home),
            title: Text("Home"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
