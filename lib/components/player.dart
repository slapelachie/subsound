import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/screens/login/artist_page.dart';
import 'package:subsound/screens/login/myscaffold.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/state/queue.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/star.dart';

import '../state/service_locator.dart';

class PlayerSong {
  final String id;
  final String songTitle;
  final String album;
  final String artist;
  final String artistId;
  final String albumId;
  final String coverArtId;
  final String? coverArtLink;
  final String songUrl;
  final String contentType;
  final String fileExtension;
  final int fileSize;
  final Duration duration;
  final bool isStarred;

  PlayerSong({
    required this.id,
    required this.songTitle,
    required this.artist,
    required this.album,
    required this.artistId,
    required this.albumId,
    required this.coverArtId,
    this.coverArtLink,
    required this.songUrl,
    required this.contentType,
    required this.fileExtension,
    required this.fileSize,
    required this.duration,
    this.isStarred = false,
  });

  static PlayerSong from(SongResult s, [bool? isStarred]) => PlayerSong(
        id: s.id,
        songTitle: s.title,
        album: s.albumName,
        artist: s.artistName,
        artistId: s.artistId,
        albumId: s.albumId,
        coverArtId: s.coverArtId,
        coverArtLink: s.coverArtLink,
        songUrl: s.playUrl,
        contentType: s.contentType,
        fileExtension: s.suffix,
        fileSize: s.fileSize,
        duration: s.duration,
        isStarred: isStarred ?? s.starred,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSong &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          songTitle == other.songTitle &&
          artist == other.artist &&
          album == other.album &&
          artistId == other.artistId &&
          albumId == other.albumId &&
          coverArtId == other.coverArtId &&
          coverArtLink == other.coverArtLink &&
          songUrl == other.songUrl &&
          contentType == other.contentType &&
          fileExtension == other.fileExtension &&
          fileSize == other.fileSize &&
          duration == other.duration &&
          isStarred == other.isStarred;

  @override
  int get hashCode =>
      id.hashCode ^
      songTitle.hashCode ^
      artist.hashCode ^
      album.hashCode ^
      artistId.hashCode ^
      albumId.hashCode ^
      coverArtId.hashCode ^
      coverArtLink.hashCode ^
      songUrl.hashCode ^
      duration.hashCode ^
      isStarred.hashCode;

  PlayerSong copy({
    bool? isStarred,
  }) =>
      PlayerSong(
        id: id,
        songTitle: songTitle,
        artist: artist,
        album: album,
        artistId: artistId,
        albumId: albumId,
        coverArtId: coverArtId,
        coverArtLink: coverArtLink,
        songUrl: songUrl,
        contentType: contentType,
        fileExtension: fileExtension,
        fileSize: fileSize,
        duration: duration,
        isStarred: isStarred ?? this.isStarred,
      );

  @override
  String toString() {
    return 'PlayerSong{id: $id, songTitle: $songTitle, format=$fileExtension,}';
  }

  MediaItem toMediaItem() {
    return asMediaItem(this);
  }

  static MediaItem asMediaItem(PlayerSong song) {
    SongMetadata meta = SongMetadata(
      songId: song.id,
      songUrl: song.songUrl,
      fileExtension: song.fileExtension,
      fileSize: song.fileSize,
      contentType: song.contentType,
    );
    final playItem = MediaItem(
      id: song.songUrl,
      artist: song.artist,
      album: song.album,
      title: song.songTitle,
      displayTitle: song.songTitle,
      displaySubtitle: song.artist,
      artUri: song.coverArtLink != null ? Uri.parse(song.coverArtLink!) : null,
      duration: song.duration.inSeconds > 0 ? song.duration : Duration.zero,
      extras: {},
    ).setSongMetadata(meta);

    return playItem;
  }

// static PlayerSong fromMediaItem(MediaItem item) {
//   var meta = item.getSongMetadata();
//   return PlayerSong(
//     id: item.id,
//     songTitle: item.id,
//     artist: item.artist ?? '',
//     album: item.album ?? '',
//     artistId: item.artist,
//     albumId: albumId,
//     coverArtId: coverArtId,
//     songUrl: songUrl,
//     contentType: contentType,
//     fileExtension: fileExtension,
//     fileSize: fileSize,
//     duration: duration,
//   );
// }
}

enum PlayerStates { stopped, playing, paused, buffering }

enum ShuffleMode { none, shuffle }

class PlayerState {
  final PlayerStates current;
  final PlayerSong? currentSong;
  final Queue queue;
  final Duration duration;
  final Duration position;
  final ShuffleMode shuffleMode;
  final double volume;

