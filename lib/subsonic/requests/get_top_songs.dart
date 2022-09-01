import 'dart:convert';

import 'package:subsound/subsonic/requests/get_album.dart';

import '../base_request.dart';
import '../context.dart';
import '../response.dart';

// TODO: change to using list of SongResult instead of Song
class TopSongsResult {
  final List<SongResult> songs;

  TopSongsResult({
    required this.songs,
  });
}

class GetTopSongs extends BaseRequest<List<SongResult>> {
  final String artist;
  final int count;

  GetTopSongs({
    required this.artist,
    this.count = 10,
  });

  @override
  String get sinceVersion => "1.2.0";

  @override
  Future<SubsonicResponse<List<SongResult>>> run(SubsonicContext ctx) async {
    print('$artist,$count');
    final response = await ctx.client.get(ctx.buildRequestUri(
      "getTopSongs",
      params: {
        'artist': '$artist',
        'count': '$count',
      },
    ));

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = json['subsonic-response'];

    if (data['status'] != 'ok') {
      throw Exception(data);
    }

    final List<dynamic>? songList = (data['topSongs']['song'] ?? []) as List<dynamic>;
    final songs =
        List<Map<String, dynamic>>.from(songList!).map((songData) {
      return SongResult.fromJson(songData, ctx);
    }).toList();

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      songs,
    );
  }
}
