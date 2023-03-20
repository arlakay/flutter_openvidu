import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';
import 'package:provider/provider.dart';

import '../../../../models/call_model.dart';
import '../../../common/media_stream_view.dart';

class Opposite extends StatelessWidget {
  const Opposite({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CallModel, MediaStream?>(
      builder: (context, value, child) {
        return MediaStreamView(
          stream: value,
          mirror: true,
        );
      },
      selector: (ctx, s) => s.oppositeStream,
    );
  }
}
