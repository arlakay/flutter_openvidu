import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/error.dart';
import '../models/local_participant.dart';
import '../models/openvidu_events.dart';
import '../models/ov_message.dart';
import '../models/remote_participant.dart';
import '../models/stream_mode.dart';
import '../models/token.dart';
import '../models/video_params.dart';
import '../support/json_rpc.dart';
import '../support/platform/device_info.dart'
    if (dart.library.js) '../support/platform/device_info_web.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../widgets/screen_select_dialog.dart';

class OpenViduClient {
  late Token _token;
  bool _active = true;
  JsonRpc? _rpc;
  String _userId = '';

  EventHandler _handlers = {};

  /* ---------------------------- LOCAL CONNECCTION --------------------------- */
  StreamMode _mode = StreamMode.frontCamera;
  VideoParams _videoParams = VideoParams.middle;

  LocalParticipant? _localParticipant;

  /* --------------------------- REMOTE CONNECTIONS --------------------------- */

  /// map of SID to RemoteParticipant
  UnmodifiableMapView<String, RemoteParticipant> get participants =>
      UnmodifiableMapView(_participants);
  final _participants = <String, RemoteParticipant>{};

  OpenViduClient(String serverUrl) {
    print('INICIA OPENVIDUCLI');
    _token = Token(serverUrl);
  }

  Future<LocalParticipant?> startLocalPreview(
      BuildContext context, StreamMode mode,
      {VideoParams? videoParams = VideoParams.middle}) async {
    _videoParams = videoParams ?? VideoParams.middle;
    _mode = mode;

    _rpc = JsonRpc(
      onData: _onRpcMessage,
      onError: _onSocketError,
      onDispose: () {},
    );

    try {
      await _rpc?.connect(_token.wss);
      _heartbeat();
    } catch (e) {
      logger.e(e);
      _rpc?.disconnect();
      throw NetworkError();
    }

    try {
      if (_rpc == null) return null;
      // ignore: use_build_context_synchronously
      final stream = await _createStream(context);
      _localParticipant = LocalParticipant.preview(stream, _dispatchEvent);
      return _localParticipant;
    } catch (e) {
      logger.e('[StartPreview] $e');
      throw NotPermissionError();
    }
  }

  Future<void> stopLocalPreview() async => disconnect();

  Future<LocalParticipant?> publishLocalStream({
    required String token,
    required String userName,
    Map<String, dynamic>? extraData,
  }) async {
    if (_localParticipant == null || _localParticipant?.stream == null) {
      throw "Please call startLocalPreview first";
    }
    _token.setToken(token);
    try {
      final response = await _joinRoom({"clientData": userName, ...?extraData});
      _userId = response["id"];

      _token.appendInfo(
        role: response["role"],
        coturnIp: response["coturnIp"],
        turnCredential: response["turnCredential"],
        turnUsername: response["turnUsername"],
      );
      Map<String, dynamic> metadata = {};
      try {
        metadata = json.decode(response["metadata"]);
      } catch (e) {
        logger.e(e);
      }
      _localParticipant = await _createParticipant(response["id"], metadata);
      _dispatchEvent(OpenViduEvent.joinRoom, response);

      _addAlreadyInRoomConnections(response);
      return _localParticipant;
    } catch (e) {
      throw OtherError();
    }
  }

