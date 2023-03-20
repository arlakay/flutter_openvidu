import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

typedef OnDisposeFunc = Future<void> Function();

mixin _Disposer {
  //
  final _disposeFuncs = <OnDisposeFunc>[];
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;
  int get disposeFuncCount => _disposeFuncs.length;

  // last added func will be called first when disposing
  void onDispose(OnDisposeFunc func) => _disposeFuncs.add(func);

  Future<bool> _dispose() async {
    if (!_isDisposed) {
      logger.d('[$objectId] dispose()');
      _isDisposed = true;
      if (_disposeFuncs.isNotEmpty) {
        logger
            .d('[$objectId] running ${_disposeFuncs.length} dispose funcs...');
        // call dispose funcs in reverse order
        for (final disposeFunc in _disposeFuncs.reversed) {
          await disposeFunc();
        }
        _disposeFuncs.clear();
        logger.d('[$objectId] dispose complete.');
      }
      return true;
    } else {
      logger.w('[$objectId] unnecessary dispose() called.');
      return false;
    }
  }
}

abstract class Disposable with _Disposer {
  @mustCallSuper
  Future<bool> dispose() async {
    return await _dispose();
  }
}

abstract class DisposableChangeNotifier extends ChangeNotifier with _Disposer {
  @override
  Future<bool> dispose() async {
    if (!isDisposed) super.dispose();
    return await super._dispose();
  }

  @override
  bool get hasListeners {
    if (isDisposed) {
      logger.w('called hasListeners on a disposed ChangeNotifier');
      return false;
    }
    return super.hasListeners;
  }

  @override
  void addListener(VoidCallback listener) {
    if (isDisposed) {
      logger.w('called addListener() on a disposed ChangeNotifier');
      return;
    }
    super.addListener(listener);
  }

  @override
  void notifyListeners() {
    if (isDisposed) {
      logger.w('called notifyListeners() on a disposed ChangeNotifier');
      return;
    }
    super.notifyListeners();
  }

  @override
  void removeListener(VoidCallback listener) {
    if (isDisposed) {
      logger.w('called removeListener() on a disposed ChangeNotifier');
      return;
    }
    super.removeListener(listener);
  }
}

extension ObjectExt on Object {
  String get objectId => '$runtimeType#$hashCode';
}
