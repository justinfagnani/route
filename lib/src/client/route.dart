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
class Route {

  final UriTemplate template;
  final UriParser _parser;
  final StreamController<RouteEvent> _onEnterController;
  final StreamController<RouteEvent> _onExitController;

  final Map<String, Route> _children = new LinkedHashMap<String, Route>();
  final String _indexRouteName;

  Route _parent;
  Router _router;

  Route _currentChild;

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

  navigate(String routeName, {Map<String, String> parameters}) {
    var newRoute = _children[routeName];
    if (newRoute == null) {
      throw new ArgumentError('no route found: $routeName in $_children');
    }
    var newUri = Uri.parse(newRoute.template.expand(parameters));
    // TODO: push the new URI to the router / window URL bar
    enter(newUri).then((allowed) {
      print("navigated");
      _router._navigate(newUri, null, true);
    });
  }

  Future<bool> enter(Uri uri) {
    print("Route($template).enter($uri): _currentChild: $_currentChild");
    var match = _match(uri);
    if (!match.matches) {
      throw new ArgumentError("Internal Error: URI $uri doesn't match "
          "$template");
    }
    var childUri = match.rest;
    var event = new RouteEvent._(this, match.rest, match.parameters);
    print(_children);
    if (_children.containsKey('catchAll')) {
      print("catchAll($childUri): ${_children['catchAll']._match(childUri)}");
    }
    var matchingChildren = _children.values
        .where((r) => r._match(childUri).matches);
    var leaveFuture;
    var newChild = (matchingChildren.isNotEmpty)
        ? matchingChildren.first
        : _indexRoute;

    leaveFuture = (_currentChild != null && newChild != _currentChild)
        ? _currentChild.exit(childUri)
        : new Future.value(true);

    return leaveFuture.then((allowLeave) {
      if (allowLeave) {
        _onEnterController.add(event);
        // TODO: wait for event navigate futures to complete
        _currentChild = newChild;
        return newChild == null ? true : newChild.enter(childUri);
      } else {
        return false;
      }
    });

  }

  Future<bool> exit(Uri uri) {
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
