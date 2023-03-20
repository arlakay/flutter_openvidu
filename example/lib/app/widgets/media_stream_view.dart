import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';

import 'future_wrapper.dart';

class MediaStreamView extends StatefulWidget {
  final bool mirror;
  final MediaStream? stream;
  final BorderRadiusGeometry? borderRadius;
  final String? userName;

  const MediaStreamView({
    Key? key,
    this.stream,
    this.mirror = false,
    this.borderRadius,
    this.userName,
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
    if (widget.stream == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: widget.borderRadius,
          border: Border.all(color: Colors.grey),
        ),
      );
    } else {
      return FutureWrapper(
        future: _render.initialize(),
        builder: (context) {
          _render.srcObject = widget.stream;
          return Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: widget.borderRadius,
              border: Border.all(color: Colors.grey),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                RTCVideoView(
                  _render,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: widget.mirror,
                ),
                if (widget.userName != null && widget.userName?.trim() != '')
                  Container(
                    margin: const EdgeInsets.only(top: 5.0, left: 5.0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      widget.userName ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  )
              ],
            ),
          );
        },
      );
    }
  }
}
