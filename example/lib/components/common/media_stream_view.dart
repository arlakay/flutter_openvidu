import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';

import 'future_wrapper.dart';

class MediaStreamView extends StatefulWidget {
  final bool mirror;
  final MediaStream? stream;

  const MediaStreamView({
    Key? key,
    this.stream,
    this.mirror = true,
  }) : super(key: key);

  @override
  State<MediaStreamView> createState() => _MediaStreamViewState();
}

class _MediaStreamViewState extends State<MediaStreamView> {
  late RTCVideoRenderer _render;

  @override
  void initState() {
    super.initState();
    _render = RTCVideoRenderer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stream == null) return Container(color: Colors.black);

    return FutureWrapper(
      future: _render.initialize(),
      builder: (context) {
        _render.srcObject = widget.stream;
        return RTCVideoView(
          _render,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          mirror: widget.mirror,
        );
      },
    );
  }

  @override
  void dispose() {
    if (_render.textureId != null) {
      _render.srcObject = null;
      _render.dispose();
    }
    super.dispose();
  }
}
