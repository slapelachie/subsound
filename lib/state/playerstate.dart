import 'dart:async';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pedantic/pedantic.dart';
import 'package:subsound/components/player.dart' hide PlayerState;
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/state/queue.dart';
import 'package:subsound/state/service_locator.dart';
import 'package:subsound/storage/cache.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_artist.dart';

import 'player_task.dart';

// Must be a top-level function
// void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

class ProgressNotifier extends ValueNotifier<ProgressBarState> {
  ProgressNotifier() : super(_initialValue);
  static const _initialValue = ProgressBarState(
    current: Duration.zero,
    buffered: Duration.zero,
    total: Duration.zero,
  );
}

class ProgressBarState {
  const ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });

  final Duration current;
  final Duration buffered;
  final Duration total;
}

class PlayButtonNotifier extends ValueNotifier<PlayButtonState> {
  PlayButtonNotifier() : super(_initialValue);
  static const _initialValue = PlayButtonState.paused;
}

enum PlayButtonState {
  paused,
  playing,
  loading,
}

class PlayerManager extends ReduxAction<AppState> {
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final playlistNotifier = ValueNotifier<List<String>>([]);
  final playButtonNotifier = PlayButtonNotifier();
  final progressNotifier = ProgressNotifier();

  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  final _audioHandler = getIt<AudioHandler>();

  void init() async {
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
  }

