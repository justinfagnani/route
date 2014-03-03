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
  Router(Map<String, Route> routes, {String index, String defaultRoute,
    bool useFragment, html.Window window})
      : root = new Route(uri(''), index: index, defaultRouteName: defaultRoute),
        _useFragment = (useFragment == null)
            ? !html.History.supportsState
            : useFragment,
        _window = (window == null) ? html.window : window {
    root.._router = this
        ..addRoutes(routes);
  }

  Route operator [](String path) => root[path];

  String toString() => 'Router';

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  // TODO: add element to listen on
  void listen({bool ignoreClick: false}) {
    _logger.fine('listen ignoreClick=$ignoreClick');
    if (_listen) {
      throw new StateError('listen can only be called once');
    }
    _listen = true;
    _window.onPopState.listen((_) {
      var uri = uriFromLocation(_window.location);
      navigate(uri).then((allowed) {
        // if not allowed, we need to restore the browser location
        if (!allowed) _window.history.forward();
      });
    });
    if (!ignoreClick) {
      _window.on[NAVIGATE].listen((html.CustomEvent e) {
        navigate(Uri.parse(e.detail['href']));
      });
      // This only works with light DOM
      _window.onClick.listen((html.Event e) {
        if (e.target is html.AnchorElement) {
          html.AnchorElement anchor = e.target;
          if (anchor.host == _window.location.host) {
            _logger.finest('clicked ${anchor.pathname}${anchor.hash}');
            e.preventDefault();
            var path = '${anchor.pathname}';
            var uri = new Uri(
                path: anchor.pathname,
                query: anchor.search,
                fragment: anchor.hash);
            navigate(uri);
          }
        }
      });
    }
  }

  /**
   * Navigates the browser to the path produced by [url] with [args] by calling
   * [History.pushState], then invokes the handler associated with [url].
   *
   * On older browsers [Location.assign] is used instead with the fragment
   * version of the UrlPattern.
   */
  Future<bool> navigate(Uri uri, {String title, bool replace}) {
    Iterable<RouteMatch> matches = root.match(uri);
    if (matches.isEmpty) {
      return new Future.value(false);
    }
    if (matches.last.rest != null && matches.last.rest.path.isNotEmpty) {
      // we're not at a valid leaf, but what about index routes?
      _logger.severe("${matches.last.rest} should be null");
      throw new ArgumentError();
    }

    // TODO: handle cases:
    // no current route
    // test: new route and old route are same

    // Find the top-most route that we're leaving
    // 1) find the current route
    Route exitRoot = root._currentChild;
    Route enterRoot;
    // 2) find where it diverges from the proposed route
    for (var match in matches) {
      enterRoot = match.route;
      if (match.route != exitRoot) break;
      exitRoot = exitRoot._currentChild;
    }

    Future future;

    if (exitRoot == null) {
      future = enterRoot._beforeEnter(matches, {}).then((allowed) {
        if (allowed != true) return false;
        return enterRoot._onEnter(matches, {});
      });
    } else {
      future = exitRoot._beforeExit().then((allowed) {
        if (allowed != true) return false;
        return enterRoot._beforeEnter(matches, {}).then((allowed) {
          if (allowed != true) return false;
          return exitRoot._onExit().then((allowed) {
            if (allowed != true) return false;
            return enterRoot._onEnter(matches, {});
          });
        });
      });
    }

    return future.then((succeeded) {
      if (succeeded) {
        _navigateBrowser(uri, title: title, replace: replace);
      }
      return succeeded;
    });
  }

  void _navigateBrowser(Uri uri, {String title, bool replace}) {
    title = (title == null) ? '' : title;
    replace = (replace == null) ? false : replace;
    if (replace) {
      _window.history.replaceState(null, title, uri.toString());
    } else {
      _window.history.pushState(null, title, uri.toString());
    }
  }
}
