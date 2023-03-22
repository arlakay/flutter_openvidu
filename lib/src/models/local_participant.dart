import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';
import '../widgets/screen_select_dialog.dart';
import 'openvidu_events.dart';
import 'participant.dart';
import 'stream_mode.dart';
import 'video_params.dart';

class LocalParticipant extends Participant {
  final bool _published = false;
  bool _audioOnly = false;
  String typeOfVideo = "CAMERA";
  int frameRate = 0;
  int width = 0;
  int height = 0;

  StreamMode _mode = StreamMode.frontCamera;
  late EventDispatcher _dispatchEvent;

  LocalParticipant.preview(
    MediaStream stream,
    EventDispatcher dispatchEvent,
  ) : super.preview() {
    _dispatchEvent = dispatchEvent;
    this.stream = stream;
    audioActive = stream.getAudioTracks().any((item) => item.enabled == true);
    videoActive = stream.getVideoTracks().any((item) => item.enabled == true);
  }

  LocalParticipant(
    super.id,
    super.token,
    super.rpc,
    super.metadata,
    EventDispatcher dispatchEvent, {
    required MediaStream stream,
    required StreamMode mode,
    required VideoParams videoParams,
  }) {
    _dispatchEvent = dispatchEvent;
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

  Future<void> _changeToCam() async {
    final width =
        (WebRTC.platformIsDesktop || WebRTC.platformIsWeb) ? '1280' : '640';
    final height =
        (WebRTC.platformIsDesktop || WebRTC.platformIsWeb) ? '720' : '480';
    stream?.getVideoTracks()[0].stop();
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'facingMode': 'user',
          'optional': [],
        },
      }
    };
    final display = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _mode = StreamMode.frontCamera;
    final connection = await peerConnection;
    final senders = await connection.senders;

    for (var sender in senders) {
      if (sender.track!.kind == 'video') {
        sender.replaceTrack(display.getVideoTracks()[0]);
      }
    }
    stream = display;
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
  }

  Future<void> _changeToScreen(BuildContext context) async {
    try {
      Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': true,
      };
      late MediaStream screen;
      if (WebRTC.platformIsDesktop) {
        // ignore: use_build_context_synchronously
        final source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (context) => ScreenSelectDialog(),
        );
        screen = await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
          'video': source == null
              ? true
              : {
                  'deviceId': {'exact': source.id},
                  'mandatory': {'frameRate': 30.0}
                }
        });
      } else {
        screen = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      }

      final connection = await peerConnection;
      final senders = await connection.senders;

      for (var sender in senders) {
        if (sender.track!.kind == 'video') {
          sender.replaceTrack(screen.getVideoTracks()[0]);
        }
      }
      _mode = StreamMode.screen;
      screen.getVideoTracks()[0].onEnded = () async {
        await _changeToCam();
      };

      stream = screen;
      _dispatchEvent(OpenViduEvent.updatedLocal,
          {'mode': _mode, 'localParticipant': this});
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> shareScreen(BuildContext context) async {
    try {
      if (stream == null) return;
      if (_mode == StreamMode.screen) {
        _changeToCam();
      } else {
        _changeToScreen(context);
      }
    } catch (e) {
      logger.e(e);
    }
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
    final devices = await Helper.cameras;
    final track = stream?.getVideoTracks().firstOrNull;
    if (track == null) return;
    final newTrack = devices.firstWhereOrNull((el) => el.deviceId == track.id);
    if (newTrack == null) return;
    Helper.switchCamera(track, newTrack.deviceId, stream);
  }

  Future<void> unpublishAllTracks() async {
    if (stream == null) return;
    stream!.getTracks().forEach((MediaStreamTrack e) => e.enabled = false);
    videoActive = false;
    audioActive = false;
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
    if (!_published) return;
    await _streamPropertyChanged("videoActive", videoActive, "publishVideo");
    await _streamPropertyChanged("audioActive", audioActive, "publishAudio");
  }

  Future<void> publishVideo(bool enable) async {
    if (stream == null) return;
    stream!
        .getVideoTracks()
        .forEach((MediaStreamTrack e) => e.enabled = enable);
    videoActive = enable;
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
    if (!_published) return;
    await _streamPropertyChanged("videoActive", videoActive, "publishVideo");
  }

  Future<void> publishAudio(bool enable) async {
    if (stream == null) return;
    stream!.getAudioTracks().forEach((e) => e.enabled = enable);
    audioActive = enable;
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
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
