// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client;

import 'dart:html';
import 'url_pattern.dart';
export 'url_pattern.dart';

typedef Handler(String path);

class Router {
  final Map<UrlPattern, Handler> _handlers;

  Router() : _handlers = new Map<UrlPattern, Handler>();

  void addHandler(UrlPattern pattern, Handler handler) {
    _handlers[pattern] = handler;
  }

  /**
   * Finds a matching [UrlPattern] added with [addHandler], parses the path
   * and invokes the associated callback.
   */
  handle(String path) {
    for (var url in _handlers.keys) {
      if (url.matches(path)) {
        _handlers[url](path);
        break;
      }
    }
  }

  /** Listens for window history events and invokes the router. */
  listen() {
    window.on.popState.add((_) => handle(window.location.pathname));
  }

  /** Looks up the handler associated with [url] and calls it with [args]. */
  go(UrlPattern url, List args) {
    if (_handlers.containsKey(url)) {
      _handlers[url](url.reverse(args));
    } else {
      throw new ArgumentError('Unknown URL pattern: $url');
    }
  }

  /**
   * Returns an [Event] handler suitable for use as a click handler on [:<a>;]
   * elements. The handler reverses [ur] with [args] and uses [window.pushState]
   * with [title] to change the user visible URL without navigating to it.
   * [Event.preventDefault] is called to stop the default behavior. Then the
   * handler associated with [url] is invoked with [args].
   */
  clickHandler(UrlPattern url, List args, String title) => (Event e) {
    var path = url.reverse(args);
    window.history.pushState(null, title, path);
    e.preventDefault();
    go(url, args);
  };
}
