import 'dart:convert';

import 'package:subsound/subsonic/base_request.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_album.dart';
import 'package:subsound/subsonic/requests/get_starred2.dart';
import 'package:subsound/subsonic/response.dart';

class GetPlaylistResult {
  PlaylistResult playlist;
  final List<SongResult> entries;

  GetPlaylistResult(this.playlist, this.entries);
}

class PlaylistResult {
  final String id;
  final String name;
  final String comment;
  final int songCount;
  final Duration duration;
  final bool isPublic;
  final String owner;
  final DateTime createdAt;
  final DateTime changedAt;

  PlaylistResult({
    required this.id,
    required this.name,
    required this.comment,
    required this.songCount,
    required this.duration,
    required this.isPublic,
    required this.owner,
    required this.createdAt,
    required this.changedAt,
  });
}

class GetPlaylist extends BaseRequest<GetPlaylistResult> {
  final String id;
  GetPlaylist(this.id);

  @override
  String get sinceVersion => '1.0.0';

  @override
  Future<SubsonicResponse<GetPlaylistResult>> run(SubsonicContext ctx) async {
    final response = await ctx.client.get(ctx.buildRequestUri(
      'getPlaylist',
      params: {
        'id': this.id,
      },
    ));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (data['subsonic-response']['status'] != 'ok') {
      throw Exception(data);
    }

    final p = data['subsonic-response']['playlist'] ?? {};
    final playlist = PlaylistResult(
      id: p['id'] as String,
      name: p['name'] as String? ?? '',
      comment: p['comment'] as String? ?? '',
      songCount: p['songCount'] as int? ?? 0,
      duration: Duration(seconds: p['duration'] as int? ?? 0),
      isPublic: p['public'] as bool? ?? false,
      owner: p['owner'] as String? ?? '',
      changedAt: parseDateTime(p['changed'] as String?) ?? DateTime.now(),
      createdAt: parseDateTime(p['created'] as String?) ?? DateTime.now(),
    );

    final rawData = (data['subsonic-response']['playlist']['entry'] ?? [])
        as List<Map<String, dynamic>>;

    final List<SongResult> songs =
        rawData.map((songData) => SongResult.fromJson(songData, ctx)).toList();

    final res = GetPlaylistResult(playlist, songs);

    return SubsonicResponse(
      ResponseStatus.ok,
      data['subsonic-response']['version'] as String,
      res,
    );
  }
}
