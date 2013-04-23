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

final _logger = new Logger('route');

typedef Handler(String path);

typedef RouteHandler(RouteEvent path);

typedef void EventHandler(Event e);

class _Route {
  final Pattern path;
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
  Function _responseCall;

  RouteEvent(this.path, Function this._responseCall);

  void allowLeave(Future<bool> veto) {
    _responseCall(veto);
  }

  RouteEvent _clone(Function newRespCall) => new RouteEvent(path, newRespCall);
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
  final Map<UrlPattern, Handler> _handlers = new Map<UrlPattern, Handler>();
  final List<_Route> _routes = <_Route>[];
  final bool useFragment;
  _Route _currentRoute;

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router({bool useFragment})
      : useFragment = (useFragment == null)
            ? !History.supportsState
            : useFragment;

  void addRoute({Pattern path, RouteHandler enter, RouteHandler leave, mount}) {
    Router child;
    if (mount != null) {
      child = new Router();
      if (mount is Function) {
        mount(child);
      } else if (mount is Routable) {
        mount.configureRouter(child);
      }
    }
    _routes.add(new _Route(path: path, enter: enter, leave: leave,
        child: child));
  }

  void addHandler(UrlPattern pattern, Handler handler) {
    _handlers[pattern] = handler;
  }

  UrlPattern _getUrl(path) {
    var matches = _handlers.keys.where((url) => url.matches(path));
    if (matches.isEmpty) {
      throw new ArgumentError("No handler found for path: $path");
    }
    return matches.first;
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
  Future handle(String path) {
    Completer completer = new Completer();
    List matchingRoutes = _routes.where((r) => matchesPrefix(r.path, path)).toList();
    if (!matchingRoutes.isEmpty) {
      if (matchingRoutes.length > 1) {
        _logger.warning("More than one route matches $path");
      }
      _Route route = matchingRoutes.first;
      var match = prefixMatch(route.path, path);
      var tailPath = path.substring(match.end);
      if (!identical(route, _currentRoute)) {
        var headPath = path.substring(0, match.end);
        var event = new RouteEvent(headPath,
            (_) => throw new StateError('Cannot veto on enter!'));
        // before we make this a new current route, leave the old
        _leaveCurrentRoute(event).then((bool allowNavigation) {
          if (allowNavigation) {
            _currentRoute = route;
            if (route.enter != null) {
              route.enter(event);
            }
            if (route.child != null) {
              route.child.handle(tailPath).then((_) {
                completer.complete();
              });
            } else {
              completer.complete();
            }
          } else {
            completer.complete();
          }
        });
      } else {
        if (route.child != null) {
          route.child.handle(tailPath).then((_) {
            completer.complete();
          });
        } else {
          completer.complete();
        }
      }
    } else {
      var url = _getUrl(path);
      if (url != null) {
        // always give handlers a non-fragment path
        var fixedPath = url.reverse(url.parse(path));
        _handlers[url](fixedPath);
      } else {
        _logger.info("Unhandled path: $path");
      }
      completer.complete();
    }
    return completer.future;
  }

  Future<bool> _leaveCurrentRoute(RouteEvent e) {
    Completer<bool> completer = new Completer<bool>();
    if (_currentRoute != null) {
      List<Future<bool>> pendingResponses = <Future<bool>>[];
      var event = e._clone((Future<bool> r) => pendingResponses.add(r));

      if (_currentRoute.leave != null) {
        _currentRoute.leave(event);
      }
      if (_currentRoute.child != null) {
        _currentRoute.child._leaveCurrentRoute(event).then((allowNavigation) {
          if (!allowNavigation) {
            completer.complete(false);
          } else if (pendingResponses.length == 0) {
            completer.complete(true);
          } else {
            Future.wait(pendingResponses).then((List<bool> responses) {
              completer.complete(responses.reduce((a, b) => a && b));
            });
          }
        });
      } else {
        if (pendingResponses.length == 0) {
          completer.complete(true);
        } else {
          Future.wait(pendingResponses).then((List<bool> responses) {
            completer.complete(responses.reduce((a, b) => a && b));
          });
        }
      }
    } else {
      completer.complete(true);
    }
    return completer.future;
  }

  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen({bool ignoreClick: false}) {
    if (useFragment) {
      window.onHashChange.listen((_) {
        return handle('${window.location.pathname}#${window.location.hash}');
      });
    } else {
      window.onPopState.listen((_) => handle(window.location.pathname));
    }
    if (!ignoreClick) {
      window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == window.location.host) {
            var fragment = (anchor.hash == '') ? '' : '${anchor.hash}';
            gotoPath("${anchor.pathname}$fragment", anchor.title);
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
  void gotoUrl(UrlPattern url, List args, String title) {
    if (_handlers.containsKey(url)) {
      _go(url.reverse(args, useFragment: useFragment), title);
      _handlers[url](url.reverse(args, useFragment: useFragment));
    } else {
      throw new ArgumentError('Unknown URL pattern: $url');
    }
  }

  void gotoPath(String path, String title) {
    var url = _getUrl(path);
    if (url != null) {
      _go(path, title);
      _handlers[url](path);
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

  /**
   * Returns an [Event] handler suitable for use as a click handler on [:<a>;]
   * elements. The handler reverses [ur] with [args] and uses [window.pushState]
   * with [title] to change the user visible URL without navigating to it.
   * [Event.preventDefault] is called to stop the default behavior. Then the
   * handler associated with [url] is invoked with [args].
   */
  EventHandler clickHandler(UrlPattern url, List args, String title) =>
      (Event e) {
        e.preventDefault();
        gotoUrl(url, args, title);
      };
}
