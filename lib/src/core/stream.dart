part of 'openvidu_resp.dart';

extension StreamCreator on OpenViduClient {
  Future<MediaStream> createStream(
    StreamMode mode, {
    BuildContext? context,
    VideoParams? videoParams = VideoParams.middle,
  }) async {
    Map<String, dynamic> mediaConstraints = {
      'audio': mode == StreamMode.screen
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
      'video': mode == StreamMode.screen
          ? true
          : {
              'facingMode':
                  mode == StreamMode.frontCamera ? 'user' : 'environment',
              'optional': [],
            }
    };
    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }
}
