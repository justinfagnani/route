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
  RouteEvent lastEvent;

  String toString() {
    return 'Route:' + path.toString();
  }

  _Route({this.path, this.enter, this.leave, this.child});

  String reverse(String tail) {
    return path.reverse(parameters: lastEvent.parameters, tail: tail);
  }
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
  final bool _useFragment;
  final Window _window;
  final StreamController<RouteEvent> _onRouteController;
  final StreamController<RouteEvent> _onLeaveController;
  final Router _parent;
  _Route _defaultRoute;
  _Route _currentRoute;

  Stream<RouteEvent> get onRoute => _onRouteController.stream;
  Stream<RouteEvent> get onLeave => _onLeaveController.stream;

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router({bool useFragment, Window windowImpl})
      : this._init(null, useFragment: useFragment, windowImpl: windowImpl);

  Router._init(Router parent, {bool useFragment, Window windowImpl})
      : _useFragment = (useFragment == null)
            ? !History.supportsState
            : useFragment,
        _window = (windowImpl == null) ? window : windowImpl,
        _onRouteController = new StreamController<RouteEvent>(),
        _onLeaveController = new StreamController<RouteEvent>(),
        _parent = parent;

  Router._childOf(Router parent, {bool useFragment, Window windowImpl})
      : this._init(parent, useFragment: useFragment, windowImpl: windowImpl);

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
      child = new Router._childOf(this, windowImpl: _window, useFragment: _useFragment);
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
  Future<bool> route(String path) {
    _logger.finest('route $path');
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
      if (route != _currentRoute || 
          _currentRoute.lastEvent.path != match.match) {
        return _processNewRoute(path, match, route);
      } else {
        _currentRoute.lastEvent = new RouteEvent(match.match, match.parameters);
        if (route.child != null)  {
          return route.child.route(match.tail);
        }
      }
      return new Future.value(true);
    }
    return new Future.value(false);
  }
  
  Future go(String routePath, Map parameters, {bool replace: false}) {
    var newTail = _getTailUrl(routePath, parameters);
    String newUrl = _getHead(newTail);
    _logger.finest('go $newUrl');
    return route(newTail).then((success) {
      if (success) {
        _go(newUrl, null, replace);
      }
      return success;
    });
  }

  String url(String routePath, [Map parameters]) {
    parameters = parameters == null ? {} : parameters;
    return (_useFragment? '#' : '') +_getHead(_getTailUrl(routePath, parameters));
  }

  String _getHead(String tail) {
    if (_parent == null) {
      return tail;
    }
    if (_parent._currentRoute == null) {
      throw new StateError('Router $_parent has no current router.');
    }
    return _parent._getHead(_parent._currentRoute.reverse(tail));
  }

  String _getTailUrl(routePath, Map parameters) {
    var routeName = routePath.split('.').first;
    if (!_routes.containsKey(routeName)) {
      throw new StateError('Invalid route name: $routeName');
    }
    var routeToGo = _routes[routeName];
    var tail = '';
    var childPath = routePath.substring(routeName.length);
    if (routeToGo.child != null && childPath.length > 0) {
      tail = routeToGo.child.
          _getTailUrl(childPath.substring(1), parameters);
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

  Future<bool> _processNewRoute(String path, UrlMatch match, _Route route) {
    var event = new RouteEvent(match.match, match.parameters);
    // before we make this a new current route, leave the old
    return _leaveCurrentRoute(event).then((bool allowNavigation) {
      if (allowNavigation) {
        _unsetAllCurrentRoutes();
        _currentRoute = route;
        _currentRoute.lastEvent = new RouteEvent(match.match, match.parameters);
        if (route.enter != null) {
          route.enter(event);
        }
        if (route.child != null) {
          route.child._onRouteController.add(event);
          return route.child.route(match.tail);
        }
      }
      return true;
    });
  }

  void _unsetAllCurrentRoutes() {
    if (_currentRoute != null) {
      if (_currentRoute.child != null) {
        _currentRoute.child._unsetAllCurrentRoutes();
      }
      _currentRoute = null;
    }
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
        _currentRoute.child._onLeaveController.add(event);
        futures.addAll(_currentRoute.child._leaveCurrentRouteHelper(event));
      }
    }
    return futures;
  }

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen({bool ignoreClick: false}) {
    if (_useFragment) {
      _window.onHashChange.listen((_) {
        return route(_normalizeHash(_window.location.hash));
      });
      route(_normalizeHash(_window.location.hash));
    } else {
      _window.onPopState.listen((_) => route(_window.location.pathname));
    }
    if (!ignoreClick) {
      _window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == _window.location.host) {
            e.preventDefault();
            var fragment = (anchor.hash == '') ? '' : '${anchor.hash}';
            route('${anchor.pathname}$fragment').then((allowed) {
              if (allowed) {
                _go("${anchor.pathname}$fragment", null, false);
              }
            });
          }
        }
      });
    }
  }

  String _normalizeHash(String hash) {
    if (hash.isEmpty) {
      return '';
    }
    return hash.substring(1);
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
    if (_useFragment) {
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
