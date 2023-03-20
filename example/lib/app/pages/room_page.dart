import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:openvidu_client/openvidu_client.dart';
import 'package:openvidu_client_example/app/utils/extensions.dart';
import 'package:openvidu_client_example/app/widgets/config_view.dart';

import '../models/connection.dart';
import '../models/session.dart';
import '../utils/logger.dart';
import '../widgets/media_stream_view.dart';

class RoomPage extends StatefulWidget {
  final Session room;
  final String userName;
  final String serverUrl;
  final String secret;
  const RoomPage(
      {super.key,
      required this.room,
      required this.userName,
      required this.serverUrl,
      required this.secret});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  List<RemoteParticipant> remoteParticipants = [];
  List<dynamic> localTrack = [];
  MediaDeviceInfo? input;
  bool isInside = false;
  late OpenViduClient _openvidu;

  LocalParticipant? localParticipant;

  @override
  void initState() {
    super.initState();
    initOpenVidu();
    _listenSessionEvents();
  }

  Future<void> initOpenVidu() async {
    _openvidu = OpenViduClient('https://demos.openvidu.io/openvidu');
    localParticipant =
        await _openvidu.startLocalPreview(context, StreamMode.frontCamera);
    setState(() {});
  }

  void _listenSessionEvents() {
    _openvidu.on(OpenViduEvent.userJoined, (params) async {
      await _openvidu.subscribeRemoteStream(params["id"]);
    });
    _openvidu.on(OpenViduEvent.userPublished, (params) {
      _openvidu.subscribeRemoteStream(params["id"]);
    });

    _openvidu.on(OpenViduEvent.addStream, (params) {
      remoteParticipants = [..._openvidu.participants];
      logger.d(remoteParticipants);
      setState(() {});
    });

    _openvidu.on(OpenViduEvent.removeStream, (params) {
      setState(() {
        remoteParticipants = [..._openvidu.participants];
      });
    });

    _openvidu.on(OpenViduEvent.error, (params) {
      context.showErrorDialog(params["error"]);
    });
  }

  Future<void> _onConnect() async {
    final dio = Dio();
    dio.options.baseUrl = '${widget.serverUrl}/openvidu/api';
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["authorization"] =
        'Basic ${base64Encode(utf8.encode('OPENVIDUAPP:${widget.secret}'))}';
    try {
      var response = await dio.post(
        '/sessions/${widget.room.sessionId}/connection',
        data: {"type": widget.room.type, "role": "PUBLISHER", "record": false},
      );
      final statusCode = response.statusCode ?? 400;
      if (statusCode >= 200 && statusCode < 300) {
        logger.i(response.data);
        final connection = Connection.fromJson(response.data);

        localParticipant = await _openvidu.publishLocalStream(
            token: connection.token!, userName: widget.userName);
        setState(() {
          isInside = true;
        });
      }
    } catch (e) {
      logger.e(e);
    }
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
              : Column(
                  children: [
                    Expanded(
                      child: MediaStreamView(
                        borderRadius: BorderRadius.circular(15),
                        stream: localParticipant?.stream,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: math.max(0, remoteParticipants.length),
                        itemBuilder: (BuildContext context, int index) =>
                            SizedBox(
                          width: 100,
                          height: 100,
                          child: MediaStreamView(
                            borderRadius: BorderRadius.circular(15),
                            stream: remoteParticipants[index].stream,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      // body: Column(
      //   children: [
      //     Expanded(
      //         child: participantTracks.isNotEmpty
      //             ? ParticipantWidget.widgetFor(participantTracks.first)
      //             : Container()),
      //     SizedBox(
      //       height: 100,
      //       child: ListView.builder(
      //         scrollDirection: Axis.horizontal,
      //         itemCount: math.max(0, participantTracks.length - 1),
      //         itemBuilder: (BuildContext context, int index) => SizedBox(
      //           width: 100,
      //           height: 100,
      //           child:
      //               ParticipantWidget.widgetFor(participantTracks[index + 1]),
      //         ),
      //       ),
      //     ),
      //     if (widget.room.localParticipant != null)
      //       SafeArea(
      //         top: false,
      //         child: ControlsWidget(widget.room, widget.room.localParticipant!),
      //       ),
      //   ],
      // ),
    );
  }
}
