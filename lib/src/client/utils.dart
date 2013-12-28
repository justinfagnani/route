// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' show Location;

Uri uriFromLocation(Location location) {
  var scheme = location.protocol;
  if (scheme.contains(':')) scheme = scheme.split(':')[0];
  var uri = new Uri(
      scheme: scheme,
      host: location.hostname,
      port: int.parse(location.port, onError: (_) => null),
      path: location.pathname,
      query: location.search,
      fragment: location.hash);
  return uri;
}