  Future<bool> sendMessage(OvMessage message) async {
    if (_localParticipant == null || _localParticipant?.stream == null) {
      return false;
    }
    try {
      await _rpc?.send(
        "sendMessage",
        params: {"message": message.toRawJson()},
        hasResult: true,
      );
      return true;
    } catch (e) {
      logger.i('SEND MESSAGE', e.toString());
      return false;
    }
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

  void _addRemoteConnection(Map<String, dynamic> model) {
    final id = model["id"];
    if (id == _userId) return;
    model["metadata"] = model["metadata"].replaceAll('}%/%{', ',');
    final connection =
        RemoteParticipant(id, _token, _rpc!, json.decode(model['metadata']));
    _participants[id] = connection;
    _dispatchEvent(OpenViduEvent.userJoined, {"id": id});
    logger.d(model["streams"]);
    if (model["streams"] != null) {
      _dispatchEvent(OpenViduEvent.userPublished, {"id": id});
    }
  }

  void _addAlreadyInRoomConnections(Map<String, dynamic> model) {
    if (!model.containsKey("value")) return;
    final list = model["value"] as List<dynamic>;
    for (var c in list) {
      _addRemoteConnection(c);
    }
  }

  Future<Map<String, dynamic>> _joinRoom(Map<String, dynamic> metadata) async {
    final initializeParams = {
      "token": _token.token,
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

  Future<LocalParticipant> _createParticipant(
      String id, Map<String, dynamic> metadata) async {
    final locaStream = _localParticipant!.stream!;
    return LocalParticipant(
      id,
      _token,
      _rpc!,
      metadata,
      _dispatchEvent,
      stream: locaStream,
      mode: _mode,
      videoParams: _videoParams,
    );
  }

  Future<MediaStream> _createStream(BuildContext context) async {
    Map<String, dynamic> mediaConstraints = {
      'audio': _mode == StreamMode.screen
          ? false
          : {
              'optional': {
                'echoCancellation': true,
                'googDAEchoCancellation': true,
                'googEchoCancellation': true,
                'googEchoCancellation2': true,
                'noiseSuppression': true,
                'googNoiseSuppression': true,
                'googNoiseSuppression2': true,
                'googAutoGainControl': true,
                'googHighpassFilter': false,
                'googTypingNoiseDetection': true,
              },
            },
      'video': _mode == StreamMode.screen
          ? true
          : {
              'facingMode':
                  _mode == StreamMode.frontCamera ? 'user' : 'environment',
              'optional': [],
            }
    };
    late MediaStream stream;
    if (_mode == StreamMode.screen) {
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
    } else {
      stream = await navigator.mediaDevices
          .getUserMedia({'audio': true, 'video': true});
    }

    return stream;
  }

  /* ----------------------------- SOCKET MANAGER ----------------------------- */

  void on(OpenViduEvent event, Function(Map<String, dynamic> params) handler) {
    _handlers = {..._handlers, event: handler};
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
        _dispatchEvent(OpenViduEvent.reciveMessage, params);
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
        final param = params as Map<String, dynamic>;
        final id = params["id"];

        final stream =
            param.containsKey('streams') ? param["streams"][0] : null;
        _dispatchEvent(OpenViduEvent.userPublished, {
          "id": id,
          "audioActive": stream['audioActive'] ?? false,
          "videoActive": stream['videoActive'] ?? false,
        });
        break;
      case Events.participantUnpublished:
        final id = params["id"];
        _dispatchEvent(OpenViduEvent.userUnpublished, {"id": id});
        break;
      case Events.streamPropertyChanged:
        final eventStr = params["reason"];
        final id = params["connectionId"];
        final property = params["property"] as String;
        final value = params["newValue"];
        if (_participants.containsKey(id)) {
          final remoteParticipant = _participants[id];
          if (property == 'videoActive') {
            logger.i(remoteParticipant!.videoActive);
            remoteParticipant.videoActive = value == 'true';
            logger.i(remoteParticipant.videoActive);
          }
          if (property == 'audioActive') {
            remoteParticipant!.videoActive = value == 'true';
          }
        }
        final event = OpenViduEvent.values.firstWhere((e) {
          return e.toString().split(".")[1] == eventStr;
        });
        _dispatchEvent(event, {"id": id, "value": value});
        break;
      default:
    }
  }

  void _onSocketError(dynamic error) {
    logger.e('received websocket error $error');
  }

  Future<void> _heartbeat() async {
    try {
      await _rpc?.send(Methods.ping,
          params: {"interval": 5000}, hasResult: true);
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

  void _dispatchEvent(OpenViduEvent event, Map<String, dynamic> params) {
    if (event == OpenViduEvent.error) _active = false;
    if (!_handlers.containsKey(event)) return;
    final handler = _handlers[event];
    if (handler != null) handler(params);
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
}
