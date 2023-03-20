import '../../openvidu_client.dart';
import '../core/stream_creator.dart';
import '../models/token.dart';
import '../support/json_rpc.dart';
import '../utils/constants.dart';
import 'connection.dart';

class RemoteParticipant extends Connection {
  final Map<String, dynamic>? metadata;
  RemoteParticipant(String id, Token token, JsonRpc rpc, this.metadata)
      : super(id, token, rpc);

  Future<void> subscribeStream(
    Function(OpenViduEvent event, Map<String, dynamic> params) dispatchEvent,
    bool video,
    bool audio,
    bool speakerphone,
  ) async {
    final connection = await peerConnection;

    connection.onAddStream = (stream) {
      this.stream = stream;
      enableVideo(video);
      enableAudio(audio);
      enableSpeakerphone(speakerphone);
      dispatchEvent(OpenViduEvent.addStream,
          {"id": id, "stream": stream, "metadata": metadata});
    };

    connection.onRemoveStream = (stream) {
      this.stream = stream;
      dispatchEvent(OpenViduEvent.removeStream, {"id": id, "stream": stream});
    };

    final streamTemp = await StreamCreator.create(StreamMode.frontCamera,
        videoParams: VideoParams.middle);

    await connection.addStream(streamTemp!);

    final offer = await connection.createOffer(constraints);

    var result = await rpc.send(
      Methods.receiveVideoFrom,
      params: {'sender': id, 'sdpOffer': offer.sdp},
      hasResult: true,
    );
    connection.setLocalDescription(offer);

    final answer = RTCSessionDescription(result['sdpAnswer'], 'answer');
    await connection.setRemoteDescription(answer);
  }

  @override
  Future<void> close() {
    stream?.dispose();
    return super.close();
  }
}
