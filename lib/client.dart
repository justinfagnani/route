// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client;

import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'url_pattern.dart';
export 'url_pattern.dart';

final _logger = new Logger('route');

typedef Handler(String path);

typedef void EventHandler(Event e);

typedef void RouteEnterCallback(RouteEvent e);

typedef Future<bool> RouteLeaveCallback(RouteEvent e);

/**
 * Ane event that is fired when entering or leaving a route.
 */
class RouteEvent {
  final Router router;
  final RoutePath current;
  final RoutePath previous;
  RouteEvent(this.router, this.current, this.previous);
}

class RoutePath {
  final String path;
  final List<String> matches;
  RoutePath(this.path, this.matches);
}

/**
 * Stores a set of [UrlPattern] to [Handler] associations and provides methods
 * for calling a handler for a URL path, listening to [Window] history events,
 * and creating HTML event handlers that navigate to a URL.
 */
class Router {
  final Map<UrlPattern, Router> _routes;
  final bool useFragment;
  final StreamController<RouteEvent> _onRouteController;

  Stream<RouteEvent> get onRoute {
    return _onRouteController.stream;
  }

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router({bool useFragment, Router parentRouter})
      : _routes = new Map<UrlPattern, Router>(),
        _onRouteController = new StreamController<RouteEvent>(),
        useFragment = (useFragment == null)
            ? !History.supportsState
            : useFragment;

  void addRoute({Pattern path, Pattern prefix, RouteEnterCallback enter,
      RouteLeaveCallback leave, dynamic mount}) {
    var childRouter = new Router(useFragment: useFragment, parentRouter: this);
    if (enter != null) {
      childRouter.onRoute.listen(enter);
    }
    // TODO(pavelgj): add leave.
    var pattern = _makePattern(path, prefix);
    _routes[pattern] = childRouter;
  }

  UrlPattern _makePattern(Pattern path, Pattern prefix) {
    // TODO(pavelgj): implement actual pattern.
    return path != null ? path: prefix;
  }

  UrlPattern _getUrl(path) => _routes.keys.firstWhere((url) =>
      url.matches(path), orElse: () => null);

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
  void route(String path) {
    var url = _getUrl(path);
    if (url != null) {
      // always give handlers a non-fragment path
      var fixedPath = url.reverse(url.parse(path));
      var tail = _getTail(url, path);
      _routes[url]._propagate(fixedPath, tail, url.parse(path));
    } else {
      _logger.info("Unhandled path: $path");
    }
  }

  String _getTail(UrlPattern pattern, String path) {
    // TODO(pavelgj): implement cutting of the tail.
    return path;
  }

  void _propagate(String path, String tail, List<String> groups) {
    _onRouteController.add(new RouteEvent(this, new RoutePath(path, groups), null));
    route(tail);
  }

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen({bool ignoreClick: false}) {
    if (useFragment) {
      window.onHashChange.listen((_) =>
          handle('${window.location.pathname}#${window.location.hash}'));
    } else {
      window.onPopState.listen((_) => handle(window.location.pathname));
    }
    if (!ignoreClick) {
      window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == window.location.host) {
            var fragment = (anchor.hash == '') ? '' : '#${anchor.hash}';
            gotoPath("${anchor.pathname}$fragment", anchor.title);
            e.preventDefault();
          }
        }
      });
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
}
