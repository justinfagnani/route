// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of route.client;

Route route(template, {String defaultRoute, String index,
    Map<String, Route> children}) {
  print("route: $template");
  if (template == null) throw new ArgumentError("null template B");
  UriTemplate t = (template is String) ? new UriTemplate(template) : template;
  return new Route._(t, index: index, defaultRouteName: defaultRoute);
}

/**
 * Route is a node in the hierarchical tree of routes.
 *
 * A Route matches against some state of the application, typicaly the URL, and
 * fires events when the application enters or leaves the state matched by the
 * route.
 */
class Route extends ChangeNotifierBase {

  final UriTemplate template;
  final UriParser _parser;
  final StreamController<RouteEvent> _onEnterController;
  final StreamController<RouteEvent> _onExitController;

  final Map<String, Route> _children = new LinkedHashMap<String, Route>();
  final String _indexRouteName;

  Route _parent;
  Router _router;

  Route get _currentChild => _children[_currentChildName];

  String _currentChildName;
  String get currentChildName => _currentChildName;
  void _setCurrentChildName(c) {
    // set route
    print('_setCurrentChildName: $c');
    _currentChildName = notifyPropertyChange(const Symbol('currentChildName'),
        _currentChildName, c);
  }

  Route._(UriTemplate template, {String index, String defaultRouteName})
      : this.template = template,
        _parser = new UriParser(template),
        _indexRouteName = index,
        _onEnterController =
            new StreamController<RouteEvent>.broadcast(sync: true),
        _onExitController =
            new StreamController<RouteEvent>.broadcast(sync: true);

  void addRoutes(Map<String, Route> children) => children.forEach(addRoute);

  void addRoute(String name, Route route) {
    if (_children.containsKey(name)) {
      throw new ArgumentError('Route with name "$name" already exists');
    }
    _children[name] = route;
    route._parent = this;
    route._router = _router;
  }

  Stream<RouteEvent> get onEnter => _onEnterController.stream;
  Stream<RouteEvent> get onExit => _onExitController.stream;
  Route get parent => _parent;

  Route get _indexRoute => _children[_indexRouteName];

  UriMatch _match(Uri uri) => _parser.parsePrefix(uri);

  void _setCUrrentRoute() {

  }

  navigate(String routeName, {Map<String, String> parameters}) {
    var newRoute = _children[routeName];
    if (newRoute == null) {
      throw new ArgumentError('no route found: $routeName in $_children');
    }
    var newUri = Uri.parse(newRoute.template.expand(parameters));
    // TODO: push the new URI to the router / window URL bar
    _enter(newUri).then((allowed) {
      print("navigated");
      _router._navigate(newUri, null, true);
    });
  }

  Future<bool> _enter(Uri uri, {bool asIndex: false}) {
    print("Route($template).enter($uri): _currentChild: $_currentChild");

//    var leaveFuture;
//    var event;
    var newChildName;
    var childUri;
    var parameters;
    bool useIndex = asIndex;

    if (!asIndex) {
      var match = _match(uri);
      if (!match.matches) {
        throw new ArgumentError("Internal Error: URI $uri doesn't match "
            "$template: $uri");
      }
      childUri = match.rest;
      print("children: $_children");
      print("childUri $childUri");

      for (var childName in _children.keys) {
        if (_children[childName]._match(childUri).matches) {
          newChildName = childName;
          break;
        }
      }
      // TODO: check URI is empty
      useIndex = true;
    }
    if (useIndex) {
      // TODO: should the index route be required to have no parameters?
      newChildName = _indexRouteName;
      childUri = uri;
      parameters = {};
    }
    print("newChild: $newChildName");
    var event = new RouteEvent._(this, childUri, parameters);
    var leaveFuture =
        (_currentChildName != null && newChildName != _currentChildName)
            ? _currentChild._exit(childUri)
            : new Future.value(true);

    return leaveFuture.then((allowLeave) {
      if (allowLeave) {
        _onEnterController.add(event);
        // TODO: wait for event navigate futures to complete
        _setCurrentChildName(newChildName);
        return _currentChild == null
            ? true : _currentChild._enter(childUri, asIndex: useIndex);
      } else {
        return false;
      }
    });
  }

  Future<bool> _exit(Uri uri) {
    var event = new RouteEvent._(this, null, null);
    _onExitController.add(event);
    if (event._allowNavigationFutures.isEmpty) {
      return new Future.value(true);
    } else {
      return Future.wait(event._allowNavigationFutures)
          .then((results) => results.every((allow) => allow == true));
    }
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

  String get uri => getUri();

  void set uri(String u) {
    print("set uri=$u");
    var newUri = Uri.parse(u);
    _enter(newUri).then((allowed) {
      notifyPropertyChange(const Symbol('uri'), getUri(), newUri);
      _router._navigate(newUri, null, true);
    });
  }

  String getUri({Map<String, String> parameters}) {
    String localUri = template.expand(parameters);
    if (_parent != null) {
      var parentUri = _parent.getUri(parameters: parameters);
//      return mergeUris(parentUri, localUri);
      return parentUri + localUri;
    }
    return localUri;
  }

  /**
   * Returns a URL for this route. The tail (url generated by the child path)
   * will be passes to the UrlMatcher to be properly appended in the
   * right place.
   */
  String expand({Map<String, String> parameters}) {
    // TODO(justin): merge with parent expand
    return template.expand(parameters);
  }

  String toString() => "Route: $template";
}
