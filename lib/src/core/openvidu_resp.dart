import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meta/meta.dart';

import '../models/error.dart';
import '../models/openvidu_events.dart';
import '../models/stream_mode.dart';
import '../models/token.dart';
import '../models/video_params.dart';
import '../participants/participant.dart';
import '../participants/remote_participant.dart';
import '../support/json_rpc.dart';
import '../support/platform/device_info.dart'
    if (dart.library.js) '../support/platform/device_info_web.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

part 'stream.dart';

class OpenViduClient {
  // Conecction information
  final String serverUrl;
  late Token _token;
  bool _active = true;
  JsonRpc? _rpc;

  /// map of SID to RemoteParticipant
  UnmodifiableMapView<String, RemoteParticipant> get participants =>
      UnmodifiableMapView(_participants);
  final _participants = <String, RemoteParticipant>{};

  /// the current participant
  @internal
  LocalParticipant? get localParticipant => _localParticipant;
  LocalParticipant? _localParticipant;

  EventHandler _handlers = {};

/* ---------------------------- Local Connection ---------------------------- */
  MediaStream? _localStream;
  StreamMode _mode = StreamMode.frontCamera;
  VideoParams _videoParams = VideoParams.middle;

  OpenViduClient(this.serverUrl) {
    print('INICIA OPENVIDUCLI');
    _token = Token(serverUrl);
  }

  Future<void> connect() async {
    print('Conecta');
    _rpc = JsonRpc(
      onData: _onRpcMessage,
      onError: _onSocketError,
      onDispose: () {},
    );

    try {
      await _rpc?.connect(_token.url);
      _heartbeat();
    } catch (e) {
      print(e);
      _rpc?.disconnect();
      throw NetworkError();
    }
  }

  Future<void> disconnect() async {
    await _rpc?.send(Methods.leaveRoom);

    // for (var track in StreamCreator.stream?.getTracks() ?? []) {
    //   await track?.stop();
    // }
    _active = false;
    // clean up RemoteParticipants
    var participants = _participants.values.toList();
    for (var participant in participants) {
      await participant.close();
    }
    _participants.clear();
    // clean up LocalParticipant
    await _localParticipant?.close();

    debugPrint('Cierra local');
    // if (_localParticipant == null) StreamCreator.stream?.dispose();
    await _rpc?.disconnect();
  }

  void _onSocketError(dynamic error) {
    logger.e('received websocket error $error');
  }

  Future<MediaStream?> startLocalPreview(BuildContext context, StreamMode mode,
      {VideoParams? videoParams = VideoParams.middle}) async {
    _videoParams = videoParams ?? VideoParams.middle;
    _mode = mode;
    try {
      _localStream = await createStream(_mode,
          context: context, videoParams: _videoParams);
      return _localStream;
    } catch (e) {
      logger.e('[StartPreview] $e');
      throw NotPermissionError();
    }
  }

  Future<void> stopLocalPreview() async => _localStream?.dispose();

  Future<void> publishLocalStream({
    required String token,
    required String userName,
    Map<String, dynamic>? extraData,
  }) async {
    if (_localParticipant == null || _localParticipant?.stream == null) {
      throw "Please call startLocalPreview first";
    }

    try {
      _token.setToken(token);
      final response = await _joinRoom({"clientData": userName, ...?extraData});

      _token.appendInfo(
        role: response["role"],
        coturnIp: response["coturnIp"],
        turnCredential: response["turnCredential"],
        turnUsername: response["turnUsername"],
      );

      _dispatchEvent(OpenViduEvent.joinRoom, response);

      _localParticipant = await _createParticipant(
        response["id"],
      );

      _addAlreadyInRoomConnections(response);
    } catch (e) {
      throw OtherError();
    }
  }

  Future<LocalParticipant> _createParticipant(String id) async {
    return LocalParticipant(
      id,
      _token,
      _rpc!,
      stream: _localStream!,
      mode: _mode,
      videoParams: _videoParams,
    );
  }

  void switchCamera() async {
    if (_localParticipant?.stream == null && _localStream == null) return;
    final List<MediaStreamTrack> tracks =
        _localParticipant?.stream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    Helper.switchCamera(tracks[0]);
  }

  void muteMic() {
    if (_localParticipant?.stream != null) {
      final List<MediaStreamTrack> tracks =
          _localParticipant?.stream?.getAudioTracks() ?? [];
      if (tracks.isEmpty) return;
      bool enabled = tracks[0].enabled;
      Helper.setMicrophoneMute(!enabled, tracks[0]);
    }
  }

  Future<void> publishVideo(bool enable) {
    if (_localParticipant == null) {
      throw "Please call startLocalPreview first";
    }
    return _localParticipant!.publishVideo(enable);
  }

  Future<void> publishAudio(bool enable) {
    if (_localParticipant == null) {
      throw "Please call startLocalPreview first";
    }
    return _localParticipant!.publishAudio(enable);
  }

  Future<void> subscribeRemoteStream(String id,
      {bool video = true, bool audio = true, bool speakerphone = false}) async {
    if (!_participants.containsKey(id)) return;
    _participants[id]!.subscribeStream(
      _localParticipant!.stream!,
      _dispatchEvent,
      video,
      audio,
      speakerphone,
    );
  }

