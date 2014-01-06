// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of route.client;

/**
 * Returns a new Route
 */
Route route(dynamic template, {String defaultRoute, String index,
    Map<String, Route> children}) {

  print("route($template, defaultRoute: $defaultRoute)");

  if (template == null) throw new ArgumentError("template is null");

  UriPattern t = (template is String)
      ? new UriParser(new UriTemplate(template))
      : template;
  var r = new Route._(t, index: index, defaultRouteName: defaultRoute);
  if (children != null) r.addRoutes(children);
//  print(r);
  return r;
}

/**
 * Route is a node in the hierarchical tree of routes.
 *
 * A Route matches against some state of the application, typicaly the URL, and
 * fires events when the application enters or leaves the state matched by the
 * route.
 */
class Route extends ChangeNotifier {

  final UriPattern template;
//  final UriParser _parser;
  final StreamController<RouteEvent> _onEnterController;
  final StreamController<RouteEvent> _onExitController;

  Map<String, Route> get children => _children;
  final Map<String, Route> _children = new LinkedHashMap<String, Route>();
  final String _indexRouteName;
  final String _defaultRouteName;

  Route _parent;
  Router _router;

  // state
  Uri _currentUri;
  Route _currentChild;
  // parameters

  Route(UriPattern template, {String index, String defaultRouteName})
      : this._(template, index: index, defaultRouteName: defaultRouteName);

  Route._(UriPattern template, {String index, String defaultRouteName})
      : this.template = template,
//        _parser = new UriParser(template),
        _indexRouteName = index,
        _onEnterController =
            new StreamController<RouteEvent>.broadcast(sync: true),
        _onExitController =
            new StreamController<RouteEvent>.broadcast(sync: true),
        _defaultRouteName = defaultRouteName;

  void addRoutes(Map<String, Route> children) => children.forEach(addRoute);

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

  Stream<RouteEvent> get onEnter => _onEnterController.stream;
  Stream<RouteEvent> get onExit => _onExitController.stream;
  Route get parent => _parent;

  Route get _indexRoute => _children[_indexRouteName];

  UriMatch match(Uri uri) => template.match(uri); //_parser.parsePrefix(uri);

  RouteMatch getChild(Uri uri) {
    for (var name in _children.keys) {
      var match = _children[name].match(uri);
      if (match != null) {
        return new RouteMatch(_children[name], name, match);
      }
    }
  }

  Route get currentRoute => (_currentChild == null) ? this
      : _currentChild.currentRoute;

  navigate(String routeName, {Map<String, String> parameters}) {
    var newRoute = _children[routeName];
    if (newRoute == null) {
      throw new ArgumentError('no route found: $routeName in $_children');
    }
    var newUri = Uri.parse(newRoute.template.expand(parameters));
    // TODO: push the new URI to the router / window URL bar
    enter(newUri).then((allowed) {
      print("navigated");
      // to do: propagate to parent
      _router._navigate(newUri);
    });
  }

  /**
   * Attempts to enter this route for [uri]. [uri] might be the remaining, or
   * rest, part after parsing if this route is a child of of another route.
   */
  Future<bool> enter(Uri uri, {Map<String, String> parameters}) {
    print("Route($template).enter($uri): _currentChild: $_currentChild");

    if (uri == null) throw new ArgumentError("uri is null");
    var m = match(uri);
    if (m == null) throw new ArgumentError("$uri doesn't match $template");

    var childUri = m.rest;
    RouteMatch childMatch = getChild(childUri);

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
        var localParameters = new Map.from(parameters)..addAll(m.parameters);
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

  String get uri => getUri();

  void set uri(String u) {
    print("set uri=$u");
    var newUri = Uri.parse(u);
    enter(newUri).then((allowed) {
      notifyPropertyChange(#uri, getUri(), newUri);
//      _router._navigate(newUri);
    });
  }

  /**
   * Returns a URI for this route expended with [parameters].
   */
  // TODO: return a Uri?
  String getUri([Map<String, String> parameters]) {
    var _parameters = {};
    if (parameters != null ) _parameters.addAll(parameters);
    if (_currentUri != null) _parameters.addAll(template.match(_currentUri).parameters);
    String localUri = template.expand(_parameters).toString();
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

  String toString() => "Route{ template: $template,"
      " defaultRouteName: $_defaultRouteName,"
      " children: $_children}";
}

class RouteMatch {
  final Route route;
  final String name;
  final UriMatch uriMatch;
  RouteMatch(this.route, this.name, this.uriMatch);
}