import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SummaryView extends StatelessWidget {
  final List<Widget> slivers;

  SummaryView({
    this.slivers = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    Widget makeDismissible({required Widget child}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: GestureDetector(
            onTap: () {},
            child: child,
          ),
        );

    return SlidableAutoCloseBehavior(
      child: makeDismissible(
        child: DraggableScrollableSheet(
          maxChildSize: 1.0,
          minChildSize: 0.8,
          initialChildSize: 0.8,
          builder: (context, controller) => Container(
            padding: EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(15.0),
              ),
            ),
            child: CustomScrollView(
              controller: controller,
              slivers: slivers,
            ),
          ),
        ),
      ),
    );
  }
}
