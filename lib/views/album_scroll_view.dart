import 'dart:math';

import 'package:flutter/material.dart';

import '../screens/login/album_page.dart';
import '../subsonic/models/album.dart';
import '../components/covert_art.dart';

class AlbumsScrollView extends StatelessWidget {
  final List<Album> data;
  final String title;
  final int max_count;
  final bool sort;

  AlbumsScrollView({
    Key? key,
    required this.data,
    required this.title,
    this.max_count = 0,
    this.sort = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Album> albums;

    const albumHeight = 150.0;

    if (sort) {
      data.sort((Album a, Album b) => a.year.compareTo(b.year));
    }
    albums = max_count != 0 ? data.sublist(0, min(10, max_count)) : data;

    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Row(
                children: albums
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(
                          right: 16.0,
                        ),
                        child: GestureDetector(
                          onTap: () => showModalBottomSheet(
                            isDismissible: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) => AlbumScreen(
                              albumId: a.id,
                            ),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(albumHeight / 10),
                                child: CoverArtImage(
                                  a.coverArtLink,
                                  id: a.coverArtId,
                                  height: albumHeight,
                                  width: albumHeight,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                width: albumHeight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      child: Text(a.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.subtitle1),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
