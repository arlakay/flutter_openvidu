import '../../openvidu_client.dart';
import '../models/token.dart';
import '../support/json_rpc.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'participant.dart';

class RemoteParticipant extends Participant {
  final Map<String, dynamic>? metadata;
  RemoteParticipant(String id, Token token, JsonRpc rpc, this.metadata)
      : super(id, token, rpc);

  Future<void> subscribeStream(
    MediaStream stream,
    EventDispatcher dispatchEvent,
    bool video,
    bool audio,
    bool speakerphone,
  ) async {
    try {
      final connection = await peerConnection;

      connection.onAddStream = (stream) {
        this.stream = stream;
        dispatchEvent(OpenViduEvent.addStream,
            {"id": id, "stream": stream, "metadata": metadata});
      };

      connection.onRemoveStream = (stream) {
        this.stream = stream;
        dispatchEvent(OpenViduEvent.removeStream, {"id": id, "stream": stream});
      };

      await connection.addStream(stream);

      final offer = await connection.createOffer(constraints);

      var result = await rpc.send(
        Methods.receiveVideoFrom,
        params: {'sender': id, 'sdpOffer': offer.sdp},
        hasResult: true,
      );
      connection.setLocalDescription(offer);

      final answer = RTCSessionDescription(result['sdpAnswer'], 'answer');
      await connection.setRemoteDescription(answer);
    } catch (e) {
      logger.e(e);
    }
  }

  @override
  Future<void> close() {
    stream?.getTracks().forEach((track) async {
      await track.stop();
      logger.i(track.toString());
    });
    stream?.dispose();
    return super.close();
  }
}
