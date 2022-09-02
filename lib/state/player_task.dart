import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/storage/cache.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    cacheManager: ArtworkCacheManager(),
    config: AudioServiceConfig(
      androidNotificationChannelName: 'SubSound',
      androidResumeOnClick: true,
      // Enable this if you want the Android service to exit the foreground state on pause.
      androidStopForegroundOnPause: false,
      androidNotificationClickStartsActivity: true,
      androidShowNotificationBadge: false,
      // androidNotificationIcon: 'mipmap/ic_launcher',
      //params: DownloadAudioTask.createStartParams(),
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _playlist = ConcatenatingAudioSource(children: []);
  final _player = AudioPlayer();

  final BehaviorSubject<double> volumeState = BehaviorSubject.seeded(1.0);

  MyAudioHandler() {
    // Broadcast which item is currently playing
    // _player.currentIndexStream.listen((index) {
    //   if (index != null) {
    //     mediaItem.add(queue.value![index]);
    //   }
    // });
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: [0, 1, 2],
        systemActions: {
          MediaAction.seek,
          // MediaAction.seekForward,
          // MediaAction.seekBackward,
        },
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    }, onError: _handleErrors, onDone: _handleDone);

    volumeState.add(_player.volume);
    _player.volumeStream.listen((event) {
      volumeState.add(event);
    });
    // skip to next song when playback completes
    _player.playbackEventStream.listen((nextState) {
      if (_player.playing &&
          nextState.processingState == ProcessingState.completed) {
        skipToNext();
      }
    }, onError: _handleErrors);
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
    });
  }

  @override
  Future<void> updateQueue(List<MediaItem> mediaItems) async {
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.clear();
    _playlist.addAll(audioSource.toList());

    final newQueue = queue.value..clear();
    newQueue..addAll(mediaItems);
    queue.add(newQueue);
    try {
      print("wait...");
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }


  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.addAll(audioSource.toList());

    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // manage Just Audio
    final audioSource = _createAudioSource(mediaItem);
    _playlist.add(audioSource);

    // notify system
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
    _player.setAudioSource(_playlist);
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.id),
    );
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    _playlist.removeAt(index);

    // notify system
    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }

  void _handleDone() {
    _handleErrors(
        "error: _handleDone called on a _player stream", StackTrace.current);
  }

  @override
  play() => _player.play();

  @override
  pause() => _player.pause();

  @override
  seek(Duration position) => _player.seek(position);

  seekTo(Duration position) => _player.seek(position);

  @override
  stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    if (_player.shuffleModeEnabled) {
      index = _player.shuffleIndices![index];
    }
    _player.seek(Duration.zero, index: index);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setVolume':
        final vol = extras?['volume'];
        if (vol is double) {
          unawaited(_player.setVolume(vol));
        }
        break;
      case 'saveBookmark':
        // app-specific code
        break;
      case 'dispose':
        await _player.dispose();
        super.stop();
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      _player.setShuffleModeEnabled(true);
    }
  }

  _handleErrors(Object e, StackTrace st) async {
    try {
      // PlatformException(-1004, Could not connect to the server., null, null)
      if (e is PlatformException && e.code == '-1004') {
        Sentry.configureScope((scope) {
          scope.setExtra("handled", true);
        });
        unawaited(Sentry.captureException(e,
            stackTrace: st, hint: {"handled": "true"}));
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: e.code,
        ));
        return;
      }
      // PlatformException(abort, Connection aborted, null, null)
      if (e is PlatformException && e.code == 'abort') {
        Sentry.configureScope((scope) {
          scope.setExtra("handled", true);
        });
        unawaited(Sentry.captureException(e,
            stackTrace: st, hint: {"handled": "true"}));
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: e.code,
        ));
        return;
      }
      // PlayerException: (-1004) Could not connect to the server.
      if (e is PlayerException && e.code == -1004) {
        Sentry.configureScope((scope) {
          scope.setExtra("handled", true);
        });
        unawaited(Sentry.captureException(e,
            stackTrace: st, hint: {"handled": "true"}));
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorCode: e.code,
          errorMessage: e.message,
        ));
        return;
      }
      Sentry.configureScope((scope) {
        scope.setExtra("handled", false);
      });
      unawaited(Sentry.captureException(e, stackTrace: st));
    } finally {
      // try stopping the player after a crash, so it hopefully can start
      // playing again when we set a new audiosource next time.
      await _player.stop();
    }
  }
}

Future<AudioSource> _toStreamSource(MediaItem mediaItem) async {
  return _toAudioSource(mediaItem, mediaItem.getSongMetadata());
}

// ignore: unused_element
Future<AudioSource> _preloadedSource(MediaItem mediaItem) async {
  SongMetadata meta = mediaItem.getSongMetadata();
  var uri = Uri.parse(meta.songUrl);

  var cacheFile = await DownloadCacheManager().loadSong(CachedSong(
    songId: meta.songId,
    songUri: uri,
    fileSize: meta.fileSize,
    fileExtension: meta.fileExtension,
  ));

  var source = AudioSource.uri(cacheFile.uri);
  return source;
}

Future<AudioSource> _toAudioSource(
  MediaItem mediaItem,
  SongMetadata meta,
) async {
  var uri = Uri.parse(meta.songUrl);

  var cacheFile = await DownloadCacheManager().getCachedSongFile(CachedSong(
    songId: meta.songId,
    songUri: uri,
    fileSize: meta.fileSize,
    fileExtension: meta.fileExtension,
  ));
  var source = LockCachingAudioSource(
    uri,
    cacheFile: cacheFile,
    //tag: ,
    headers: {
      "X-Request-ID": uuid.v1().toString(),
      "Host": uri.host,
    },
  );
  return source;
}

extension SongMeta on MediaItem {
  MediaItem setSongMetadata(SongMetadata s) {
    extras!["id"] = s.songId;
    extras!["songUrl"] = s.songUrl;
    extras!["extension"] = s.fileExtension;
    extras!["size"] = s.fileSize;
    extras!["type"] = s.contentType;
    extras!["playNow"] = s.playNow;
    return this;
  }

  SongMetadata getSongMetadata() {
    if (extras == null) {
      throw StateError('invalid mediaItem: $this');
    }
    return SongMetadata(
      songId: extras!["id"] as String,
      songUrl: extras!["songUrl"] as String,
      fileExtension: extras!["extension"] as String,
      fileSize: extras!["size"] as int,
      contentType: extras!["type"] as String,
      playNow: extras!["playNow"] as bool? ?? false,
    );
  }
}
