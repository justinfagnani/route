// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client;

import 'dart:html';
import 'package:logging/logging.dart';
import 'url_pattern.dart';
export 'url_pattern.dart';

final _logger = new Logger('route');

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
  String _currentPath;

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router({bool useFragment})
      : _handlers = new Map<UrlPattern, Handler>(),
        useFragment = (useFragment == null)
            ? !History.supportsState
            : useFragment;

  void addHandler(UrlPattern pattern, Handler handler) {
    _handlers[pattern] = handler;
  }

  UrlPattern _getUrl(path) {
    var matches = _handlers.keys.where((url) => url.matches(path));
    if (matches.isEmpty) {
      throw new ArgumentError("No handler found for $path");
    }
    return matches.first;
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
   * with the path version of the URL by converting the # to a /.
   */
  void handle(String path, {bool force: false}) {
    var url = _getUrl(path);
    if (url != null) {
      // always give handlers a non-fragment path
      var fixedPath = url.reverse(url.parse(path));
      if (force || fixedPath != _currentPath) {
        _currentPath = fixedPath;
        _handlers[url](fixedPath);
      }
    } else {
      _logger.info("Unhandled path: $path");
    }
  }

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   *
   * Handle routing for the current path which leads to consitent behavior
   * for all browsers.
   */
  bool listen({bool ignoreClick: false}) {
    var currentPathMatched = true;
    if (!ignoreClick) {
      window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == window.location.host) {
            var fragment = (anchor.hash == '') ? '' : '${anchor.hash}';
            gotoPath("${anchor.pathname}$fragment", anchor.title);
            e.preventDefault();
          }
        }
      });
    }
    if (useFragment) {
      try {
        handle('${window.location.pathname}${window.location.hash}');
      } on ArgumentError catch (e) {
        currentPathMatched = false;
      }
      window.onHashChange.listen((_) {
        print("location: ${window.location}");
        handle('${window.location.pathname}${window.location.hash}');
      });
    } else {
      try {
        handle(window.location.pathname);
      } on ArgumentError catch (e) {
        currentPathMatched = false;
      }
      window.onPopState.listen((_) => handle(window.location.pathname));
    }
    return currentPathMatched;
  }

  /**
   * Navigates the browser to the path produced by [url] with [args] by calling
   * [History.pushState], then invokes the handler associated with [url].
   *
   * On older browsers [Location.assign] is used instead with the fragment
   * version of the UrlPattern.
   */
  void gotoUrl(UrlPattern url, List args, String title) {
    if (_handlers.containsKey(url)) {
      var fixedPath = url.reverse(args, useFragment: useFragment);
      _go(fixedPath, title);
      _currentPath = fixedPath;
      _handlers[url](fixedPath);
    } else {
      throw new ArgumentError('Unknown URL pattern: $url');
    }
  }

  void gotoPath(String path, String title) {
    var url = _getUrl(path);
    if (url != null) {
      _go(path, title);
      _currentPath = path;
      _handlers[url](path);
    }
  }

  void _go(String path, String title) {
    title = (title == null) ? '' : title;
    if (useFragment) {
      window.location.assign(path);
      (window.document as HtmlDocument).title = title;
    } else {
      window.history.pushState(null, title, path);
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
        gotoUrl(url, args, title);
      };
}
