import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/requests.dart';
import 'package:subsound/subsonic/subsonic.dart';
import 'package:subsound/utils/duration.dart';
import 'package:subsound/views/summary_view.dart';

import '../../state/playerstate.dart';
import '../../views/album_scroll_view.dart';

class ArtistScreen extends StatelessWidget {
  final String artistId;
  final String artistName;

  ArtistScreen({
    required this.artistId,
    required this.artistName,
  });

  ArtistScreen.of(this.artistId, this.artistName);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ArtistPage(
          artistId: artistId,
          artistName: artistName,
        ),
      ),
    );
  }
}

class ArtistPageModel extends Vm {
  final String? currentSongId;
  final Future<ArtistResult?> Function(String artistId) onLoad;
  final Future<List<SongResult>?> Function(String artistName) onLoadTopSongs;
  final Function(SongResult song) onEnqueue;
  final Function(SongResult song, List<SongResult> topSongs) onPlay;

  ArtistPageModel({
    required this.currentSongId,
    required this.onLoad,
    required this.onLoadTopSongs,
    required this.onEnqueue,
    required this.onPlay,
  }) : super(equals: []);
}

class ArtistPage extends StatelessWidget {
  final String artistId;
  final String artistName;

  const ArtistPage({
    Key? key,
    required this.artistId,
    required this.artistName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ArtistPageModel>(
      vm: () => ArtistPageModelFactory(this),
      builder: (context, vm) => _ArtistPageStateful(
        artistId: artistId,
        artistName: artistName,
        currentSongId: vm.currentSongId,
        onEnqueue: vm.onEnqueue,
        onPlay: vm.onPlay,
        vm: vm,
      ),
    );
  }
}

class ArtistPageModelFactory extends VmFactory<AppState, ArtistPage> {
  ArtistPageModelFactory(ArtistPage widget) : super(widget);

  @override
  ArtistPageModel fromStore() {
    return ArtistPageModel(
        currentSongId: state.playerState.currentSong?.id,
        onLoad: (artistId) =>
            dispatchAsync(GetArtistCommand(artistId: artistId)).then(
                (value) => currentState().dataState.artists.get(artistId)),
        onLoadTopSongs: (artistName) =>
            dispatchAsync(GetTopSongsCommand(artist: artistName)).then(
                (value) => currentState().dataState.topSongs.get(artistName)),
        onEnqueue: (SongResult song) {
          dispatch(PlayerCommandEnqueueSong(song));
        },
        onPlay: (SongResult song, List<SongResult> topSongs) {
          dispatch(
              PlayerCommandPlaySongInQueue(song: song, songQueue: topSongs));
        });
  }
}

class _ArtistPageStateful extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String? currentSongId;
  final ArtistPageModel vm;
  final Function(SongResult song) onEnqueue;
  final Function(SongResult song, List<SongResult> topSongs) onPlay;

  _ArtistPageStateful({
    Key? key,
    required this.artistId,
    required this.artistName,
    required this.currentSongId,
    required this.vm,
    required this.onEnqueue,
    required this.onPlay,
  }) : super(key: key);

  @override
  State<_ArtistPageStateful> createState() {
    return _ArtistPageState();
  }
}

class AlbumRow extends StatelessWidget {
  final AlbumResultSimple album;
  final Function(AlbumResultSimple) onSelectedAlbum;

