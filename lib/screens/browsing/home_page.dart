import 'dart:math';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/browsing/starred_page.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/screens/login/playlist_page.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/models/album.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';
import 'package:subsound/subsonic/requests/get_playlist.dart';

import '../../components/album_scroll_view.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _HomePageViewModel>(
      converter: (st) => _HomePageViewModel(
        currentSongId: st.state.playerState.currentSong?.id ?? '',
        onPlayAlbum: (album) => st.dispatch(PlayerCommandPlayAlbum(album)),
        onPlaySong: (song, queue) => st.dispatch(PlayerCommandContextualPlay(
          songId: song.id,
          playQueue: queue,
        )),
        onLoadStarred: () async {
          final load1 = st.dispatchAsync(RefreshStarredCommand());
          final load2 = st.dispatchAsync(
            GetAlbumsCommand(type: GetAlbumListType.recent, pageSize: 20),
          );
          final load3 = st.dispatchAsync(
            GetAlbumsCommand(type: GetAlbumListType.newest, pageSize: 20),
          );
          final load4 = st.dispatchAsync(RefreshPlaylistsCommand());

          await Future.wait([load1, load2, load3, load4]);

          final starred = st.state.dataState.stars;
          final recentAlbums =
              st.state.dataState.albums.albumLists[GetAlbumListType.recent] ??
                  [];
          final newAlbums =
              st.state.dataState.albums.albumLists[GetAlbumListType.newest] ??
                  [];

          final data = [
            ...starred.albums.entries
                .map((key) => StarredItem(album: key.value))
                .toList(),
            ...starred.songs.entries
                .map((key) => StarredItem(song: key.value))
                .toList(),
          ];

          data.sort((a, b) {
            if (a.getAlbum() != null) {
              if (b.getAlbum() != null) {
                return a
                        .getAlbum()!
                        .starredAt!
                        .compareTo(b.getAlbum()!.starredAt!) *
                    -1;
              } else {
                return a
                        .getAlbum()!
                        .starredAt!
                        .compareTo(b.getSong()!.starredAt!) *
                    -1;
              }
            } else {
              if (b.getAlbum() != null) {
                return a
                        .getSong()!
                        .starredAt!
                        .compareTo(b.getAlbum()!.starredAt!) *
                    -1;
              } else {
                return a
                        .getSong()!
                        .starredAt!
                        .compareTo(b.getSong()!.starredAt!) *
                    -1;
              }
            }
          });

          return HomeData(
            data,
            recentAlbums,
            newAlbums,
            st.state.dataState.playlists.playlistList.values.toList(),
          );
        },
      ),
      builder: (context, vm) => _StarredPageStateful(model: vm),
    );
  }
}

class _StarredPageStateful extends StatefulWidget {
  final _HomePageViewModel model;

  _StarredPageStateful({Key? key, required this.model}) : super(key: key);

  @override
  State<_StarredPageStateful> createState() {
    return _StarredPageState();
  }
}

class StarredItem {
  final SongResult? song;
  final AlbumResultSimple? album;

  StarredItem({this.song, this.album});

  SongResult? getSong() {
    return song;
  }

  AlbumResultSimple? getAlbum() {
    return album;
  }

  bool isPlaying(String currentSongId) {
    return currentSongId.isNotEmpty && song?.id == currentSongId;
  }
}

class HomeData {
  final List<StarredItem> starred;
  final List<Album> recentAlbums;
  final List<Album> newAlbums;
  final List<PlaylistResult> playlists;

  HomeData(this.starred, this.recentAlbums, this.newAlbums, this.playlists);
}

class _HomePageViewModel extends Vm {
  final String currentSongId;
  final Function(SongResult, List<SongResult>) onPlaySong;
  final Function(AlbumResultSimple) onPlayAlbum;
  final Future<HomeData> Function() onLoadStarred;

  _HomePageViewModel({
    required this.currentSongId,
    required this.onPlaySong,
    required this.onPlayAlbum,
    required this.onLoadStarred,
  }) : super(equals: [currentSongId]);
}

class StarredScrollView extends StatelessWidget {
  final List<StarredItem> starred;
  final String currentPlayingId;
  final Function(StarredItem) onPlay;

