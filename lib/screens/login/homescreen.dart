import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/screens/browsing/home_page.dart';
import 'package:subsound/screens/browsing/starred_page.dart';
import 'package:subsound/screens/login/albums_page.dart';
import 'package:subsound/screens/login/artists_page.dart';
import 'package:subsound/state/appstate.dart';

import 'myscaffold.dart';

class HomeScreen extends StatelessWidget {
  static final routeName = "/home";

  final int initialTabIndex;

  const HomeScreen({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ServerData>(
      converter: (st) => st.state.loginState,
      builder: (context, state) => DefaultTabController(
        length: 3,
        initialIndex: initialTabIndex,
        child: MyScaffold(
          appBar: AppBarSettings(
            title: Text("Home"),
            bottom: TabBar(
              onTap: (idx) {},
              tabs: [
                Tab(
                  text: "Home",
                ),
                Tab(
                  text: "Albums",
                ),
                Tab(
                  text: "Artists",
                ),
              ],
            ),
          ),
          body: (context) => Center(
            child: TabBarView(
              children: [
                Center(child: HomePage()),
                Center(child: AlbumsPage()),
                Center(child: ArtistsPage()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
