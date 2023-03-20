import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';
import 'package:provider/provider.dart';

import '../../../../models/call_model.dart';
import '../../../common/media_stream_view.dart';

class Self extends StatelessWidget {
  const Self({super.key});

  @override
  Widget build(BuildContext context) {
    final localStream = context.select<CallModel, MediaStream?>(
      (value) => value.localStream,
    );

    final hiddenLocal = context.select<CallModel, bool>(
      (value) => value.hiddenLocal,
    );

    return Visibility(
      visible: !hiddenLocal,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          child: MediaStreamView(
            stream: localStream,
            mirror: true,
          ),
        ),
      ),
    );
  }
}