  StarredScrollView({
    Key? key,
    required this.starred,
    required this.currentPlayingId,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: starred.length,
      shrinkWrap: true,
      itemBuilder: (context, idx) {
        return StarredRow(
          item: starred[idx],
          isPlaying: currentPlayingId.isNotEmpty &&
              starred[idx].isPlaying(currentPlayingId),
          onPlay: onPlay,
        );
      },
    );
  }
}

class StarredListView extends StatelessWidget {
  final _HomePageViewModel model;
  final HomeData data;

  const StarredListView({
    Key? key,
    required this.model,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      itemCount: 3,
      padding: EdgeInsets.zero,
      itemBuilder: (context, listIndex) {
        if (listIndex == 0) {
          return AlbumsScrollView(
            title: "Recent albums",
            data: data.recentAlbums,
            max_count: 10,
          );
        } else if (listIndex == 1) {
          return AlbumsScrollView(
            title: "New albums",
            data: data.newAlbums,
            max_count: 10,
          );
        } else {
          return PlaylistsScrollView(
            title: "Playlists",
            data: data.playlists,
          );
        }
      },
    );
  }
}

class HomePageTitle extends StatelessWidget {
  final String text;
  final double? bottomPadding;

  const HomePageTitle(this.text, {Key? key, this.bottomPadding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
          left: homePaddingLeft,
          bottom: bottomPadding ?? homePaddingBottom,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 24),
        ));
  }
}

const homePaddingLeft = 8.0;
const homePaddingBottom = 8.0;


class PlaylistsScrollView extends StatelessWidget {
  final List<PlaylistResult> data;
  final String title;

  PlaylistsScrollView({
    Key? key,
    required this.data,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomePageTitle(
          title,
          bottomPadding: 0.0,
        ),
        ListView.builder(
            shrinkWrap: true,
            physics: ScrollPhysics(),
            itemCount: data.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (ctx, idx) {
              var a = data[idx];

              return ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: homePaddingLeft),
                dense: true,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PlaylistScreen(playlistId: a.id),
                  ));
                },
                leading: CoverArtImage(
                  a.coverArt ?? fallbackImageUrl,
                  id: a.coverArt ?? fallbackImageUrl,
                  width: 48.0,
                  height: 48.0,
                ),
                title: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.subtitle1,
                ),
                subtitle: Text(
                  a.comment,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.subtitle1,
                ),
              );
            }),
      ],
    );
  }
}

class StarredRow extends StatelessWidget {
  final StarredItem item;
  final bool isPlaying;
  final Function(StarredItem) onPlay;
  final EdgeInsets? padding;

  const StarredRow({
    Key? key,
    required this.item,
    required this.isPlaying,
    required this.onPlay,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (item.getAlbum() != null) {
      return StarredAlbumRow(
        album: item.getAlbum()!,
        onTap: (AlbumResultSimple album) {
          onPlay(item);
        },
        onTapCover: (album) {
          return showModalBottomSheet(
            context: context,
            isDismissible: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AlbumScreen(
              albumId: album.id,
            ),
          );
          /*
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AlbumScreen(
              albumId: album.id,
            ),
          ));
          */
        },
      );
    }
    if (item.getSong() != null) {
      return StarredSongRow(
        song: item.getSong()!,
        isPlaying: isPlaying,
        onTapCover: (SongResult song) {
          return showModalBottomSheet(
            context: context,
            isDismissible: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AlbumScreen(
              albumId: song.albumId,
            ),
          );
        },
        onTapRow: (SongResult song) {
          onPlay(item);
        },
      );
    }
    throw StateError("unhandled item type");
  }
}

class _StarredPageState extends State<_StarredPageStateful> {
  late Future<HomeData> initialLoad;

  @override
  void initState() {
    super.initState();

    initialLoad = widget.model.onLoadStarred();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
        future: initialLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasError) {
              return Text("${snapshot.error}");
            } else {
              final loadedData = snapshot.data!;
              return StarredListView(
                model: widget.model,
                data: loadedData,
              );
            }
          }
        });
  }
}