  const AlbumRow({
    Key? key,
    required this.album,
    required this.onSelectedAlbum,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onSelectedAlbum(album);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CoverArtImage(
              album.coverArtLink,
              id: album.coverArtId,
              width: 72.0,
              height: 72.0,
            ),
            Flexible(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '${album.year}',
                      style: TextStyle(
                          fontWeight: FontWeight.w100, fontSize: 12.0),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
                margin: EdgeInsets.all(10.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: add playing from here
class TopSongRow extends StatelessWidget {
  final SongResult song;
  final bool isPlaying;
  final int position;
  final Function(SongResult) onEnqueue;
  final Function(SongResult) onPlay;

  const TopSongRow({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.onPlay,
    required this.onEnqueue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(left: 10),
      child: ListTile(
        onTap: () {
          onPlay(song);
        },
        leading: Column(
          //mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${position}",
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
        subtitle: Text(song.albumName),
      ),
    );
  }
}

// TODO: Add ability to specify amount of top songs
class ArtistView extends StatelessWidget {
  final ArtistResult artist;
  final List<SongResult> topSongs;
  final String? currentSongId;
  final Function(AlbumResultSimple) onSelectedAlbum;
  final Function(SongResult song) onEnqueue;
  final Function(SongResult song, List<SongResult> topSongs) onPlay;

  const ArtistView({
    Key? key,
    required this.artist,
    required this.onSelectedAlbum,
    required this.currentSongId,
    required this.topSongs,
    required this.onEnqueue,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var expandedHeight = MediaQuery.of(context).size.width * .9;
    Duration duration = Duration(milliseconds: 0);
    int songCount = 0;
    List<Album> albums =
        artist.albums.map((album) => convertFromSimpleAlbum(album)).toList();

    artist.albums.forEach((album) {
      duration += album.duration;
      songCount += album.songCount;
    });

    return SummaryView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(expandedHeight / 50),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.center,
                child: CoverArtImage(
                  artist.coverArtLink,
                  id: artist.coverArtId,
                  height: expandedHeight,
                  width: expandedHeight,
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
                  artist.name,
                  //textAlign: TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36.0,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      artist.albumCount.toString() + " Albums",
                    ),
                    VerticalDivider(),
                    Text(
                      songCount.toString() + " Songs",
                    ),
                    VerticalDivider(),
                    Text(
                      formatDuration(duration),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: AlbumsScrollView(
              data: albums,
              title: "Albums",
              sort: true,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: topSongs.isEmpty
              ? SizedBox()
              : Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Text(
                    "Top Songs",
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final song = topSongs[index];
              final isPlaying =
                  currentSongId != null && currentSongId == song.id;

              return TopSongRow(
                isPlaying: isPlaying,
                song: song,
                position: index + 1,
                onEnqueue: (song) {
                  onEnqueue(song);
                },
                onPlay: (song) {
                  onPlay(song, topSongs);
                },
              );
            },
            childCount: topSongs.length,
          ),
        ),
      ],
    );
  }
}

class AlbumList extends StatelessWidget {
  final ArtistResult artist;
  final List<AlbumResultSimple> albums;
  final Function(AlbumResultSimple) onSelectedAlbum;

  const AlbumList({
    Key? key,
    required this.artist,
    required this.albums,
    required this.onSelectedAlbum,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: albums
            .map((a) => AlbumRow(
                  album: a,
                  onSelectedAlbum: onSelectedAlbum,
                ))
            .toList(),
      ),
    );
  }
}

class _ArtistPageState extends State<_ArtistPageStateful> {
  late Future<ArtistResult> loader;
  late Future<List<SongResult>> topSongs;

  _ArtistPageState();

  @override
  void initState() {
    super.initState();
    loader = load(widget.artistId);
    topSongs = loadTopSongs(widget.artistName);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder(
            future: Future.wait([loader, topSongs]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return SummaryView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                );
              } else {
                if (snapshot.hasData) {
                  return ArtistView(
                    artist: snapshot.data![0],
                    topSongs: snapshot.data![1],
                    onEnqueue: widget.onEnqueue,
                    onPlay: widget.onPlay,
                    currentSongId: widget.currentSongId,
                    onSelectedAlbum: (album) {
                      return showModalBottomSheet(
                        isDismissible: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) => AlbumScreen(
                          albumId: album.id,
                        ),
                      );
                    },
                  );
                } else {
                  return Text("${snapshot.error}");
                }
              }
            }));
  }

  Future<ArtistResult> load(String artistId) {
    return widget.vm.onLoad(artistId).then((value) => value!);
  }

  Future<List<SongResult>> loadTopSongs(String artistName) {
    return widget.vm.onLoadTopSongs(artistName).then((value) => value!);
  }
}
