import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';
import 'openvidu_events.dart';
import 'participant.dart';

class RemoteParticipant extends Participant {
  RemoteParticipant(super.id, super.token, super.rpc, super.metadata);

  Future<void> subscribeStream(
    MediaStream localStream,
    EventDispatcher dispatchEvent,
    bool video,
    bool audio,
    bool speakerphone,
  ) async {
    try {
      final connection = await peerConnection;

      connection.onIceConnectionState = (state) {
        logger.d('onIceConnectionState = $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          connection.restartIce();
        }
      };

      connection.onRenegotiationNeeded = () async {
        return _createOffer(await peerConnection);
      };

      if (sdpSemantics == "plan-b") {
        connection.onRemoveStream = (stream) {
          logger.d('onRemoveStream = ${stream.toString()}');

          this.stream = stream;
          dispatchEvent(OpenViduEvent.removeStream, {"id": id, "stream": stream, "metadata": metadata});
        };

        connection.onAddStream = (stream) {
          logger.d('onAddStream = ${stream.toString()}');
          this.stream = stream;
          audioActive = audio;
          videoActive = video;
          dispatchEvent(OpenViduEvent.addStream, {"id": id, "stream": stream, "metadata": metadata});
        };

        connection.addStream(localStream);
      }

      if (sdpSemantics == "unified-plan") {
        connection.onRemoveTrack = (stream, track) {
          logger.d('onRemoveTrack1 = ${stream.toString()}');
          logger.d('onRemoveTrack2 = ${track.toString()}');

          this.stream = stream;
          dispatchEvent(OpenViduEvent.removeStream, {"id": id, "stream": stream, "metadata": metadata});
        };

        connection.onAddTrack = (stream, track) {
          logger.d('onAddTrack1 = ${stream.toString()}');
          logger.d('onAddTrack2 = ${track.toString()}');

          this.stream = stream;
          audioActive = audio;
          videoActive = video;
          dispatchEvent(OpenViduEvent.addStream, {"id": id, "stream": stream, "metadata": metadata});
        };

        final localTracks = localStream.getTracks();
        logger.d('localTrack = ${localTracks.toString()}');
        for (var track in localTracks) {
          connection.addTrack(track, localStream);
        }
      }
    } catch (e) {
      logger.e(e);
    }
  }

  _createOffer(RTCPeerConnection connection) async {
    final offer = await connection.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      "optional": [
        {'DtlsSrtpKeyAgreement': true}
      ],
    });

    await connection.setLocalDescription(offer);

    connection.onIceGatheringState = (state) async {
      logger.d(' onIceGatheringState= ${state.name}');

      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        final result = await rpc.send(
          Methods.receiveVideoFrom,
          params: {
            'sdpOffer': offer.sdp,
            'sender': id,
          },
          hasResult: true,
        );

        logger.d('receiveVideoFrom = $result');

        final answer = RTCSessionDescription(result['sdpAnswer'], 'answer');
        await connection.setRemoteDescription(answer);
      }
    };
  }

  @override
  Future<void> close() {
    stream?.getTracks().forEach((track) async {
      await track.stop();
      logger.i(track.toString());
    });
    stream?.dispose();
    stream = null;

    return super.close();
  }
}
