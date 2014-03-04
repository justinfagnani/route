// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of route.client;

class RouteMatch extends LinkedListEntry<RouteMatch> {
  final Route route;
  final String name;
  final UriMatch uriMatch;

  RouteMatch(this.route, this.name, this.uriMatch);

  UriPattern get pattern => uriMatch == null ? null : uriMatch.pattern;

  Uri get uri => uriMatch == null ? null : uriMatch.input;

  Uri get rest => uriMatch == null ? null : uriMatch.rest;

  Map<String, String> get parameters =>
      uriMatch == null ? {} : uriMatch.parameters;

  String toString() => '$name ${uriMatch == null ? '' : uriMatch.input}';
}
