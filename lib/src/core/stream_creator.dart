import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/stream_mode.dart';
import '../models/video_params.dart';
import '../widgets/screen_select_dialog.dart';

class StreamCreator {
  static MediaStream? _stream;
  static StreamMode? _mode;
  static VideoParams? _videoParams;

  static MediaStream? get stream => _stream;
  static StreamMode get mode => _mode ?? StreamMode.frontCamera;
  static VideoParams get videoParams => _videoParams ?? VideoParams.low;

  static Future<MediaStream?> create(
    StreamMode mode, {
    BuildContext? context,
    VideoParams? videoParams,
  }) async {
    if (_stream != null) await _stream!.dispose();
    _mode = mode;
    _videoParams = videoParams ?? VideoParams.low;
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

    if (_mode == StreamMode.screen) {
      if (WebRTC.platformIsDesktop && context != null) {
        // ignore: use_build_context_synchronously
        final source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (context) => ScreenSelectDialog(),
        );
        _stream =
            await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
          'video': source == null
              ? true
              : {
                  'deviceId': {'exact': source.id},
                  'mandatory': {'frameRate': 30.0}
                }
        });
      } else {
        _stream =
            await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      }
    } else {
      _stream = await navigator.mediaDevices
          .getUserMedia({'audio': true, 'video': true});
    }

    return _stream;
  }

  static Future<void> dispose() async {
    stream?.getTracks().forEach((track) async {
      debugPrint(track.toString());
      await track.stop();
    });
    await _stream?.dispose();
    _stream = null;
    _mode = null;
    _videoParams = null;
  }
}
