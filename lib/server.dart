// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.server;

import 'dart:io';
import 'url_pattern.dart';
export 'url_pattern.dart';

typedef bool HttpMatcher(HttpRequest request);

/**
 * Returns a matcher for use with [HttpServer.addRequestHandler] that returns
 * [:true:] if [pattern] matches against the request path.
 *
 * Usage:
 *     server.addRequestHandler(matchesUrl(pattern), handler);
 */
HttpMatcher matchesUrl(UrlPattern pattern) => (HttpRequest req) =>
   pattern.matches(req.path);
