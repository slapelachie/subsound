import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/screens/login/homescreen.dart';
import 'package:subsound/screens/login/settings_page.dart';

import '../state/appstate.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => MainPageState();
}

class AppScaffoldModel extends Vm {
  final StartUpState startUpState;
  final bool hasSong;

  AppScaffoldModel({
    required this.startUpState,
    required this.hasSong,
  }) : super(equals: [startUpState, hasSong]);

  static AppScaffoldModel fromStore(Store<AppState> store) => AppScaffoldModel(
        startUpState: store.state.startUpState,
        hasSong: store.state.playerState.currentSong != null,
      );
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
    return StoreConnector<AppState, AppScaffoldModel>(
      converter: (store) => AppScaffoldModel.fromStore(store),
      builder: (context, state) => state.startUpState == StartUpState.loading
          ? SplashScreen()
          : Scaffold(
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
            ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        //color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Sub",
              style: TextStyle(
                fontSize: 40.0,
                //color: Theme.of(context).primaryColor,
                //color: Colors.tealAccent,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            Icon(
              Icons.play_arrow,
              size: 36.0,
            ),
            SizedBox(height: 20.0),
            Text(
              "Sound",
              style: TextStyle(
                fontSize: 32.0,
                //color: Theme.of(context).primaryColor,
                //color: Colors.tealAccent,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            //CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
