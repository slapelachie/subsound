import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/artist_page.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/theme/text_styles.dart';

import '../../state/service_locator.dart';

class _AlbumViewModelFactory extends VmFactory<AppState, AlbumScreen> {
  _AlbumViewModelFactory(AlbumScreen widget) : super(widget);

  @override
  AlbumViewModel fromStore() {
    final playerManager = getIt<PlayerManager>();
    return AlbumViewModel(
      serverData: state.loginState,
      currentSongId: state.playerState.currentSong?.id,
      loadAlbum: (String albumId) {
        return dispatchAsync(GetAlbumCommand(albumId: albumId))
            .then((value) => currentState().dataState.albums.get(albumId));
      },
      onPlay: (SongResult song, List<SongResult> albumSongs) {
        playerManager.playSongWithQueue(song, albumSongs);
      },
      onEnqueue: playerManager.enqueueSong,
    );
  }
}

class AlbumViewModel extends Vm {
  final ServerData serverData;
  final String? currentSongId;
  final Future<AlbumResult?> Function(String albumId) loadAlbum;
  final Function(SongResult song, List<SongResult> albumSongs) onPlay;
  final Function(SongResult song) onEnqueue;

  AlbumViewModel({
    required this.serverData,
    required this.currentSongId,
    required this.loadAlbum,
    required this.onPlay,
    required this.onEnqueue,
  }) : super(equals: [
          serverData,
          currentSongId ?? '',
        ]);
}

class AlbumScreen extends StatelessWidget {
  final String albumId;

  AlbumScreen({
    required this.albumId,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AlbumViewModel>(
      vm: () => _AlbumViewModelFactory(this),
      builder: (context, state) {
        return Container(
          child: Center(
            child: AlbumPage(
              ctx: state.serverData.toClient(),
              currentSongId: state.currentSongId,
              albumId: albumId,
              loadAlbum: state.loadAlbum,
              onPlay: state.onPlay,
              onEnqueue: state.onEnqueue,
            ),
          ),
        );
      },
    );
  }
}

class AlbumPage extends StatefulWidget {
  final SubsonicContext ctx;
  final String albumId;
  final String? currentSongId;
  final Future<AlbumResult?> Function(String albumId) loadAlbum;
  final Function(SongResult song, List<SongResult> albumSongs) onPlay;
  final Function(SongResult song) onEnqueue;

  const AlbumPage({
    Key? key,
    required this.ctx,
    required this.albumId,
    required this.currentSongId,
    required this.onPlay,
    required this.onEnqueue,
    required this.loadAlbum,
  }) : super(key: key);

  @override
  State<AlbumPage> createState() {
    return AlbumPageState();
  }
}

String stringDuration(Duration duration) {
  String newDuration = "";
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours >= 1) {
    newDuration = "${twoDigits(duration.inHours)}:";
  }

  return newDuration + "$twoDigitMinutes:$twoDigitSeconds";
}

class SongRow extends StatelessWidget {
  final SongResult song;
  final bool isPlaying;
  final Function(SongResult) onPlay;
  final Function(SongResult) onEnqueue;

  const SongRow({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.onPlay,
    required this.onEnqueue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(left: 10),
      child: Slidable(
        key: Key(song.id),
        groupTag: '0',
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 1.0,
          dismissible: DismissiblePane(
            closeOnCancel: true,
            onDismissed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Added to queue')));
              onEnqueue(song);
              Slidable.of(context)?.close();
            },
            confirmDismiss: () async {
              return true;
            },
          ),
          children: [
            SlidableAction(
              label: 'Enqueue',
              backgroundColor: Colors.green,
              icon: Icons.playlist_add,
              onPressed: (context) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Added to queue")));
                onEnqueue(song);
                Slidable.of(context)?.close();
              },
            ),
          ],
        ),
        direction: Axis.horizontal,
        child: ListTile(
          onTap: () {
            print("TAP!!!!!!");
            onPlay(song);
            Slidable.of(context)?.close();
          },
          leading: Column(
            //mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${song.trackNumber}",
                style: TextStyle(
                    // color: isPlaying
                    //     ? theme.accentColor
                    //     : theme.colorScheme.onPrimary.withOpacity(0.7),
                    ),
              ),
            ],
          ),
          dense: true,
          minLeadingWidth: 15,
          title: Text(
            song.title,
            style: TextStyle(
              color: isPlaying
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(stringDuration(song.duration)),
              PopupMenuButton(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: Text("Add to queue"),
                      onTap: onEnqueue(song),
                    )
                  ];
                },
              )
            ],
          ),
          subtitle: Text(song.artistName),
        ),
      ),
    );
  }
}

class AlbumView extends StatelessWidget {
  final AlbumResult album;
  final String? currentSongId;
  final Function(SongResult song, List<SongResult> albumSongs) onPlay;
  final Function(SongResult song) onEnqueue;

  AlbumView({
    Key? key,
    required this.album,
    required this.currentSongId,
    required this.onPlay,
    required this.onEnqueue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var expandedHeight = MediaQuery.of(context).size.width * .9;
    final playerManager = getIt<PlayerManager>();

    Widget makeDismissible({required Widget child}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: GestureDetector(
            onTap: () {},
            child: child,
          ),
        );

    return SlidableAutoCloseBehavior(
      child: makeDismissible(
        child: DraggableScrollableSheet(
          maxChildSize: 1.0,
          minChildSize: 0.7,
          initialChildSize: 0.7,
          builder: (context, controller) => Container(
            padding: EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(15.0),
              ),
            ),
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(expandedHeight / 50),
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                        child: CoverArtImage(
                          album.coverArtLink,
                          id: album.coverArtId,
                          width: expandedHeight,
                          height: expandedHeight,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.name,
                          //textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 36.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isDismissible: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ArtistScreen(
                              artistId: album.artistId,
                              artistName: album.artistName,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                album.artistName,
                                style: albumInfoStyle.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.8),
                                ),
                              ),
                              VerticalDivider(),
                              Text(
                                "${album.year}",
                                style: albumInfoStyle.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.8),
                                ),
                              ),
                              VerticalDivider(),
                              Text(
                                stringDuration(album.duration),
                                style: albumInfoStyle.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                        top: 10, left: 20, right: 20, bottom: 10),
                    child: Text(
                      "Songs",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final song = album.songs[index];
                      final isPlaying =
                          currentSongId != null && currentSongId == song.id;
                      return SongRow(
                        isPlaying: isPlaying,
                        song: song,
                        onEnqueue: (song) {
                          onEnqueue(song);
                        },
                        onPlay: (song) {
                          print("PLAY ALBUM THSJK");
                          playerManager.playSongWithQueue(song, album.songs);
                        },
                      );
                    },
                    childCount: album.songs.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlbumPageState extends State<AlbumPage> {
  late Future<AlbumResult> future;

  AlbumPageState();

  @override
  void initState() {
    super.initState();
    future = load(widget.albumId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder<AlbumResult>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return AlbumView(
                currentSongId: widget.currentSongId,
                album: snapshot.data!,
                onPlay: widget.onPlay,
                onEnqueue: widget.onEnqueue,
              );
            } else {
              return Center(child: Text("${snapshot.error}"));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<AlbumResult> load(String albumId) {
    return widget.loadAlbum(albumId).then((value) => value!);
  }
}
