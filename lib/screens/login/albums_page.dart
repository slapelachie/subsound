import 'package:flutter/material.dart';
import 'package:subsound/screens/login/album_page.dart';
import 'package:subsound/subsonic/context.dart';
import 'package:subsound/subsonic/models/album.dart';
import 'package:subsound/subsonic/requests/get_album_list.dart';
import 'package:subsound/subsonic/requests/get_album_list2.dart';

class AlbumsPage extends StatefulWidget {
  final SubsonicContext ctx;

  const AlbumsPage({Key? key, required this.ctx}) : super(key: key);

  @override
  State<AlbumsPage> createState() {
    return AlbumsPageState(ctx);
  }
}

class AlbumRow extends StatelessWidget {
  final Album album;
  final Function(Album) onTap;

  const AlbumRow({
    Key? key,
    required this.album,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        this.onTap(album);
      },
      // leading: CoverArtImage(
      //   album.coverArtLink,
      //   id: album.coverArtLink,
      //   width: 48.0,
      //   height: 48.0,
      // ),
      // leading: Image.network(
      //   album.coverArtLink,
      //   //id: album.coverArtId,
      //   width: 48.0,
      //   height: 48.0,
      // ),
      title: Text(album.title),
      subtitle: Text(album.artist),
    );
  }
}

class AlbumsListView extends StatelessWidget {
  final SubsonicContext ctx;
  final List<Album> albums;
  final ScrollController controller;
  final bool isLoading;
  final void Function() loadMore;

  const AlbumsListView({
    Key? key,
    required this.ctx,
    required this.albums,
    required this.controller,
    required this.isLoading,
    required this.loadMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: this._handleScrollNotification,
      child: CustomScrollView(
        controller: controller,
        physics: BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, idx) {
                return AlbumRow(
                  album: albums[idx],
                  onTap: (album) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AlbumScreen(
                        albumId: album.id,
                      ),
                    ));
                  },
                );
              },
              childCount: albums.length,
            ),
          ),
          if (isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Center(
                  child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator()),
                ),
              ),
            )
        ],
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (controller.position.extentAfter == 0) {
        loadMore();
      }
    }
    return false;
  }
}

class AlbumsPageState extends State<AlbumsPage> {
  final SubsonicContext ctx;

  final int pageSize = 30;
  List<Album> _albumList = [];
  bool hasMore = true;
  bool isLoading = false;
  late ScrollController _controller;

  late Future<List<Album>> initialLoad;

  AlbumsPageState(this.ctx);

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    isLoading = true;
    initialLoad = load(offset: 0, pageSize: pageSize).then((value) {
      if (!this.mounted) {
        return value;
      }
      setState(() {
        isLoading = false;
        _albumList.addAll(value);
      });
      return value;
    });
    initialLoad.whenComplete(() {
      if (!this.mounted) {
        return;
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<List<Album>>(
            future: initialLoad,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  _albumList = snapshot.data!;
                  return AlbumsListView(
                    ctx: ctx,
                    controller: _controller,
                    albums: _albumList,
                    isLoading: isLoading,
                    loadMore: this.loadMore,
                  );
                }
              }
            }));
  }

  Future<void> loadMore() {
    if (hasMore && !isLoading) {
      setState(() {
        isLoading = true;
      });

      return load(
        pageSize: 30,
        offset: _albumList.length,
      ).then((value) {
        setState(() {
          _albumList.addAll(value);
          isLoading = false;
        });
      }).whenComplete(() => {
            setState(() {
              isLoading = false;
            })
          });
    }
    return Future.value(null);
  }

  Future<List<Album>> load({
    int pageSize = 50,
    int offset = 0,
  }) {
    return GetAlbumList2(
      type: GetAlbumListType.alphabeticalByName,
      size: pageSize,
      offset: offset,
    ).run(ctx).then((value) => value.data).then((List<Album> nextList) {
      if (nextList.length < pageSize) {
        setState(() {
          hasMore = false;
        });
      }
      return nextList;
    });
  }
}
