import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../models/call_model.dart';
import 'video/opposite.dart';
import 'video/self.dart';

class VideoPanel extends StatefulWidget {
  const VideoPanel({Key? key}) : super(key: key);

  @override
  State<VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<VideoPanel> {
  final self = const Self();
  final opposite = const Opposite();

  @override
  Widget build(BuildContext context) {
    final srceen = MediaQuery.of(context);

    return Stack(
      children: [
        opposite,
        Selector<CallModel, bool>(
          builder: (context, value, child) {
            if (value) {
              return Positioned(
                width: 100,
                height: 150,
                right: 20 + srceen.padding.right,
                top: 20 + srceen.padding.top,
                child: self,
              );
            } else {
              return self;
            }
          },
          selector: (ctx, s) => s.floatSelf,
        )
      ],
    );
  }
}
