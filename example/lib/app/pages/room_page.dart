import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';
import 'package:openvidu_client_example/app/widgets/config_view.dart';
import 'package:openvidu_client_example/app/widgets/controls.dart';
import 'package:openvidu_client_example/app/widgets/media_stream_view.dart';

import '../models/connection.dart';
import '../models/session.dart';
import '../utils/logger.dart';

class RoomPage extends StatefulWidget {
  final Session room;
  final String userName;
  final String serverUrl;
  final String secret;
  const RoomPage(
      {super.key, required this.room, required this.userName, required this.serverUrl, required this.secret});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  Map<String, RemoteParticipant> remoteParticipants = {};
  MediaDeviceInfo? input;
  bool isInside = false;
  late OpenViduClient _openvidu;

  LocalParticipant? localParticipant;

  bool isCenteredLocalParticipantCamera = true;

  List<MediaDevice>? _audioInputs;
  List<MediaDevice>? _audioOutputs;
  List<MediaDevice>? _videoInputs;
  MediaDevice? selectedAudioInput;
  MediaDevice? selectedVideoInput;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = Hardware.instance.onDeviceChange.stream.listen((List<MediaDevice> devices) {
      _loadDevices(devices);
    });
    Hardware.instance.enumerateDevices().then(_loadDevices);

    initOpenVidu();
    _listenSessionEvents();

    // if (!isInside) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _onConnect();
    //   });
    // }
  }

  void _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
    logger.d('cek audio input = $_audioInputs');
    logger.d('cek video input = $_videoInputs');

    selectedAudioInput = _audioInputs?.first;
    selectedVideoInput = _videoInputs?.singleWhere((element) => element.label.toLowerCase().contains('front'));
    setState(() {});
  }

  Future<void> initOpenVidu() async {
    final securityContext = SecurityContext();

    _openvidu = OpenViduClient('${widget.serverUrl}/openvidu', securityContext);
    localParticipant = await _openvidu.startLocalPreview(context, StreamMode.frontCamera);
    setState(() {});
  }

  void _listenSessionEvents() {
    _openvidu.on(OpenViduEvent.userJoined, (params) async {
      logger.d('check userJoined = ${params["id"]}');
      await _openvidu.subscribeRemoteStream(params["id"]);
      setState(() {});
    });
    _openvidu.on(OpenViduEvent.userPublished, (params) {
      logger.d('check userPublished = ${params["id"]}');
      _openvidu.subscribeRemoteStream(params["id"], video: params["videoActive"], audio: params["audioActive"]);
      setState(() {});
    });

    _openvidu.on(OpenViduEvent.addStream, (params) {
      remoteParticipants = {..._openvidu.participants};
      setState(() {});
    });

    _openvidu.on(OpenViduEvent.removeStream, (params) async {
      remoteParticipants = {..._openvidu.participants};
      setState(() {});
    });

    _openvidu.on(OpenViduEvent.publishVideo, (params) {
      remoteParticipants = {..._openvidu.participants};
      setState(() {});
    });
    _openvidu.on(OpenViduEvent.publishAudio, (params) {
      // remoteParticipants = {..._openvidu.participants};
      // setState(() {});
    });
    _openvidu.on(OpenViduEvent.updatedLocal, (params) {
      localParticipant = params['localParticipant'];
      setState(() {});
    });
    _openvidu.on(OpenViduEvent.reciveMessage, (params) {
      // context.showMessageRecivedDialog(params["data"] ?? '');
      // setState(() {});
    });
    _openvidu.on(OpenViduEvent.userUnpublished, (params) {
      remoteParticipants = {..._openvidu.participants};
      setState(() {});
    });

    _openvidu.on(OpenViduEvent.error, (params) {
      // context.showErrorDialog(params["error"]);
    });
  }

  Future<void> _onConnect() async {
    final dio = Dio();
    dio.options.baseUrl = '${widget.serverUrl}/openvidu/api';
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["authorization"] = 'Basic ${base64Encode(utf8.encode('OPENVIDUAPP:${widget.secret}'))}';
    try {
      var response = await dio.post(
        '/sessions/${widget.room.sessionId}/connection',
        data: {"type": widget.room.type, "role": "MODERATOR", "record": false},
      );
      final statusCode = response.statusCode ?? 400;
      if (statusCode >= 200 && statusCode < 500) {
        logger.i(response.data);
        final connection = Connection.fromJson(response.data);

        localParticipant = await _openvidu.publishLocalStream(token: connection.token!, userName: widget.userName);
        setState(() {
          isInside = true;
        });
      }
    } catch (e) {
      logger.e(e);
    }
  }

  void _onChange() {
    // trigger refresh
    Future.delayed(
      const Duration(milliseconds: 2000),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: localParticipant == null
          ? Container()
          : !isInside
              ? ConfigView(
                  participant: localParticipant!,
                  onConnect: _onConnect,
                  userName: widget.userName,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _onChange();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                top: 0,
                                child: isCenteredLocalParticipantCamera
                                    ? MediaStreamView(
                                        borderRadius: BorderRadius.circular(0),
                                        participant: localParticipant!,
                                      )
                                    : MediaStreamView(
                                        borderRadius: BorderRadius.circular(0),
                                        participant: remoteParticipants.values.first,
                                      ),
                              ),
                              Positioned(
                                bottom: 150,
                                right: 0,
                                left: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: SizedBox(
                                    width: 50,
                                    height: 213,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 213,
                                          child: ListView.builder(
                                              reverse: true,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: math.max(0, remoteParticipants.length),
                                              itemBuilder: (BuildContext context, int index) {
                                                final remote = remoteParticipants.values.elementAt(index);
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      isCenteredLocalParticipantCamera =
                                                          !isCenteredLocalParticipantCamera;
                                                    });
                                                  },
                                                  child: SizedBox(
                                                    width: 150,
                                                    height: 213,
                                                    child: isCenteredLocalParticipantCamera
                                                        ? MediaStreamView(
                                                            borderRadius: BorderRadius.circular(8),
                                                            participant: remote,
                                                          )
                                                        : MediaStreamView(
                                                            borderRadius: BorderRadius.circular(8),
                                                            participant: localParticipant!,
                                                          ),
                                                  ),
                                                );
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                right: 0,
                                left: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                  child: Container(
                                    child: Column(
                                      children: [
                                        if (localParticipant != null)
                                          SafeArea(
                                            top: false,
                                            child: ControlsWidget(_openvidu, localParticipant!),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
