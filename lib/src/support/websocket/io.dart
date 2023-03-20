import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/cupertino.dart';

import '../../utils/logger.dart';
import 'open_vidu_websocket.dart';

Future<WebSocketIO> lkWebSocketConnect(
  Uri uri, [
  WebSocketEventHandlers? options,
]) =>
    WebSocketIO.connect(uri, options);

class WebSocketIO extends OpenViduWebsocket {
  final io.WebSocket _ws;
  final WebSocketEventHandlers? options;
  late final StreamSubscription _subscription;

  WebSocketIO._(
    this._ws, [
    this.options,
  ]) {
    _subscription = _ws.listen(
      (dynamic data) {
        if (isDisposed) {
          logger.w('IoWebsocket already disposed, ignoring received data.');
          return;
        }
        options?.onData?.call(data);
      },
      onDone: () async {
        await _subscription.cancel();
        options?.onDispose?.call();
      },
    );

    onDispose(() async {
      if (_ws.readyState != io.WebSocket.closed) {
        await _ws.close();
      }
    });
  }

  static Future<WebSocketIO> connect(
    Uri uri, [
    WebSocketEventHandlers? options,
  ]) async {
    debugPrint(uri.toString());
    logger.d('[WebSocketIO] Connecting(uri: ${uri.toString()})...');
    try {
      final ws = await io.WebSocket.connect(uri.toString());
      logger.d('[WebSocketIO] Connected');
      return WebSocketIO._(ws, options);
    } catch (_) {
      logger.e('[WebSocketIO] did throw $_');
      throw WebSocketException.connect();
    }
  }

  @override
  void send(String data) {
    if (_ws.readyState != io.WebSocket.open) {
      logger.d('[IoWebsocket] Socket not open (state: ${_ws.readyState})');
      return;
    }

    try {
      _ws.add(data);
    } catch (_) {
      logger.d('[IoWebsocket] send did throw $_');
    }
  }
}
