// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client;

import 'dart:html';
import 'url_pattern.dart';
export 'url_pattern.dart';

typedef Handler(String path);

typedef void EventHandler(Event e);

/**
 * Stores a set of [UrlPattern] to [Handler] associations and provides methods
 * for calling a handler for a URL path, listening to [Window] history events,
 * and creating HTML event handlers that navigate to a URL.
 */
class Router {
  final Map<UrlPattern, Handler> _handlers;
  final bool useFragment;

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router({bool useFragment})
      : _handlers = new Map<UrlPattern, Handler>(),
        useFragment = (useFragment == null)
            ? History.supportsState
            : useFragment;

  void addHandler(UrlPattern pattern, Handler handler) {
    _handlers[pattern] = handler;
  }

  /**
   * Finds a matching [UrlPattern] added with [addHandler], parses the path
   * and invokes the associated callback.
   *
   * This method does not perform any navigation, [go] should be used for that.
   * This method is used to invoke a handler after some other code navigates the
   * window, such as [listen].
   *
   * If the UrlPattern contains a fragment (#), the handler is always called
   * with the path version of the URL by convertins the # to a /.
   */
  void handle(String path) {
    for (var url in _handlers.keys) {
      if (url.matches(path)) {
        // always give handlers a non-fragment path
        var fixedPath = url.reverse(url.parse(path));
        _handlers[url](fixedPath);
        break;
      }
    }
  }

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen() {
    if (useFragment) {
      window.onPopState.listen((_) => handle(window.location.pathname));
    } else {
      window.onHashChange.listen((_) =>
          handle('${window.location.pathname}#${window.location.hash}'));
    }
  }

  /**
   * Navigates the browser to the path produced by [url] with [args] by calling
   * [History.pushState], then invokes the handler associated with [url].
   *
   * On older browsers [Location.assign] is used instead with the fragment
   * version of the UrlPattern.
   */
  void go(UrlPattern url, List args, String title) {
    if (_handlers.containsKey(url)) {
      if (useFragment) {
        var path = url.reverse(args, useFragment: useFragment);
        window.history.pushState(null, title, path);
      } else {
        var path = url.reverse(args, useFragment: useFragment);
        window.location.assign(path);
      }
      _handlers[url](url.reverse(args, useFragment: useFragment));
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
  EventHandler clickHandler(UrlPattern url, List args, String title) =>
      (Event e) {
        e.preventDefault();
        go(url, args, title);
      };
}
