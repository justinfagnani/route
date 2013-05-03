library stream_cleaner;

import 'dart:async';

/**
 *  A little stream helper class to which stream subscriptions can be added
 *  and then by calling [cancelAll] all subscriptions will be cancelled.
 */
class StreamCleaner {
  var _toClean = <StreamSubscription>[];

  void add(StreamSubscription s) => _toClean.add(s);

  void cancelAll() {
    _toClean.forEach((s) => s.cancel());
    _toClean.clear();
  }
}