import 'package:flutter/widgets.dart';

class ConversationModel extends ChangeNotifier {
  CallMode _callMode = CallMode.None;
  bool _isCallOffer = false;

  CallMode get callMode => _callMode;
  bool get isCallOffer => _isCallOffer;

  void startCall(CallMode mode, bool isOffer) {
    _callMode = mode;
    _isCallOffer = isOffer;
    notifyListeners();
  }

  void stopCall() {
    _callMode = CallMode.None;
    notifyListeners();
  }
}

// ignore: constant_identifier_names
enum CallMode { None, Audio, Video }
