import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs [callback] off the UI isolate in production.
///
/// [AutomatedTestWidgetsFlutterBinding] does not pump isolate completions as
/// frames, so widget tests (and the `test` package zone) run the work in a
/// later event instead. The caller still `await`s, so `_confirm` is not
/// synchronous on the tap. Production uses [compute] / `Isolate.run`.
Future<R> offUiCompute<Q, R>(ComputeCallback<Q, R> callback, Q message) {
  if (Zone.current[#test.declarer] != null) {
    return Future<R>(() => callback(message));
  }
  return compute(callback, message);
}
