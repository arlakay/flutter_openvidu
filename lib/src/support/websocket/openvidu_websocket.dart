import 'dart:async';

import '../../models/error_code.dart' as error_code;

typedef WebSocketOnData = Function(Map<String, dynamic> data);
typedef WebSocketOnError = Function(dynamic error);
typedef WebSocketOnDispose = Function();

class WebSocketEventHandlers {
  final WebSocketOnData? onData;
  final WebSocketOnError? onError;
  final WebSocketOnDispose? onDispose;

  const WebSocketEventHandlers({
    this.onData,
    this.onError,
    this.onDispose,
  });
}

abstract class OpenViduWebsocket {
  final int internalId = 0;
  final Map<int, Request> pendingRequests = {};

  Future<void> connect(String url);
  Future<dynamic>? send(
    String method, {
    Map<String, dynamic> params = const {},
    bool hasResult = false,
  });

  Future<void> disconnect();

  void handleResponse(response) {
    if (response is List) {
      response.forEach(_handleSingleResponse);
    } else {
      _handleSingleResponse(response);
    }
  }

  void _handleSingleResponse(response) {
    if (!_isResponseValid(response)) return;
    var id = response['id'];
    id = (id is String) ? int.parse(id) : id;
    var request = pendingRequests.remove(id)!;
    if (response.containsKey('result')) {
      request.completer.complete(response['result']);
    } else {
      request.completer.completeError(
        RpcException(response['error']['code'], response['error']['message'],
            data: response['error']['data']),
      );
    }
  }

  bool _isResponseValid(response) {
    if (response is! Map) return false;
    if (response['jsonrpc'] != '2.0') return false;
    var id = response['id'];
    id = (id is String) ? int.parse(id) : id;
    if (!pendingRequests.containsKey(id)) return false;
    if (response.containsKey('result')) return true;

    if (!response.containsKey('error')) return false;
    var error = response['error'];
    if (error is! Map) return false;
    if (error['code'] is! int) return false;
    if (error['message'] is! String) return false;
    return true;
  }
}

class Request {
  /// THe method that was sent.
  final String method;

  /// The completer to use to complete the response future.
  final Completer completer;

  Request(this.method, this.completer);
}

class RpcException implements Exception {
  final int code;
  final String message;
  final Object? data;

  RpcException(this.code, this.message, {this.data});
  RpcException.methodNotFound(String methodName)
      : this(error_code.METHOD_NOT_FOUND, 'Unknown method "$methodName".');

  RpcException.invalidParams(String message)
      : this(error_code.INVALID_PARAMS, message);

  Map<String, dynamic> serialize(request) {
    dynamic modifiedData;
    if (data is Map && !(data as Map).containsKey('request')) {
      modifiedData = Map.from(data as Map);
      modifiedData['request'] = request;
    } else if (data == null) {
      modifiedData = {'request': request};
    } else {
      modifiedData = data;
    }

    var id = request is Map ? request['id'] : null;
    if (id is! String && id is! num) id = null;
    return {
      'jsonrpc': '2.0',
      'error': {'code': code, 'message': message, 'data': modifiedData},
      'id': id
    };
  }

  @override
  String toString() {
    var prefix = 'JSON-RPC error $code';
    var errorName = error_code.name(code);
    if (errorName != null) prefix += ' ($errorName)';
    return '$prefix: $message';
  }
}
