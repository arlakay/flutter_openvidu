import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/stream_mode.dart';
import '../models/token.dart';
import '../models/video_params.dart';
import '../support/json_rpc.dart';
import '../utils/constants.dart';
import 'connection.dart';

class LocalParticipant extends Connection {
  LocalParticipant(String id, Token token, JsonRpc rpc) : super(id, token, rpc);

  bool audioOnly = false;
  bool hasAudio = true;
  bool hasVideo = false;
  bool audioActive = true;
  bool videoActive = false;
  String typeOfVideo = "CAMERA";
  int frameRate = 0;
  int width = 0;
  int height = 0;
  final bool doLoopback = false;

  void setStream(
    MediaStream stream,
    StreamMode mode,
    VideoParams videoParams,
  ) {
    this.stream = stream;
    audioActive = true;
    hasAudio = true;

    if (mode == StreamMode.audio) {
      audioOnly = true;
    } else {
      hasVideo = true;
      videoActive = true;
    }

    if (mode == StreamMode.screen) typeOfVideo = "SCREEN";

    frameRate = videoParams.frameRate;
    width = videoParams.width;
    height = videoParams.height;
  }

  Future<void> publishStream(bool video, bool audio) async {
    if (stream == null) return;
    final connection = await peerConnection;
    enableVideo(video);
    enableAudio(audio);

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
        'audioOnly': audioOnly,
        'hasAudio': hasAudio,
        'doLoopback': doLoopback,
        'hasVideo': hasVideo,
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
  }

  Future<void> publishVideo(bool enable) async {
    if (stream == null) return;
    stream!.getVideoTracks().forEach((e) => e.enabled = enable);
    videoActive = enable;
    await _streamPropertyChanged("videoActive", videoActive, "publishVideo");
  }

  Future<void> publishAudio(bool enable) async {
    if (stream == null) return;
    stream!.getAudioTracks().forEach((e) => e.enabled = enable);
    audioActive = enable;
    await _streamPropertyChanged("audioActive", audioActive, "publishAudio");
  }

  Future<void> _streamPropertyChanged(
    String property,
    Object value,
    String reason,
  ) async {
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

  @override
  Future<void> close() {
    stream?.getTracks().forEach((track) async {
      debugPrint(track.toString());
      await track.stop();
    });
    stream?.dispose();
    return super.close();
  }
}
