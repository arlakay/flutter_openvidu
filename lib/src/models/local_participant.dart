import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';
import '../widgets/screen_select_dialog.dart';
import 'participant.dart';
import 'stream_mode.dart';
import 'video_params.dart';

class LocalParticipant extends Participant {
  final bool _published = false;
  bool _audioOnly = false;
  bool audioActive = true;
  bool videoActive = false;
  String typeOfVideo = "CAMERA";
  int frameRate = 0;
  int width = 0;
  int height = 0;

  StreamMode _mode = StreamMode.frontCamera;

  LocalParticipant.preview(MediaStream stream) : super.preview() {
    this.stream = stream;
  }

  LocalParticipant(
    super.id,
    super.token,
    super.rpc, {
    required MediaStream stream,
    required StreamMode mode,
    required VideoParams videoParams,
  }) {
    _mode = mode;
    this.stream = stream;
    audioActive = true;

    if (mode == StreamMode.audio) {
      _audioOnly = true;
    } else {
      _audioOnly = false;
      videoActive = true;
    }

    if (mode == StreamMode.screen) typeOfVideo = "SCREEN";

    audioActive = stream.getAudioTracks().any((item) => item.enabled == true);
    videoActive = stream.getVideoTracks().any((item) => item.enabled == true);

    frameRate = videoParams.frameRate;
    width = videoParams.width;
    height = videoParams.height;
    _publishLocalStream();
  }

  Future<void> _publishLocalStream() async {
    if (stream == null || _published == true) return;
    try {
      final connection = await peerConnection;
      switch (sdpSemantics) {
        case "plan-b":
          connection.addStream(stream!);
          break;
        case "unified-plan":
          stream?.getTracks().forEach((track) {
            connection.addTrack(track, stream!);
          });
          break;
        default:
      }

      final offer = await connection.createOffer(constraints);
      connection.setLocalDescription(offer);

      final result = await rpc.send(
        Methods.publishVideo,
        params: {
          'audioOnly': _audioOnly,
          'hasAudio': true,
          'doLoopback': false,
          'hasVideo': true,
          'audioActive': audioActive,
          'videoActive': videoActive,
          'typeOfVideo': typeOfVideo,
          'frameRate': frameRate,
          'videoDimensions': json.encode({"width": width, "height": height}),
          'sdpOffer': offer.sdp
        },
        hasResult: true,
      );

      streamId = result["id"];
      final answer = RTCSessionDescription(result['sdpAnswer'], 'answer');
      await connection.setRemoteDescription(answer);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> shareScreen(BuildContext context) async {
    Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': true,
    };
    if (WebRTC.platformIsDesktop) {
      // ignore: use_build_context_synchronously
      final source = await showDialog<DesktopCapturerSource>(
        context: context,
        builder: (context) => ScreenSelectDialog(),
      );
      stream = await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
        'video': source == null
            ? true
            : {
                'deviceId': {'exact': source.id},
                'mandatory': {'frameRate': 30.0}
              }
      });
    } else {
      stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
    }

    final connection = await peerConnection;
    final senders = await connection.senders;

    for (var sender in senders) {
      if (sender.track!.kind == 'video') {
        sender.replaceTrack(stream?.getVideoTracks()[0]);
      }
    }
    _mode = StreamMode.screen;
  }

  Future<void> setAudioInput(String deviceId) async {
    final connection = await peerConnection;
    final senders = await connection.senders;

    for (var sender in senders) {
      if (sender.track!.kind == 'audio') {
        sender.replaceTrack(stream?.getTrackById(deviceId));
      }
    }
  }

  Future<void> selectVideoInput(String deviceId) async {
    final track = stream?.getVideoTracks().firstOrNull;
    if (track == null) return;
    await Helper.switchCamera(track, deviceId, stream);
  }

  void switchCamera() async {
    if (stream == null) return;
    final List<MediaStreamTrack> tracks = stream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    Helper.switchCamera(tracks[0]);
  }

  Future<void> publishVideo(bool enable) async {
    if (stream == null) return;
    stream!.getVideoTracks().forEach((e) => e.enabled = enable);
    videoActive = enable;
    if (!_published) return;
    await _streamPropertyChanged("videoActive", videoActive, "publishVideo");
  }

  Future<void> publishAudio(bool enable) async {
    if (stream == null) return;
    stream!.getAudioTracks().forEach((e) => e.enabled = enable);
    audioActive = enable;
    if (!_published) return;
    await _streamPropertyChanged("audioActive", audioActive, "publishAudio");
  }

  Future<void> _streamPropertyChanged(
    String property,
    Object value,
    String reason,
  ) async {
    if (!rpc.isActive) return;
    await rpc.send(
      "streamPropertyChanged",
      params: {
        "streamId": streamId,
        "property": property,
        "newValue": value,
        "reason": reason,
      },
    );
  }
}
