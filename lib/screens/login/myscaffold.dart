import 'dart:developer';
import 'dart:io';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:libadwaita_core/libadwaita_core.dart';
import 'package:subsound/components/miniplayer.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/screens/login/drawer.dart';
import 'package:subsound/screens/login/loginscreen.dart';
import 'package:subsound/state/appstate.dart';
import 'package:we_slide/we_slide.dart';

import 'homescreen.dart';

class SlidingHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WeSlide(
      body: Container(),
      panel: Container(),
      panelHeader: Container(),
      footer: BottomNavigationBar(
        items: [],
      ),
    );
  }
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

/// AppBarSettings exists because we sometimes need a SliverAppBar
/// and sometimes a regular AppBar.
class AppBarSettings {
  final bool disableAppBar;
  final bool centerTitle;
  final bool floating;
  final bool pinned;
  final Widget? title;
  final PreferredSizeWidget? bottom;

  AppBarSettings({
    this.disableAppBar = false,
    this.centerTitle = false,
    this.floating = false,
    this.pinned = false,
    this.title,
    this.bottom,
  });
}

class MyScaffold extends StatelessWidget {
  final AppBarSettings? appBar;
  final WidgetBuilder body;
  final bool disableBottomBar;

  MyScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppScaffoldModel>(
      converter: (store) => AppScaffoldModel.fromStore(store),
      builder: (context, state) => state.startUpState == StartUpState.loading
          ? SplashScreen()
          : _AppScaffold(
              builder: body,
              appBar: appBar ?? AppBarSettings(),
              disableBottomBar: disableBottomBar || !state.hasSong,
            ),
    );
  }
}

final Color bottomColor = Colors.black26.withOpacity(1.0);

class MainBody extends StatelessWidget {
  final AppBarSettings appBar;
  final bool disableBottomBar;
  final WidgetBuilder builder;

  MainBody({
    Key? key,
    required this.appBar,
    required this.builder,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _playerBottomSize = 50.0;
    final bgColor = Theme.of(context).colorScheme.background;
    final bool disableAppBar = appBar.disableAppBar;
    final WeSlideController _controller = WeSlideController();
    final footerHeight =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final double _panelMinSize =
        disableBottomBar ? footerHeight : _playerBottomSize + footerHeight;
    final double _panelMaxSize = MediaQuery.of(context).size.height;

    return WeSlide(
      controller: _controller,
      panelMinSize: _panelMinSize,
      panelMaxSize: _panelMaxSize,
      hidePanelHeader: true,
      hideFooter: true,
      parallax: false,
      overlayOpacity: 1.0,
      overlayColor: bgColor,
      backgroundColor: bgColor,
      overlay: true,
      body: CustomScrollView(
        slivers: <Widget>[
          if (!disableAppBar)
            SliverAppBar(
              title: appBar.title,
              centerTitle: appBar.centerTitle,
              floating: appBar.floating,
              pinned: appBar.pinned,
              bottom: appBar.bottom,
            ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Builder(builder: builder),
          ),
        ],
      ),
      panel: disableBottomBar
          ? SizedBox()
          : Container(
              child: PlayerView(
                backgroundColor: Theme.of(context).backgroundColor,
                header: Text(
                  "Now Playing",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ),
      panelHeader: disableBottomBar
          ? SizedBox()
          : Container(
              child: PlayerBottomBar(
                height: _playerBottomSize,
                backgroundColor: Theme.of(context).backgroundColor,
                onTap: () {
                  _controller.show();
                },
              ),
            ),
      footerHeight: footerHeight,
    );
  }
}

class _AppScaffold extends StatelessWidget {
  final AppBarSettings appBar;
  final WidgetBuilder builder;
  final bool disableBottomBar;

  _AppScaffold({
    Key? key,
    required this.builder,
    required this.appBar,
    this.disableBottomBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var bodyHolder = MainBody(
      appBar: appBar,
      disableBottomBar: disableBottomBar,
      builder: builder,
    );
    if (!kIsWeb && Platform.isLinux) {
      return AdwScaffold(
        body: bodyHolder,
        actions: AdwActions(),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: bodyHolder,
        drawer: Navigator.of(context).canPop() ? null : MyDrawer(),
      );
    }
  }
}

class RootScreen extends StatelessWidget {
  static final routeName = "/root";

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ServerData>(
      converter: (store) => store.state.loginState,
      builder: (context, data) {
        if (data.uri.isEmpty || Uri.tryParse(data.uri) == null) {
          log("root:init:nostate data.uri=${data.uri}");
          //Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
          return LoginScreen();
        } else {
          log("root:init:state data.uri=${data.uri}");
          //Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
          return HomeScreen();
        }
      },
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
