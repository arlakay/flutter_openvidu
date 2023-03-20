part of 'participant.dart';

class LocalParticipant extends Participant {
  bool _published = false;
  bool _audioOnly = false;
  bool audioActive = true;
  bool videoActive = false;
  String typeOfVideo = "CAMERA";
  int frameRate = 0;
  int width = 0;
  int height = 0;

  LocalParticipant(
    super.id,
    super.token,
    super.rpc, {
    required MediaStream stream,
    required StreamMode mode,
    required VideoParams videoParams,
  }) {
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
      await _initPeerConnection();
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
    if (!rpc.isActive || !_published) return;
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
      await track.stop();
    });
    _published = false;
    logger.i('$objectId Closed');
    stream?.dispose();
    return super.close();
  }
}
