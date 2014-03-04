// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of route.client;

typedef RouteHandler(RouteEvent);

/**
 * Returns a new Route
 */
Route route(UriPattern pattern, {
    RouteHandler beforeEnter,
    RouteHandler beforeExit,
    RouteHandler onEnter,
    RouteHandler onExit,
    Map<String, Route> children,
    String defaultRoute,
    String indexRoute,
    bool matchFull
  }) {

  _logger.fine("route($pattern, defaultRoute: $defaultRoute)");

  if (pattern == null) throw new ArgumentError("pattern is null");

  var r = new Route(pattern, indexRoute: indexRoute, defaultRoute: defaultRoute,
      matchFull: matchFull);

  if (beforeExit != null) r.beforeExit.listen(beforeExit);
  if (beforeEnter != null) r.beforeEnter.listen(beforeEnter);
  if (onExit != null) r.onExit.listen(onExit);
  if (onEnter != null) r.onEnter.listen(onEnter);

  if (children != null) r.addRoutes(children);
  return r;
}

UriPattern uri(String s) =>
    new UriParser(new UriTemplate(s));
