import 'package:dio/dio.dart';

class Token {
  final Dio _dio = Dio();
  final String _server;
  final String _session;

  Token(this._server, this._session);

  Future<Map<String, dynamic>> _getSession() async {
    var response = await _dio.get("$_server/api/Session/list");
    final sessions = response.data["content"] as List<dynamic>;
    final session = sessions.firstWhere(
      (element) => element["id"] == _session,
      orElse: () => null,
    );
    if (session != null) return session;

    response = await _dio.post(
      "$_server/api/Session",
      data: {"id": _session, "record": true},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> _getConnection() async {
    _dio.options.headers['content-Type'] = 'application/json';
    _dio.options.headers["authorization"] =
        "JWT eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjM2NiwidXNlcm5hbWUiOiJwaXJvc184NkBob3RtYWlsLmNvbSIsIm5hbWUiOnsiZmlyc3ROYW1lIjoiRGF2aWQiLCJsYXN0TmFtZSI6IkNhbGFicsOpcyJ9LCJpYXQiOjE2NzI2ODE1NTF9.-bIRWI0X3FCEnvJnPPJTafqzRtSWaXg_g8Aa3xTOvWc";
    final response = await _dio
        .post("http://192.168.0.100:3000/lessons/enter_teacher/16588");
    return response.data;
  }

  Future<String> getToken() async {
    // final session = await _getSession();
    // final sessionId = session["id"];
    final connection = await _getConnection();
    return connection['openviduToken'];
  }
}
