part of 'http.dart';

abstract class HttpResult<T> {
  HttpResult(this.statusCode);
  final int? statusCode;
}

class HttpSuccess<T> extends HttpResult<T> {
  HttpSuccess(super.statusCode, this.data);
  final T data;
}

class HttpFailure<T> extends HttpResult<T> {
  HttpFailure(super.statusCode, this.data);
  final Object? data;
}
