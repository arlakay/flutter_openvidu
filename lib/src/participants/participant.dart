import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/stream_mode.dart';
import '../models/token.dart';
import '../models/video_params.dart';
import '../support/json_rpc.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

part 'local_participant.dart';

abstract class Participant {
  final String id;
  final Token token;
  final JsonRpc rpc;
  MediaStream? stream;
  String streamId = '';
  late Future<RTCPeerConnection> peerConnection;

  final Map<String, dynamic> constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  String get sdpSemantics =>
      WebRTC.platformIsWindows ? 'plan-b' : 'unified-plan';

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  final List<RTCIceCandidate> _candidateTemps = [];

  Participant(this.id, this.token, this.rpc);

  Participant.remote(this.id, this.token, this.rpc) {
    peerConnection = _getPeerConnection();
  }

  _initPeerConnection() {
    peerConnection = _getPeerConnection();
  }

  Future<RTCPeerConnection> _getPeerConnection() async {
    final connection = await createPeerConnection(_getConfiguration(), _config);
    connection.onIceCandidate = (candidate) {
      Map<String, dynamic> iceCandidateParams = {
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'candidate': candidate.candidate,
        "endpointName": id
      };
      rpc.send(Methods.onIceCandidate, params: iceCandidateParams);
    };

    connection.onSignalingState = (state) {
      if (state == RTCSignalingState.RTCSignalingStateStable) {
        for (var i in _candidateTemps) {
          connection.addCandidate(i);
        }
        _candidateTemps.clear();
      }
    };

    return connection;
  }

  Map<String, dynamic> _getConfiguration() {
    final stun = "stun:${token.coturnIp}:3478";
    final turn1 = "turn:${token.coturnIp}:3478";
    final turn2 = "$turn1?transport=tcp";

    return {
      "sdpSemantics": sdpSemantics,
      'iceServers': [
        {
          "urls": [stun]
        },
        {
          "urls": [turn1, turn2],
          "username": token.turnUsername,
          "credential": token.turnCredential
        },
      ]
    };
  }

  Future<void> close() async {
    final connection = await peerConnection;
    connection.close();
    connection.dispose();
    stream?.dispose();
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    var connection = await peerConnection;
    final rtcIceCandidate = RTCIceCandidate(
      candidate["candidate"],
      candidate["sdpMid"],
      candidate["sdpMLineIndex"],
    );
    if (connection.signalingState ==
        RTCSignalingState.RTCSignalingStateStable) {
      await connection.addCandidate(rtcIceCandidate);
    } else {
      _candidateTemps.add(rtcIceCandidate);
    }
  }
}
