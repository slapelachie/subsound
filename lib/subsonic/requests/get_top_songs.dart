import 'dart:convert';

import '../base_request.dart';
import '../context.dart';
import '../models/song.dart';
import '../response.dart';

class TopSongsResult {
  final List<Song> songs;

  TopSongsResult({
    required this.songs,
  });
}

class GetTopSongs extends BaseRequest<List<Song>> {
  final String artist;
  final int count;

  GetTopSongs({
    required this.artist,
    this.count = 10,
  });

  @override
  String get sinceVersion => "1.2.0";

  @override
  Future<SubsonicResponse<List<Song>>> run(SubsonicContext ctx) async {
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

    print(data['topSongs']);

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      ((data['topSongs']['song'] ?? []) as List)
          .map((song) => Song.parse(song as Map<String, dynamic>))
          .toList(),
    );
  }
}
