import 'package:flutter/widgets.dart';
import 'package:openvidu_client/openvidu_client.dart';

import '../app/utils/logger.dart';

class CallModel extends ChangeNotifier {
  OpenViduClient? _session;
  MediaStream? _localStream;
  MediaStream? _oppositeStream;
  String _oppositeId = '';
  bool _float = false;
  bool _enterd = false;
  OpenViduError? _error;

  MediaStream? get localStream => _localStream;
  MediaStream? get oppositeStream => _oppositeStream;
  bool get float => _float;
  bool get enterd => _enterd;
  bool get floatSelf => _oppositeStream != null;
  bool get hiddenLocal => floatSelf && _float;
  OpenViduError? get error => _error;

  set float(bool value) {
    _float = value;
    notifyListeners();
  }

  Future<void> start(BuildContext context, String userName, String token,
      StreamMode mode) async {
    print('HACE LA LLAMADA');
    logger.i('HACE LA LLAMADA');
    try {
      _session = OpenViduClient(token);
      // _localStream = await _session!.startLocalPreview(context, mode);
      _listenSessionEvents();
      // await _session!.connect();

      await _session!.publishLocalStream(token: token, userName: 'Usuario');
      notifyListeners();
    } catch (e) {
      logger.e(e);
      _error = e is OpenViduError ? e : OtherError();
      await stop();
    }
  }

  enter() async {
    if (_enterd || _session == null) return;
    // await _session!.publishLocalStream();
    // await _session!.publishLocalStream();
    _enterd = true;
    notifyListeners();
  }

  void _listenSessionEvents() {
    if (_session == null) return;
    _session!.on(OpenViduEvent.joinRoom, (params) => null);
    _session!.on(OpenViduEvent.userJoined, (params) async {
      await _session!.subscribeRemoteStream(params["id"]);
    });
    _session!.on(OpenViduEvent.userPublished, (params) {
      logger.i(params);
      _session!.subscribeRemoteStream(params["id"]);
    });

    _session!.on(OpenViduEvent.addStream, (params) {
      _oppositeStream = params["stream"];
      debugPrint('INICIA');
      debugPrint(params.toString());
      _oppositeId = params["id"];
      notifyListeners();
    });

    _session!.on(OpenViduEvent.removeStream, (params) {
      if (params["id"] == _oppositeId) {
        _oppositeStream = null;
        notifyListeners();
      }
    });

    _session!.on(OpenViduEvent.error, (params) {
      if (params.containsKey("error")) {
        _error = params["error"];
      } else {
        _error = OtherError();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  Future<void> stop() async {
    debugPrint('desconecta');
    await _session?.disconnect();
    _session = null;
  }
}