  void _listenToChangesInPlaylist() {
    _audioHandler.queue.listen((playlist) {
      print("playlist changed!");
      if (playlist.isEmpty) {
        playlistNotifier.value = [];
        currentSongTitleNotifier.value = '';
      } else {
        final newList = playlist.map((item) => item.title).toList();
        playlistNotifier.value = newList;
      }
    });
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      print("playback state changed!");
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = PlayButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = PlayButtonState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = PlayButtonState.playing;
      }
    });
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((current) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: current,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenToBufferedPosition() {
    _audioHandler.playbackState.listen((playbackState) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: playbackState.bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _listenToTotalDuration() {
    _audioHandler.mediaItem.listen((mediaItem) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      );
    });
  }

  void _listenToChangesInSong() {
    _audioHandler.mediaItem.listen((mediaItem) {
      currentSongTitleNotifier.value = mediaItem?.title ?? '';
    });
  }

  void play() => _audioHandler.play();

  void pause() => _audioHandler.pause();

  void seek(Duration position) => _audioHandler.seek(position);

  void previous() => _audioHandler.skipToPrevious();

  void next() => _audioHandler.skipToNext();

  void shuffle() {
    final enable = !isShuffleModeEnabledNotifier.value;
    isShuffleModeEnabledNotifier.value = enable;
    if (enable) {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

  void setQueueIndex(int? position) {
    _audioHandler.skipToQueueItem(position!);
  }

  Future<void> playSong(PlayerSong song) async {
    List<MediaItem> queue = [song.toMediaItem()];
    await _audioHandler.updateQueue(queue);
    unawaited(_audioHandler.play());
  }

  Future<void> playSongWithQueue(
      SongResult song, List<SongResult> songQueue) async {
    List<QueueItem> queue = songQueue
        .map((SongResult e) => PlayerSong.from(
              e,
            ))
        .map((song) => QueueItem(song, QueuePriority.low))
        .toList();

    var selectedIdx = queue.indexWhere((element) => element.song.id == song.id);
    final mediaQueue = songQueue
        .map((s) => s.toMediaItem(
              playNow: s.id == song.id,
            ))
        .toList();

    await _audioHandler.updateQueue(mediaQueue);
    await _audioHandler.skipToQueueItem(selectedIdx);
    unawaited(_audioHandler.play());

    return null;
  }

  Future<void> playAlbum(AlbumResultSimple album) async {
    print("album!");
    final albumData = await GetAlbum(album.id).run(state.loginState.toClient());
    final song = albumData.data.songs.first;

    await playSongWithQueue(song, albumData.data.songs);
  }

  Future<void> enqueueSong(SongResult song) async {
    final PlayerSong s = PlayerSong.from(song);
    _audioHandler.queue.value
        .add(QueueItem(s, QueuePriority.low).song.toMediaItem());
  }

  PlaybackState getPlaybackState() => _audioHandler.playbackState.value;

  void dispose() => _audioHandler.customAction('dispose');

  void stop() => _audioHandler.stop();

  @override
  Future<void> before() async {}

  @override
  FutureOr<AppState?> reduce() {}
}

abstract class PlayerActions extends ReduxAction<AppState> {
  static final String playerId = 'e5dde786-5365-11eb-ae93-0242ac130002';

  @override
  Future<void> before() async {
    // if (!AudioService.connected) {
    //   await dispatchFuture(StartupPlayer());
    // }
    // if (!AudioService.running) {
    //   await dispatchFuture(StartupPlayer());
    // }
  }
}

extension ToMediaItem on SongResult {
  MediaItem toMediaItem({bool playNow = false}) {
    final song = this;
    SongMetadata meta = SongMetadata(
      songId: song.id,
      songUrl: song.playUrl,
      fileExtension: song.suffix,
      fileSize: song.fileSize,
      contentType: song.contentType,
      playNow: playNow,
    );
    final playItem = MediaItem(
      id: song.playUrl,
      artist: song.artistName,
      album: song.albumName,
      title: song.title,
      displayTitle: song.title,
      displaySubtitle: song.artistName,
      artUri:
          song.coverArtLink.isNotEmpty ? Uri.parse(song.coverArtLink) : null,
      duration: song.duration.inSeconds > 0 ? song.duration : Duration.zero,
      extras: {},
    ).setSongMetadata(meta);

    return playItem;
  }
}

extension Formatter on PlaybackState {
  String format() {
    //return toString();
    return "PlaybackState={playing=$playing, processingState=${describeEnum(processingState)}, queueIndex=$queueIndex, errorMessage=$errorMessage, updateTime=$updateTime,updatePosition=$updatePosition, bufferedPosition=$bufferedPosition, }";
  }
}

//class CleanupPlayer extends ReduxAction<AppState> {
//  @override
//  Future<AppState> reduce() async {
//    await StartupPlayer.disconnect();
//    return state.copy();
//  }
//}

//// How much of the song to play before we scrobble.
//// 0.7 == 70% of the song.
//const scrobbleThreshold = 0.5;
//const scrobbleMinimumDuration = Duration(seconds: 30);
//const scrobbleAlwaysPlaytime = Duration(minutes: 4);
//
//class PlayerScrobbleState {
//  final bool playing;
//  final MediaItem? item;
//  final Duration? position;
//  final DateTime startedAt;
//
//  PlayerScrobbleState({
//    required this.playing,
//    this.item,
//    this.position,
//    required this.startedAt,
//  });
//
//  PlayerScrobbleState copyWith({
//    bool? playing,
//    MediaItem? item,
//    Duration? position,
//    DateTime? startedAt,
//  }) =>
//      PlayerScrobbleState(
//        playing: playing ?? this.playing,
//        item: item ?? this.item,
//        position: position ?? this.position,
//        startedAt: startedAt ?? this.startedAt,
//      );
//}
//
//final BehaviorSubject<PlayerScrobbleState> playerScrobbles =
//    BehaviorSubject.seeded(PlayerScrobbleState(
//  playing: false,
//  startedAt: DateTime.now(),
//));
//
//class StartupPlayer extends ReduxAction<AppState> {
//  static StreamSubscription<Duration>? positionStream;
//  static StreamSubscription<bool>? runningStream;
//  static StreamSubscription<PlaybackState>? playbackStream;
//  static StreamSubscription<MediaItem?>? currentMediaStream;
//  static StreamSubscription<double>? volumeStream;
//
//  Future<void> connectListeners() async {
//    await disconnect();
//    log('connectListeners() called');
//    positionStream = AudioService.createPositionStream(
//      steps: 800,
//      minPeriod: Duration(milliseconds: 500),
//      maxPeriod: Duration(milliseconds: 500),
//    ).listen((pos) {
//      //log("createPositionStream $pos");
//      PlayerStartListenPlayerPosition.updateListeners(PositionUpdate(
//        duration: state.playerState.duration,
//        position: pos,
//      ));
//      if (state.playerState.position.inSeconds != pos.inSeconds) {
//        //dispatch(PlayerPositionChanged(pos));
//      }
//    });
//
//    playbackStream = audioHandler.playbackState.listen((event) {
//      log("playbackStateStream event=${event.format()}");
//      var processingState = event.processingState;
//      if (processingState == AudioProcessingState.error) {
//        dispatch(DisplayError(
//          "${event.errorCode ?? -1}: ${event.errorMessage ?? ''}",
//        ));
//      }
//      if (state.playerState.queue.position != event.queueIndex) {
//        dispatch(PlayerSetQueueIndex(event.queueIndex));
//      }
//
//      bool wasPlaying = state.playerState.isPlaying;
//      if (wasPlaying != event.playing) {
//        playerScrobbles.add(playerScrobbles.value.copyWith(
//          playing: event.playing,
//          startedAt: DateTime.now(),
//          position: event.position,
//        ));
//      }
//      PlayerStates nextState =
//          getNextPlayerState(processingState, event.playing);
//      if (state.playerState.current != nextState) {
//        dispatch(PlayerStateChanged(nextState));
//      }
//      final currentPosition = event.position;
//      if (state.playerState.position != currentPosition) {
//        //log("updateListeners currentPosition=$currentPosition");
//        PlayerStartListenPlayerPosition.updateListeners(PositionUpdate(
//          position: currentPosition,
//          duration: state.playerState.duration,
//        ));
//      }
//    }, onError: (err, stackTrace) {
//      log("playbackStateStream error=$err", error: err);
//      Sentry.configureScope((scope) {
//        scope.setContexts("action", "playbackStateStream");
//        scope.setTag("action", "playbackStateStream");
//      });
//      Sentry.captureException(err, stackTrace: stackTrace);
//      dispatch(DisplayError("$err"));
//    });
//    currentMediaStream = audioHandler.mediaItem.listen((MediaItem? item) async {
//      log("currentMediaItemStream ${item?.toString()}");
//      if (item == null) {
//        return;
//      }
//      if (item.duration != null &&
//          item.duration != state.playerState.duration) {
//        await dispatch(PlayerDurationChanged(item.duration!));
//      }
//      var songMetadata = item.getSongMetadata();
//      var id = songMetadata.songId;
//
//      var prev = playerScrobbles.value;
//      playerScrobbles.add(prev.copyWith(
//        playing: audioHandler.playbackState.value.playing,
//        position: Duration.zero,
//        item: item,
//        startedAt: DateTime.now(),
//      ));
//
//      if (prev.playing) {
//        var duration = prev.item?.duration;
//        if (duration != null) {
//          var continuousPlayTime = DateTime.now().difference(prev.startedAt);
//          var playedPortion =
//              continuousPlayTime.inMilliseconds / duration.inMilliseconds;
//          log('playedPortion=$playedPortion prev.startedAt=${prev.startedAt}');
//
//          final prevId = prev.item?.getSongMetadata().songId;
//          // https://www.last.fm/api/scrobbling#when-is-a-scrobble-a-scrobble
//          // Send scrobble when:
//          // 1. the song has been played for more than 4 minutes OR
//          // 2. the song is longer than 30 seconds AND the song played for at least 50% of it's duration
//          //
//          // TODO(scrobble): handle scrobbling when the last track of a playqueue finishes
//          // ie. player goes to the completed state and stops playing.
//          if (prevId != null && continuousPlayTime > scrobbleAlwaysPlaytime ||
//              duration > scrobbleMinimumDuration &&
//                  playedPortion >= scrobbleThreshold) {
//            dispatch(StoreScrobbleAction(
//              prevId!,
//              playedAt: prev.startedAt,
//            ));
//          }
//        } else {
//          log('prev.item?.duration${prev.item?.duration} prev.item=${prev.item}');
//        }
//      } else {
//        log('prev.playing=${prev.playing}');
//      }
//
//      audioHandler.volumeState.listen((value) {
//        if (state.playerState.volume != value) {
//          dispatch(SetPlayerVolume(value));
//        }
//      });
//
//      if (id == state.playerState.currentSong?.id) {
//        return;
//      }
//
//      var song = state.dataState.songs.getSongId(id);
//      //final song = PlayerSong.fromMediaItem(item);
//
//      if (song == null) {
//        log('got unknown song from mediaItem: $id');
//        await dispatch(GetSongCommand(songId: id));
//        final song = state.dataState.songs.getSongId(id);
//        if (song == null) {
//          log('got API unknown song from mediaItem: $id');
//        } else {
//          var ps = PlayerSong.from(song);
//          await dispatch(PlayerCommandSetCurrentPlaying(ps));
//        }
//      } else {
//        var ps = PlayerSong.from(song);
//        await dispatch(PlayerCommandSetCurrentPlaying(ps));
//      }
//    });
//  }
//
//  static Future<void> disconnect() async {
//    await positionStream?.cancel();
//    positionStream = null;
//    await runningStream?.cancel();
//    runningStream = null;
//    await playbackStream?.cancel();
//    playbackStream = null;
//    await currentMediaStream?.cancel();
//    currentMediaStream = null;
//    await volumeStream?.cancel();
//    volumeStream = null;
//  }

class SetPlayerVolume extends ReduxAction<AppState> {
  final double volume;

  SetPlayerVolume(this.volume);

  @override
  AppState? reduce() {
    if (state.playerState.volume != volume) {
      return state.copy(
        playerState: state.playerState.copy(
          volume: volume,
        ),
      );
    }
    return null;
  }
}

PlayerStates getNextPlayerState(
  AudioProcessingState processingState,
  bool playing,
) {
  switch (processingState) {
    case AudioProcessingState.ready:
      if (playing) {
        return PlayerStates.playing;
      } else {
        return PlayerStates.paused;
      }
    case AudioProcessingState.buffering:
      if (playing) {
        return PlayerStates.buffering;
      } else {
        return PlayerStates.buffering;
      }
    case AudioProcessingState.completed:
      return PlayerStates.stopped;
    case AudioProcessingState.error:
      return PlayerStates.stopped;
    case AudioProcessingState.idle:
      return PlayerStates.stopped;
    case AudioProcessingState.loading:
      return PlayerStates.buffering;
  }
}
