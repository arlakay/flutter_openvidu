import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '../../utils/logger.dart';
import 'open_vidu_websocket.dart';

Future<WebSocketWeb> lkWebSocketConnect(
  Uri uri, [
  WebSocketEventHandlers? options,
]) =>
    WebSocketWeb.connect(uri, options);

class WebSocketWeb extends OpenViduWebsocket {
  final html.WebSocket _ws;
  final WebSocketEventHandlers? options;
  late final StreamSubscription _messageSubscription;
  late final StreamSubscription _closeSubscription;

  WebSocketWeb._(
    this._ws, [
    this.options,
  ]) {
    _ws.binaryType = 'arraybuffer';
    _messageSubscription = _ws.onMessage.listen((event) {
      if (isDisposed) {
        logger.w('WebSocketWeb already disposed, ignoring received data.');
        return;
      }
      final data = json.decode(event.data) as Map<String, dynamic>;
      options?.onData?.call(data);
    });
    _closeSubscription = _ws.onClose.listen((_) async {
      await _messageSubscription.cancel();
      await _closeSubscription.cancel();
      options?.onDispose?.call();
    });

    onDispose(() async {
      if (_ws.readyState != html.WebSocket.CLOSED) {
        _ws.close();
      }
    });
  }

  static Future<WebSocketWeb> connect(
    Uri uri, [
    WebSocketEventHandlers? options,
  ]) async {
    final completer = Completer<WebSocketWeb>();
    final ws = html.WebSocket(uri.toString());
    ws.onOpen.listen((_) => completer.complete(WebSocketWeb._(ws, options)));
    ws.onError
        .listen((_) => completer.completeError(WebSocketException.connect()));
    return completer.future;
  }

  @override
  void send(String data) => _ws.send(data);
}
