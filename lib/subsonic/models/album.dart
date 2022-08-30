import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/requests/get_cover_art.dart';

import '../requests/get_artist.dart';

Album convertFromSimpleAlbum(AlbumResultSimple album) {
  return Album(
    coverArtLink: album.coverArtId ?? '',
    coverArtId: album.coverArtId ?? '',
    artist: album.artistName,
    year: album.year,
    id: album.id,
    title: album.title,
  );
}

class Album {
  final String id;
  final String? parent;
  final String title;
  final String artist;
  final bool isDir;
  final String coverArtId;
  final String coverArtLink;
  final int year;

  Album({
    required this.id,
    this.parent,
    required this.title,
    required this.artist,
    required this.year,
    this.isDir = false,
    required this.coverArtId,
    required this.coverArtLink,
  });

  factory Album.parse(SubsonicContext ctx, Map<String, dynamic> data) {
    final coverArtId = data['coverArt'] as String?;
    final coverArtLink =
        coverArtId != null ? GetCoverArt(coverArtId).getImageUrl(ctx) : '';

    return Album(
      id: data['id'].toString(),
      parent: data['parent'] as String? ?? '',
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      year: data['year'] as int? ?? 0,
      isDir: data['isDir'] as bool? ?? false,
      coverArtId: coverArtId ?? '',
      coverArtLink: coverArtLink,
    );
  }
}
