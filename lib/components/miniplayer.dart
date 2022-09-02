import 'dart:async';
import 'dart:developer';

import 'package:async_redux/async_redux.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:subsound/components/covert_art.dart';
import 'package:subsound/components/player.dart';
import 'package:subsound/state/appcommands.dart';
import 'package:subsound/state/appstate.dart';
import 'package:subsound/state/playerstate.dart';
import 'package:subsound/subsonic/requests/star.dart';

import '../state/service_locator.dart';

class PlayerBottomBar extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final Function onTap;

  PlayerBottomBar({
    Key? key,
    required this.height,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: MiniPlayer(
        height: height,
        backgroundColor: backgroundColor,
        onTap: onTap,
      ),
    );
  }
}

class _MiniPlayerModelFactory extends VmFactory<AppState, MiniPlayer> {
  _MiniPlayerModelFactory(MiniPlayer widget) : super(widget);

  @override
  MiniPlayerModel fromStore() {
    return MiniPlayerModel.from(state, dispatch);
  }
}

class MiniPlayerModel extends Vm {
  final bool hasCurrentSong;
  final String? songId;
  final String? songTitle;
  final String? artistTitle;
  final String? albumTitle;
  final String? coverArtLink;
  final String coverArtId;
  final Duration duration;
  final double playbackProgress;
  final double volume;
  final PlayerStates playerState;
  final Function(String) onStar;
  final Function(String) onUnstar;
  final bool isStarred;

  MiniPlayerModel({
    required this.hasCurrentSong,
    required this.songId,
    required this.songTitle,
    required this.artistTitle,
    required this.albumTitle,
    required this.coverArtLink,
    required this.coverArtId,
    required this.duration,
    required this.playbackProgress,
    required this.volume,
    required this.playerState,
    required this.onStar,
    required this.onUnstar,
    required this.isStarred,
  }) : super(equals: [
          hasCurrentSong,
          songId,
          artistTitle ?? '',
          songTitle ?? '',
          albumTitle ?? '',
          coverArtLink ?? '',
          coverArtId,
          duration,
          volume,
          playerState,
          isStarred,
        ]);

  static MiniPlayerModel from(AppState state, Dispatch<AppState> dispatch) {
    final pos = state.playerState.position.inMilliseconds;
    final durSafe = state.playerState.duration.inMilliseconds;
    final dur = durSafe == 0 ? 1 : durSafe;
    final playbackProgress = pos / dur;
    final currentSong = state.playerState.currentSong;

    return MiniPlayerModel(
      hasCurrentSong: currentSong != null,
      songId: currentSong?.id ?? '',
      songTitle: currentSong?.songTitle ?? '',
      artistTitle: currentSong?.artist ?? '',
      albumTitle: currentSong?.album ?? '',
      coverArtLink: currentSong?.coverArtLink ?? '',
      coverArtId: currentSong?.coverArtId ?? '',
      duration: state.playerState.duration,
      playbackProgress: playbackProgress,
      volume: state.playerState.volume,
      playerState: state.playerState.current,
      onStar: (next) => dispatch(StarIdCommand(SongId(songId: next))),
      onUnstar: (next) => dispatch(UnstarIdCommand(SongId(songId: next))),
      isStarred: currentSong?.isStarred ?? false,
    );
  }
}


class MiniAudioProgressBar extends StatelessWidget {
  const MiniAudioProgressBar({Key? key}) : super(key: key);
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
          thumbRadius: 0.0,
        );
      },
    );
  }
}

class MiniPlayer extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final Function onTap;

  final double _miniProgressBarHeight = 2.0;

  MiniPlayer({
    Key? key,
    required this.height,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = height - _miniProgressBarHeight;
    final playerManager = getIt<PlayerManager>();

    return StoreConnector<AppState, MiniPlayerModel>(
      vm: () => _MiniPlayerModelFactory(this),
      builder: (context, state) => AnimatedContainer(
        height: playerManager.getPlaybackState() == MediaAction.stop? 0 : 50.0,
        duration: Duration(milliseconds: 100),
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              MiniAudioProgressBar(),
              SizedBox(
                height: playerHeight,
                child: InkWell(
                  onTap: () {
                    onTap();
                  },
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        state.coverArtLink != null
                            ? CoverArtImage(
                                state.coverArtLink,
                                id: state.coverArtId,
                                height: playerHeight,
                                width: playerHeight,
                                fit: BoxFit.fitHeight,
                              )
                            : Padding(
                                padding: EdgeInsets.only(left: 10.0),
                                child: Icon(Icons.album),
                              ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              state.songTitle ?? 'Nothing playing',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              state.artistTitle ?? 'Artistic',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 11.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.only(right: 5.0),
                          child: PlayButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}