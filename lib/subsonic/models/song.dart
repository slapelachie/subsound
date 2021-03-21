class Song {
  final String id;
  final String? parent;
  final bool isDir;
  final String title;
  final String album;
  final String artist;
  final int track;
  final int year;
  final String? coverArt;
  final int size;
  final String contentType;
  final String suffix;
  final Duration duration;
  final int bitRate;
  final String path;
  final bool isVideo;
  final int playCount;
  final DateTime created;
  final String albumId;
  final String artistId;
  final String type;

  Song({
    required this.id,
    this.parent,
    this.isDir = false,
    required this.title,
    this.album = '',
    this.artist = '',
    this.track = 0,
    this.year = 0,
    this.coverArt,
    required this.size,
    required this.contentType,
    required this.suffix,
    required this.duration,
    this.bitRate = 0,
    this.path = '',
    this.isVideo = false,
    this.playCount = 0,
    required this.created,
    this.albumId = '',
    this.artistId = '',
    this.type = '',
  });

  factory Song.parse(Map<String, dynamic> data) {
    return Song(
      id: data['id'].toString(),
      parent: data['parent'].toString(),
      isDir: data['isDir'] == true ||
          data['isDir'].toString().toLowerCase() == 'true',
      title: data['title'],
      album: data['album'],
      artist: data['artist'],
      track: data['track'],
      year: data['year'],
      coverArt: data['coverArt'],
      size: data['size'],
      contentType: data['contentType'],
      suffix: data['suffix'],
      duration: Duration(seconds: data['duration']),
      bitRate: data['bitRate'],
      path: data['path'],
      isVideo: data['isVideo'],
      playCount: data['playCount'],
      created: DateTime.parse(data['created']),
      albumId: data['albumId'].toString(),
      artistId: data['artistId'].toString(),
      type: data['type'],
    );
  }

  @override
  String toString() {
    return 'Song{id: $id, title: $title}';
  }
}