  // void setRemoteVideo(String id, bool enable) {
  //   if (!_participants.containsKey(id)) return;
  //   _participants[id]!.enableVideo(enable);
  // }

  // void setRemoteAudio(String id, bool enable) {
  //   if (!_participants.containsKey(id)) return;
  //   _participants[id]!.enableAudio(enable);
  // }

  // void setRemoteSpeakerphone(String id, bool enable) {
  //   if (!_participants.containsKey(id)) return;
  //   _participants[id]!.enableSpeakerphone(enable);
  // }

  void on(OpenViduEvent event, Function(Map<String, dynamic> params) handler) {
    _handlers = {..._handlers, event: handler};
  }

  Future<Map<String, dynamic>> _joinRoom(Map<String, dynamic> metadata) async {
    final initializeParams = {
      "token": _token.url,
      "session": _token.sessionId,
      "platform": DeviceInfo.userAgent,
      "secret": "",
      "recorder": false,
      "metadata": json.encode(metadata)
    };

    try {
      return await _rpc?.send(
        Methods.joinRoom,
        params: initializeParams,
        hasResult: true,
      );
    } catch (e) {
      if (e is Map && e['code'] == 401) throw TokenError();
      throw OtherError();
    }
  }

  void _dispatchEvent(OpenViduEvent event, Map<String, dynamic> params) {
    if (event == OpenViduEvent.error) _active = false;
    logger.i(event);
    logger.i(_handlers.keys);
    if (!_handlers.containsKey(event)) return;
    final handler = _handlers[event];
    if (handler != null) handler(params);
  }

  Future<void> _heartbeat() async {
    try {
      await _rpc?.send(Methods.ping,
          params: {"interval": 3000}, hasResult: true);
    } catch (e) {
      _dispatchEvent(OpenViduEvent.error, {"error": NetworkError()});
    }

    Future<void> loop() async {
      while (_active) {
        await Future.delayed(const Duration(seconds: 3));
        if (!_active) break;

        try {
          await _rpc?.send(Methods.ping, hasResult: true);
        } catch (e) {
          _dispatchEvent(OpenViduEvent.error, {"error": NetworkError()});
        }
      }
    }

    loop();
  }

  void _addAlreadyInRoomConnections(Map<String, dynamic> model) {
    if (!model.containsKey("value")) return;
    final list = model["value"] as List<dynamic>;
    for (var c in list) {
      _addRemoteConnection(c);
    }
  }

  void _addRemoteConnection(Map<String, dynamic> model) {
    final id = model["id"];
    model["metadata"] = model["metadata"].replaceAll('}%/%{', ',');
    String userName = ''; // _getUserName(model);
    final connection =
        RemoteParticipant(id, _token, _rpc!, json.decode(model['metadata']));
    _participants[id] = connection;
    _dispatchEvent(OpenViduEvent.userJoined, {"id": id, "userName": userName});
    logger.d(model["streams"]);
    if (model["streams"] != null) {
      _dispatchEvent(
          OpenViduEvent.userPublished, {"id": id, "userName": userName});
    }
  }

  void _onRpcMessage(Map<String, dynamic> message) {
    if (!_active) return;
    if (!message.containsKey("method")) return;
    logger.i(message);
    final method = message["method"];
    final params = message["params"];

    switch (method) {
      case Events.iceCandidate:
        var id = params["senderConnectionId"];
        [
          ..._participants.entries.map((e) => e.value),
          _localParticipant,
        ].firstWhere((c) => (c?.id ?? '') == id)?.addIceCandidate(params);
        break;
      case Events.sendMessage:
        _dispatchEvent(OpenViduEvent.sendMessage, params);
        break;
      case Events.participantJoined:
        _addRemoteConnection(params);
        break;
      case Events.participantLeft:
        final id = params["connectionId"];

        if (_participants.containsKey(id)) {
          try {
            var connection = _participants[id];
            connection?.close();
            _participants.remove(id);
          } catch (e) {
            logger.w(e);
          }

          _dispatchEvent(OpenViduEvent.removeStream, {"id": id});
        }
        break;
      case Events.participantPublished:
        final id = params["id"];
        _dispatchEvent(OpenViduEvent.userPublished, {"id": id});
        break;
      case Events.participantUnpublished:
        final id = params["id"];
        _dispatchEvent(OpenViduEvent.userPublished, {"id": id});
        break;
      case Events.streamPropertyChanged:
        final eventStr = params["reason"];
        final id = params["connectionId"];
        final value = params["newValue"];

        final event = OpenViduEvent.values.firstWhere((e) {
          return e.toString().split(".")[1] == eventStr;
        });
        _dispatchEvent(event, {"id": id, "value": value});
        break;
      default:
    }
  }

  String _getUserName(Map<String, dynamic> params) {
    String userName = 'OpenVidu_User';

    try {
      if (params["metadata"] != null) {
        params["metadata"] = params["metadata"].replaceAll('}%/%{', ',');
        final clientData = json.decode(params["metadata"]);
        userName = clientData["clientData"];
      }
    } catch (e) {
      logger.w('Problem decoding metadata');
    }

    return userName;
  }
}