  PlayerState({
    required this.current,
    this.currentSong,
    required this.queue,
    required this.duration,
    required this.position,
    required this.shuffleMode,
    required this.volume,
  });

  bool get isPlaying => current == PlayerStates.playing;

  bool get isPaused =>
      current == PlayerStates.paused || current == PlayerStates.buffering;

  bool get isStopped => current == PlayerStates.stopped;

  PlayerState copy({
    PlayerStates? current,
    PlayerSong? currentSong,
    Queue? queue,
    Duration? duration,
    Duration? position,
    ShuffleMode? shuffleMode,
    double? volume,
  }) =>
      PlayerState(
        current: current ?? this.current,
        currentSong: currentSong ?? this.currentSong,
        queue: queue ?? this.queue,
        duration: duration ?? this.duration,
        position: position ?? this.position,
        shuffleMode: shuffleMode ?? this.shuffleMode,
        volume: volume ?? this.volume,
      );

  static PlayerState initialState() => PlayerState(
        current: PlayerStates.stopped,
        currentSong: null,
        duration: Duration.zero,
        position: Duration.zero,
        queue: Queue([]),
        shuffleMode: ShuffleMode.none,
        volume: 1.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          current == other.current &&
          currentSong == other.currentSong &&
          queue == other.queue &&
          shuffleMode == other.shuffleMode &&
          duration == other.duration &&
          position == other.position;

  @override
  int get hashCode =>
      current.hashCode ^
      currentSong.hashCode ^
      queue.hashCode ^
      duration.hashCode ^
      position.hashCode ^
      shuffleMode.hashCode;

  @override
  String toString() {
    return 'PlayerState{current: $current, currentSong: $currentSong, queue: ${queue.length}, duration: $duration, position: $position, shuffleMode: ${describeEnum(shuffleMode)}';
  }
}

class _PlayerViewModelFactory extends VmFactory<AppState, PlayerView> {
  _PlayerViewModelFactory(PlayerView widget) : super(widget);

  @override
  PlayerViewModel fromStore() {
    return PlayerViewModel(
      songId: state.playerState.currentSong?.id ?? '',
      songTitle: state.playerState.currentSong?.songTitle ?? '',
      artistTitle: state.playerState.currentSong?.artist ?? '',
      artistId: state.playerState.currentSong?.artistId ?? '',
      albumTitle: state.playerState.currentSong?.album ?? '',
      albumId: state.playerState.currentSong?.albumId ?? '',
      coverArtLink: state.playerState.currentSong?.coverArtLink ?? '',
      coverArtId: state.playerState.currentSong?.coverArtId ?? '',
      isStarred: state.playerState.currentSong?.isStarred ?? false,
      duration: state.playerState.duration,
      position: state.playerState.position,
      playerState: state.playerState.current,
      onStar: (String id) => dispatch(StarIdCommand(SongId(songId: id))),
      onUnstar: (String id) => dispatch(UnstarIdCommand(SongId(songId: id))),
    );
  }
}

class PlayerViewModel extends Vm {
  final String songId;
  final String songTitle;
  final String artistTitle;
  final String artistId;
  final String albumTitle;
  final String albumId;
  final String? coverArtLink;
  final String coverArtId;
  final bool isStarred;
  final Duration duration;
  final Duration position;
  final PlayerStates playerState;
  final Function(String) onStar;
  final Function(String) onUnstar;

