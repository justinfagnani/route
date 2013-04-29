// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client;

import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'url_pattern.dart';
export 'url_pattern.dart';
import 'pattern.dart';
import 'url_matcher.dart';
import 'url_template.dart';


final _logger = new Logger('route');

typedef RouteHandler(RouteEvent path);

class _Route {
  final UrlMatcher path;
  final RouteHandler enter;
  final RouteHandler leave;
  final Router child;

  String toString() {
    return 'Route:' + path.toString();
  }

  _Route({this.path, this.enter, this.leave, this.child});

  bool matches(String matchPath) => matchesPrefix(path, matchPath);
}

class RouteEvent {
  final String path;
  final Map parameters;
  Future<bool> _allowLeaveFuture;

  RouteEvent(this.path, this.parameters);

  void allowLeave(Future<bool> allow) {
    _allowLeaveFuture = allow;
  }

  RouteEvent _clone() => new RouteEvent(path, parameters);
}

abstract class Routable {
  void configureRouter(Router router);
}

/**
 * Stores a set of [UrlPattern] to [Handler] associations and provides methods
 * for calling a handler for a URL path, listening to [Window] history events,
 * and creating HTML event handlers that navigate to a URL.
 */
class Router {
  final Map<String, _Route> _routes = new Map<String, _Route>();
  final bool useFragment;
  final Window _window;
  _Route _defaultRoute;
  _Route _currentRoute;
  String _lastTail = '';

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router({bool useFragment, Window windowImpl})
      : useFragment = (useFragment == null)
            ? !History.supportsState
            : useFragment,
        _window = (windowImpl == null) ? window : windowImpl;

  void addRoute({String name, Pattern path, bool defaultRoute: false,
      RouteHandler enter, RouteHandler leave, mount}) {
    if (name == null) {
      throw new ArgumentError('name is required for all routes');
    }
    if (_routes.containsKey(name)) {
      throw new ArgumentError('Route $name already exists');
    }
    Router child;
    if (mount != null) {
      child = new Router();
      if (mount is Function) {
        mount(child);
      } else if (mount is Routable) {
        mount.configureRouter(child);
      }
    }
    var matcher;
    if (!(path is UrlMatcher)) {
      matcher = new UrlTemplate(path.toString());
    } else {
      matcher = path;
    }
    var route = new _Route(path: matcher, enter: enter, leave: leave,
        child: child);
    if (defaultRoute) {
      if (_defaultRoute != null) {
        throw new StateError('Only one default route can be added.');
      }
      _defaultRoute = route;
    }
    _routes[name] = route;
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
  Future<bool> route(String path, {String prefix: ''}) {
    _lastTail = prefix;
    _Route route;
    List matchingRoutes = _routes.values.where(
        (r) => r.path.match(path) != null).toList();
    if (!matchingRoutes.isEmpty) {
      if (matchingRoutes.length > 1) {
        _logger.warning("More than one route matches $path");
      }
      route = matchingRoutes.first;
    } else {
      if (_defaultRoute != null) {
        route = _defaultRoute;
      }
    }
    if (route != null) {
      var match = _getMatch(route, path);
      if (!identical(route, _currentRoute)) {
        return _processNewRoute(path, match, route, prefix + match.match);
      } else if (route.child != null)  {
        return route.child.route(match.tail, prefix: prefix + match.match);
      }
    }
    return new Future.value(true);
  }

  Future go(String routePath, Map parameters, {bool replace: false}) {
    String newUrl = _lastTail + _getTailUrl(routePath, parameters);
    return route(newUrl, prefix: _lastTail).then((success) {
      if (success) {
        _go(newUrl, null, replace);
      }
    });
  }

  String _getTailUrl(routePath, Map parameters) {
    var routeName = routePath.split('.').first;
    if (!_routes.containsKey(routeName)) {
      throw new StateError('Invalid route name: $routeName');
    }
    var routeToGo = _routes[routeName];
    var tail = '';
    if (routeToGo.child != null) {
      tail = routeToGo.child.
          _getTailUrl(routePath.substring(routeName.length), parameters);
    }
    return routeToGo.path.reverse(parameters: parameters, tail: tail);
  }

  UrlMatch _getMatch(_Route route, String path) {
    var match = route.path.match(path);
    if (match == null) { // default route
      return new UrlMatch('', '', {});
    }
    return match;
  }

  Future<bool> _processNewRoute(String path, UrlMatch match, _Route route,
                                String prefix) {
    var event = new RouteEvent(match.match, match.parameters);
    // before we make this a new current route, leave the old
    return _leaveCurrentRoute(event).then((bool allowNavigation) {
      if (allowNavigation) {
        _currentRoute = route;
        if (route.enter != null) {
          route.enter(event);
        }
        if (route.child != null) {
          return route.child.route(match.tail, prefix: prefix);
        }
      }
      return true;
    });
  }

  Future<bool> _leaveCurrentRoute(RouteEvent e) =>
      Future.wait(_leaveCurrentRouteHelper(e))
          .then((values) => values.fold(true, (c, v) => c && v));

  List<Future<bool>> _leaveCurrentRouteHelper(RouteEvent e) {
    var futures = [];
    if (_currentRoute != null) {
      List<Future<bool>> pendingResponses = <Future<bool>>[];
      // We create a copy of the route event
      var event = e._clone();
      if (_currentRoute.leave != null) {
        _currentRoute.leave(event);
      }
      if (event._allowLeaveFuture != null) {
        futures.add(event._allowLeaveFuture);
      }
      if (_currentRoute.child != null) {
        futures.addAll(_currentRoute.child._leaveCurrentRoute(event));
      }
    }
    return futures;
  }

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen({bool ignoreClick: false}) {
    if (useFragment) {
      _window.onHashChange.listen((_) {
        return route('#${_window.location.hash}');
      });
    } else {
      _window.onPopState.listen((_) => route(_window.location.pathname));
    }
    if (!ignoreClick) {
      _window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == _window.location.host) {
            var fragment = (anchor.hash == '') ? '' : '${anchor.hash}';
            gotoUrl("${anchor.pathname}$fragment", anchor.title);
            e.preventDefault();
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
  Future<bool> gotoUrl(String url) {
    return route(url).then((success) {
      if (success) {
        _go(url, null);
      }
    });
  }

  void _go(String path, String title, bool replace) {
    title = (title == null) ? '' : title;
    if (useFragment) {
      if (replace) {
        _window.location.replace('#$path');
      } else {
        _window.location.assign('#$path');
      }
      (_window.document as HtmlDocument).title = title;
    } else {
      if (replace) {
        _window.history.replaceState(null, title, path);
      } else {
        _window.history.pushState(null, title, path);
      }
    }
  }
}
