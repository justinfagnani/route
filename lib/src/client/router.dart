// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of route.client;


/**
 * A [Router] provides an interface for controlling and listening to the
 * window location in a structured, hierarchical manner.
 *
 * Stores a set of [UrlPattern] to [Handler] associations and provides methods
 * for calling a handler for a URL path, listening to [Window] history events,
 * and creating HTML event handlers that navigate to a URL.
 */
class Router {
  final Route root;
  final bool _useFragment;
  final html.Window _window;
  bool _listen = false;

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router(Map<String, Route> routes, {String index, bool useFragment,
      html.Window window})
      : root = new Route._(new UriTemplate(''), index: index)
            ..addRoutes(routes),
        _useFragment = (useFragment == null)
            ? !html.History.supportsState
            : useFragment,
        _window = (window == null) ? html.window : window {
    root._router = this;
  }

  Route operator [](String name) => root._children[name];

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen({bool ignoreClick: false}) {
    _logger.finest('listen ignoreClick=$ignoreClick');
    if (_listen) {
      throw new StateError('listen can only be called once');
    }
    _listen = true;
    _window.onPopState.listen((_) {
      var path = '${_window.location.pathname}${_window.location.hash}';
      var location = _window.location;
      var uri = new Uri(
//          scheme: location.protocol,
          host: location.host,
//          port: location.port,
          path: location.pathname,
          query: location.search,
          fragment: location.hash);
      root._enter(uri).then((allowed) {
        // if not allowed, we need to restore the browser location
        if (!allowed) _window.history.forward();
      });
    });
    if (!ignoreClick) {
      _logger.finest('listen on win: $_window');
      _window.onClick.listen((html.Event e) {
        if (e.target is html.AnchorElement) {
          var anchor = e.target;
          if (anchor.host == _window.location.host) {
            _logger.finest('clicked ${anchor.pathname}${anchor.hash}');
            e.preventDefault();
            var path = '${anchor.pathname}';
            var uri = new Uri(
                path: anchor.pathname,
                query: anchor.search,
                fragment: anchor.hash);
            root._enter(uri).then((allowed) {
              if (allowed) _navigate(uri, null, false);
            });
          }
        }
      });
    }
  }

  String _normalizeHash(String hash) => hash.isEmpty ? '' : hash.substring(1);

  /**
   * Navigates the browser to the path produced by [url] with [args] by calling
   * [History.pushState], then invokes the handler associated with [url].
   *
   * On older browsers [Location.assign] is used instead with the fragment
   * version of the UrlPattern.
   */
//  Future<bool> navigate(String url) {
//    return route(url).then((success) {
//      if (success) {
//        _go(url, null, false);
//      }
//    });
//  }

  void _navigate(Uri uri, String title, bool replace) {
    title = (title == null) ? '' : title;
    if (replace) {
      _window.history.replaceState(null, title, uri.toString());
    } else {
      _window.history.pushState(null, title, uri.toString());
    }
  }
}
