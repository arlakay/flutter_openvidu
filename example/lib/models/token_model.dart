import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/token.dart';

class TokenModel extends ChangeNotifier {
  String server = "https://demos.openvidu.io/openvidu";
  String session = "ses_N21zM94yhM";
  String userName = kIsWeb
      ? 'web_user'
      : Platform.isAndroid
          ? "android_user"
          : "iphone_user";

  Future<String> getToken() async {
    final token = await Token(server, session).getToken();
    debugPrint(token);
    return token;
  }
}
