// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of route.client;

/**
 * Route is a node in the hierarchical tree of routes.
 *
 * A Route matches against some state of the application, typicaly the URL, and
 * fires events when the application enters or leaves the state matched by the
 * route.
 */
class Route extends ChangeNotifier {

  final StreamController<RouteEvent> _beforeEnterController =
      new StreamController<RouteEvent>.broadcast(sync: true);

  final StreamController<RouteEvent> _beforeExitController =
      new StreamController<RouteEvent>.broadcast(sync: true);

  final StreamController<RouteEvent> _onEnterController =
      new StreamController<RouteEvent>.broadcast(sync: true);

  final StreamController<RouteEvent> _onExitController =
      new StreamController<RouteEvent>.broadcast(sync: true);

  final UriPattern pattern;
  final String _indexRouteName;
  final String _defaultRouteName;
  final Map<String, Route> _children = new LinkedHashMap<String, Route>();

  Route _parent;
  Router _router;

  // current routing state
  Uri _currentUri;
  Route _currentChild;
  Map<String, Object> parameters;

  Route(UriPattern pattern, {String index, String defaultRouteName})
      : this.pattern = pattern,
        _indexRouteName = index,
        _defaultRouteName = defaultRouteName {
    if (pattern == null) throw new ArgumentError();
    // TODO: validate index and default
  }

  Route get _indexRoute => _children[_indexRouteName];

  Map<String, Route> get children => _children;

  void addRoutes(Map<String, Route> children) => children.forEach(addRoute);

  /**
   * Adds a new child route to this Route. [name] must be unique among this
   * Route's children.
   */
  void addRoute(String name, Route route) {
    if (_children.containsKey(name)) {
      throw new ArgumentError('Route with name "$name" already exists');
    }
    if (route.parent != null)  {
      throw new ArgumentError('Route already has a parent');
    }
    _children[name] = route;
    route._parent = this;
    route._router = _router;
  }

  /**
   * A Stream of [RouteEvent]s fired when this Route is being entered.
   */
  Stream<RouteEvent> get beforeEnter => _beforeEnterController.stream;

  /**
   * A Stream of [RouteEvent]s fired when this Route is being exited.
   */
  Stream<RouteEvent> get beforeExit => _beforeExitController.stream;

  /**
   * A Stream of [RouteEvent]s fired when this Route is being entered.
   */
  Stream<RouteEvent> get onEnter => _onEnterController.stream;

  /**
   * A Stream of [RouteEvent]s fired when this Route is being exited.
   */
  Stream<RouteEvent> get onExit => _onExitController.stream;

  /**
   * The parent of this Route.
   */
  Route get parent => _parent;

  remove() {
    parent.children.remove(this.name);
  }

  /**
   * The current child of this Route, which can be this Route.
   */
  Route get currentRoute => (_currentChild == null) ? this
      : _currentChild.currentRoute;

  /**
   * Returns the sub-route identified by [path]. Throws a [ArgumentError] if
   * [path] isn't valid.
   */
  Route operator[](String path) => _getRoute(path, path.split('.'));

  Route _getRoute(String path, Iterable<String> parts) {
    if (parts.isEmpty) throw new ArgumentError('Route $path not found');
    var child = _children[parts.first];
    if (child == null) throw new ArgumentError('Route $path not found');
    if (parts.length == 1) return child;
    return child._getRoute(path, parts.skip(1));
  }

  /**
   * Returns the direct child route that handles [uri].
   */
  RouteMatch _getChild(Uri uri) {
    for (var name in _children.keys) {
      var match = _children[name].pattern.match(uri);
      if (match != null) {
        return new RouteMatch(_children[name], name, match);
      }
    }
    return null;
  }

  List<RouteMatch> _getPath(Uri uri) {
    var match = _getChild(uri);
    if (match == null) {
      return [];
    }
    return match.route._getPath(match.uriMatch.rest)..add(match);
  }

  /**
   * Navigates to this route, making it the current route of the whole route
   * hierarchy.
   *
   * TODO: describe what happens if this route doesn't isn't a valid leaf node,
   * if it has children, but doesn't have an index route.
   */
  Future<bool> navigate({Map<String, String> parameters, String title,
      bool replace}) {
    var newUri = pattern.expand(parameters);
    // TODO: verify that the route found by navigating to newUri is the same
    // as this route, otherwise there's an ambiguity in the URI patterns and
    // we tried to navigate to a route that's unreachable with newUri
    return _router.navigate(newUri, title: title, replace: replace);
//    // walk up to the root, collect nodes for the new route
//    var path = _getPath();
//    // then walk up from the current route calling _beforeExit
//    // then walk down from the root into the new route, calling _beforeEnter
//    // then walk up the current route again calling _onExit
//    // then walk down the new route again calling _onEnter
//    return _router.root.currentRoute._beforeExit(parameters).then((allowed) {
//      _router.root._beforeEnter(path, parameters);
//      // TODO: push the new URI to the router / window URL bar
//      enter(newUri).then((allowed) {
//        print("navigated");
//        // to do: propagate to parent
//        _router._navigate(newUri);
//      });
//    });
  }

