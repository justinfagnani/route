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
  final bool matchFull;
  final String _indexRouteName;
  final String _defaultRouteName;
  final Map<String, Route> _children = new LinkedHashMap<String, Route>();

  Route _parent;
  Router _router;

  // current routing state
  Uri _currentUri;
  Route _currentChild;
  Map<String, Object> _currentParameters;

  // for testing only
  void set currentChild(c) { _currentChild = c; }
  Route get currentChild => _currentChild;
  void set currentUri(u) { _currentUri = u; }
  Uri get currentUri => _currentUri;

  Route(UriPattern pattern, {
      bool matchFull,
      String index,
      String defaultRouteName})
      : pattern = pattern,
        matchFull = firstNonNull(matchFull, false),
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
    throw new UnimplementedError('remove');
//    parent.children.remove(this.name);
  }

  /**
   * The current child of this Route, which can be this Route.
   */
  Route get currentRoute => (_currentChild == null) ? this
      : _currentChild.currentRoute;

  /**
   * Returns the sub-route identified by the dot separated [path]. Throws an
   * [ArgumentError] if [path] doesn't represent a valid route.
   */
  Route operator[](String path) {
    var separatorIndex = path.indexOf('.');
    var name = separatorIndex == -1 ? path : path.substring(0, separatorIndex);
    var child = _children[name];
    if (child == null) throw new ArgumentError('Route $path not found');
    if (separatorIndex == -1) return child;
    return child[path.substring(separatorIndex + 1)];
  }

  LinkedList<RouteMatch> match(Uri uri) {
    for (var name in _children.keys) {
      var child = _children[name];
      var uriMatch = child._matchUri(uri);
      if (uriMatch != null) {
        var routeMatch = new RouteMatch(child, name, uriMatch);
        return child.match(uriMatch.rest)..addFirst(routeMatch);
      }
    }
    return new LinkedList<RouteMatch>();
  }

  UriMatch _matchUri(Uri uri) {
    var match = pattern.match(uri);
    if (match != null && matchFull) {
      var rest = match.rest;
      if (rest.path.isNotEmpty || rest.queryParameters.isNotEmpty ||
          rest.fragment.isNotEmpty) {
        return null;
      }
    }
    return match;
  }

  /**
   * Navigates to this route, making it the current route of the whole route
   * hierarchy.
   *
   * TODO: describe what happens if this route isn't a valid leaf node:
   * if it has children, but doesn't have an index route.
   */
  Future<bool> navigate({Map<String, String> parameters}) {
    // We expand and reparse the URI so that we always go to the same route for
    // the same URI
    // TODO: verify that the route found by navigating to newUri is the same
    // as this route, otherwise there's an ambiguity in the URI patterns and
    // we tried to navigate to a route that's unreachable with newUri
    var newUri = pattern.expand(parameters);
    return _router.navigate(newUri);
  }

  /**
   * Helper for _beforeExit and _onExit
   */
  Future<bool> _doExit(StreamController<RouteEvent> controller, cont) {
    // TODO: need to clarify if this should contain the current URI and
    // parameters, the new URI and parameters, or both
    var event = new RouteEvent(this, this._currentUri, _currentParameters,
        isExit: true);
    controller.add(event);
    return event.checkNavigationAllowed().then((allowed) {
      if (!allowed) return false;
      if (_currentChild != null) return cont(_currentChild);
      return true;
    });
  }

  // send a route exit event to this routes, and all decendents along the
  // current route path, beforeExit streams
  Future<bool> _beforeExit() =>
      _doExit(_beforeExitController, (c) => c._beforeExit());

  // send a route exit event to this routes, and all decendents along the
  // current route path, beforeExit streams
  Future<bool> _onExit() =>
      _doExit(_onExitController, (c) => c._onExit());

  /**
   * Helper for _beforeEnter and _onEnter
   */
  Future<bool> _doEnter(StreamController<RouteEvent> controller, cont,
      Iterable<RouteMatch> path, Map<String, String> parentParameters) {
    var match = path.first;
    assert(match.route == this);
    // accumulate parameters. This means that parameter name collision will
    // result in aliasing, and a route can't see the parameters for it's
    // decendents, much like block scope.
    var parameters = new Map.from(parentParameters)..addAll(match.parameters);
    var event = new RouteEvent(this, match.uri, parameters, isExit: false);
    controller.add(event);
    return event.checkNavigationAllowed().then((allowed) {
      if (!allowed) return false;

      var rest = path.skip(1);
      if (rest.isNotEmpty) {
        var child = _children[rest.first.name];
        if (child == null) throw new ArgumentError(path);
        return cont(child, rest, parameters);
      }
      return true;
    });
  }

  Future<bool> _beforeEnter(Iterable<RouteMatch> path,
      Map<String, String> parentParameters) =>
          _doEnter(_beforeEnterController, (c, r, p) => c._beforeEnter(r, p),
              path, parentParameters);

  Future<bool> _onEnter(Iterable<RouteMatch> path,
      Map<String, String> parentParameters) =>
          _doEnter(_onEnterController, (c, r, p) => c._onEnter(r, p),
              path, parentParameters);

  /**
   * Returns a URI for this route expended with [parameters].
   */
  // TODO: return a Uri?
  String getUri([Map<String, String> parameters]) {
    var _parameters = {};
    if (parameters != null ) _parameters.addAll(parameters);
    if (_currentUri != null) {
      _parameters.addAll(pattern.match(_currentUri).parameters);
    }
    String localUri = pattern.expand(_parameters).toString();
    if (_parent != null) {
      var parentUri = _parent.getUri(_parameters);
      return parentUri + localUri;
    }
    return localUri;
  }

  String toString() => "Route{ template: $pattern,"
      " defaultRouteName: $_defaultRouteName,"
      " children: $_children}";
}

