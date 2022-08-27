import 'package:flutter/material.dart';
import 'package:subsound/screens/browsing/home_page.dart';
import 'package:subsound/screens/login/albums_page.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final screens = [
    HomePage(),
    AlbumsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.background,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Music',
          )
        ],
      ),
    );
  }
}

/*class HomeScreen extends StatelessWidget {
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
              indicatorColor: Theme.of(context).primaryColor,
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
*/