  Iterable<Route> _getPathToRoot() {
    var path = <Route>[];
    var r = this;
    while (r.parent != null) {
      path.add(r);
    }
    return path.reversed;
  }

  // walk up the route hierarchy, sending an event to the beforeExit streams
  // along the way. wait for each event to signal that exiting is allowed
  Future<bool> _beforeExit(Map<String, String> parameters) {
    // TODO: need to clarify if this should contain the current URI and
    // parameters, the new URI and parameters, or both
    var event = new RouteEvent(this, this._currentUri, parameters, isExit: true);
    _beforeExitController.add(event);
    return event.checkNavigationAllowed().then((allowed) {
      if (!allowed) return false;
      if (parent != null) return parent._beforeExit(parameters);
      // reached the top, walk down the new route calling _beforeEnter
      return true;
    });
  }

  Future<bool> _beforeEnter(Iterable<Route> path, Map<String, String> parameters) {
    var event = new RouteEvent(this, this._currentUri, parameters, isExit: true);
    if (path.isNotEmpty) {
      var child = _children[path.first];
      if (child == null) throw new ArgumentError(path);
      return child._beforeEnter(path.skip(1), parameters);
    }
  }

  /**
   * Attempts to enter this route for [uri]. [uri] might be the remaining, or
   * rest, part after parsing if this route is a child of of another route.
   */
  Future<bool> enter(Uri uri, {Map<String, String> parameters}) {
    print("Route($pattern).enter($uri): _currentChild: $_currentChild");

    if (uri == null) throw new ArgumentError("uri is null");
    var m = pattern.match(uri);
    if (m == null) throw new ArgumentError("$uri doesn't match $pattern");

    var childUri = m.rest;
    RouteMatch childMatch = _getChild(childUri);

    // check if we're allowed to leave the current route
    // start checking routes bottom up?
    var leaveFuture = (
        _currentChild != null
        && childMatch != null
        && childMatch.route != _currentChild)
            ? _currentChild._exit()
            : new Future.value(true);

    // check if we're allowed to enter the new route
    return leaveFuture.then((allowLeave) {
      if (allowLeave) {
        var localParameters = parameters == null ? {} : new Map.from(parameters);
        localParameters.addAll(m.parameters);
        var enterEvent = new RouteEvent(this, uri, localParameters);
        _onEnterController.add(enterEvent);
        return enterEvent.checkNavigationAllowed().then((allowEnter) {
          if (allowEnter) {
            if (childMatch != null && childMatch.route != null) {
              return childMatch.route.enter(childUri).then((allow) {
                if (allow) _currentChild = childMatch.route;
                return allow;
              });
            }
          }
          return allowEnter;
        });
      } else {
        return false;
      }
    });

  }

  Future<bool> _exit() {
    var event = new RouteEvent(this, this._currentUri, {}, isExit: true);
    _onExitController.add(event);
    return event.checkNavigationAllowed();
  }

//  /**
//   * Returns a route node at the end of the given route path. Route path
//   * dot delimited string of route names.
//   */
//  Route getRoute(String routePath) => _getRoute(routePath.split('.'));

//  Route _getRoute(List<String> path) {
//    var name = path.first;
//    if (!_children.containsKey(name)) {
//      _logger.warning('Route $name not found');
//      return null;
//    }
//    var child = _children[name];
//    return (path.length == 1) ? child : child._getRoute(path.sublist(1));
//  }

//  String get uri => getUri();

//  void set uri(String u) {
//    print("set uri=$u");
//    var newUri = Uri.parse(u);
//    enter(newUri).then((allowed) {
//      notifyPropertyChange(#uri, getUri(), newUri);
//      _router._navigate(newUri);
//    });
//  }

  /**
   * Returns a URI for this route expended with [parameters].
   */
  // TODO: return a Uri?
  String getUri([Map<String, String> parameters]) {
    var _parameters = {};
    if (parameters != null ) _parameters.addAll(parameters);
    if (_currentUri != null) _parameters.addAll(pattern.match(_currentUri).parameters);
    String localUri = pattern.expand(_parameters).toString();
    if (_parent != null) {
      var parentUri = _parent.getUri(_parameters);
//      return mergeUris(parentUri, localUri);
      return parentUri + localUri;
    }
    return localUri;
  }

//  /**
//   * Returns a URL for this route. The tail (url generated by the child path)
//   * will be passes to the UrlMatcher to be properly appended in the
//   * right place.
//   */
//  String expand({Map<String, String> parameters}) {
//    // TODO(justin): merge with parent expand
//    return template.expand(parameters);
//  }

  String toString() => "Route{ template: $pattern,"
      " defaultRouteName: $_defaultRouteName,"
      " children: $_children}";
}

class RouteMatch {
  final Route route;
  final String name;
  final UriMatch uriMatch;
  RouteMatch(this.route, this.name, this.uriMatch);
}