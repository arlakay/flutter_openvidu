import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

part 'failure.dart';
part 'logs.dart';

enum HttpMethod { get, post, patch, delete, put }

class Http {
  Http({
    required Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final Client _client;
  final String _baseUrl;

  Future<HttpResult<R>> request<R>(
    String path, {
    required R Function(dynamic responseBody) parser,
    HttpMethod method = HttpMethod.get,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    Map<String, dynamic> body = const {},
    bool useApiKey = true,
    String languageCode = 'en',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    Map<String, dynamic> logs = {};
    StackTrace? stackTrace;
    late Uri url;
    late Request request;
    Response? response;
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        url = Uri.parse(path);
      } else {
        if (!path.startsWith('/')) {
          path = '/$path';
        }
        url = Uri.parse('$_baseUrl$path');
      }

      url = url.replace(
        queryParameters: queryParameters,
      );

      request = Request(method.name, url);
      headers = {
        ...headers,
        'Content-Type': 'application/json; charset=utf-8',
      };

      request.headers.addAll(headers);

      if (method != HttpMethod.get) {
        request.body = jsonEncode(body);
      }

      final bodyString = jsonEncode(body);
      logs = {
        'url': url.toString(),
        'method': method.name,
        'body': body,
      };

      switch (method) {
        case HttpMethod.get:
          response = await _client
              .get(
                url,
                headers: headers,
              )
              .timeout(timeout);
          break;
        case HttpMethod.post:
          response = await _client
              .post(
                url,
                headers: headers,
                body: bodyString,
              )
              .timeout(timeout);
          break;
        case HttpMethod.patch:
          response = await _client
              .patch(
                url,
                headers: headers,
                body: bodyString,
              )
              .timeout(timeout);
          break;
        case HttpMethod.delete:
          response = await _client
              .delete(
                url,
                headers: headers,
                body: bodyString,
              )
              .timeout(timeout);
          break;
        case HttpMethod.put:
          response = await _client
              .put(
                url,
                headers: headers,
                body: bodyString,
              )
              .timeout(timeout);
          break;
      }

      final statusCode = response.statusCode;
      final responseBody = _parseResponseBody(
        response.body,
      );
      logs = {
        ...logs,
        'startTime': DateTime.now().toString(),
        'statusCode': statusCode,
        'responseBody': responseBody,
      };

      if (statusCode >= 200 && statusCode < 300) {
        return HttpSuccess(
          statusCode,
          parser(
            responseBody,
          ),
        );
      }

      return HttpFailure(
        statusCode,
        responseBody,
      );
    } catch (e, s) {
      stackTrace = s;
      logs = {
        ...logs,
        'exception': e.toString(),
      };
      return HttpFailure(
        response?.statusCode,
        e,
      );
    } finally {
      logs = {
        ...logs,
        'endTime': DateTime.now().toString(),
      };
      _printLogs(logs, stackTrace);
    }
  }
}

dynamic _parseResponseBody(String responseBody) {
  try {
    return jsonDecode(responseBody);
  } catch (_) {
    return responseBody;
  }
}