  PlayerViewModel({
    required this.songId,
    required this.songTitle,
    required this.artistTitle,
    required this.artistId,
    required this.albumTitle,
    required this.albumId,
    this.coverArtLink,
    required this.coverArtId,
    required this.isStarred,
    required this.duration,
    required this.position,
    required this.playerState,
    required this.onStar,
    required this.onUnstar,
  }) : super(equals: [
          songId,
          songTitle,
          artistTitle,
          albumTitle,
          albumId,
          coverArtLink ?? '',
          coverArtId,
          isStarred,
          duration,
          position,
          playerState,
        ]);
}

class PlayerView extends StatelessWidget {
  final Widget? header;
  final Color? backgroundColor;
  final double? height;

  const PlayerView({
    Key? key,
    this.header,
    this.backgroundColor,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerManager = getIt<PlayerManager>();
    return Container(
      color: backgroundColor,
      height: height,
      child: StoreConnector<AppState, PlayerViewModel>(
        vm: () => _PlayerViewModelFactory(this),
        builder: (context, vm) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  if (vm.albumId.isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      isDismissible: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AlbumScreen(
                        albumId: vm.albumId,
                      ),
                    );
                  }
                },
                child: FittedBox(
                  child: vm.coverArtLink != null
                      ? CoverArtImage(
                          vm.coverArtLink,
                          id: vm.coverArtId,
                          width: MediaQuery.of(context).size.width * .8,
                          height: MediaQuery.of(context).size.width * .8,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.album),
                ),
              ),
              Column(
                children: [
                  Column(
                    children: [
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isDismissible: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AlbumScreen(
                            albumId: vm.albumId,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: SongTitle(songTitle: vm.songTitle),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isDismissible: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ArtistScreen(
                            artistId: vm.artistId,
                            artistName: vm.artistTitle,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: ArtistTitle(
                            artistName: vm.artistTitle,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.0),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.skip_previous),
                        iconSize: 42.0,
                        onPressed: playerManager.previous,
                      ),
                      PlayButton(size: 72.0),
                      IconButton(
                        icon: Icon(Icons.skip_next),
                        iconSize: 42.0,
                        onPressed: playerManager.next,
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SongTitle extends StatelessWidget {
  final String? songTitle;

  const SongTitle({Key? key, this.songTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      songTitle ?? '',
      style: TextStyle(fontSize: 18.0),
      overflow: TextOverflow.fade,
      maxLines: 1,
    );
  }
}

class ArtistTitle extends StatelessWidget {
  final String? artistName;

  const ArtistTitle({Key? key, this.artistName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      artistName ?? "",
      style: theme.textTheme.subtitle1!.copyWith(
        fontSize: 12.0,
        color: Colors.white70,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

class PlayerScreen extends StatelessWidget {
  static final String routeName = "/player";

  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBarSettings(
        centerTitle: true,
        title: Text(
          "NOW PLAYING",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.0),
        ),
      ),
      body: (context) => PlayerView(),
      disableBottomBar: true,
    );
  }
}

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final playerManager = getIt<PlayerManager>();
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: playerManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: playerManager.seek,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  final double size;

  const PlayButton({
    Key? key,
    this.size = 32.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerManager = getIt<PlayerManager>();
    return ValueListenableBuilder<PlayButtonState>(
      valueListenable: playerManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case PlayButtonState.loading:
            return Container(
              margin: EdgeInsets.all(8.0),
              width: size,
              height: size,
              child: CircularProgressIndicator(),
            );
          case PlayButtonState.paused:
            return IconButton(
              icon: Icon(Icons.play_arrow),
              iconSize: size,
              onPressed: playerManager.play,
            );
          case PlayButtonState.playing:
            return IconButton(
              icon: Icon(Icons.pause),
              iconSize: size,
              onPressed: playerManager.pause,
            );
        }
      },
    );
  }
}