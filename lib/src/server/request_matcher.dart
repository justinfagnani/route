// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.server.request_matcher;

import 'dart:io';

import 'package:quiver/strings.dart' show equalsIgnoreCase;
import 'package:quiver/pattern.dart' show matchesFull;
import 'package:uri/uri.dart' show UriPattern;

typedef bool RequestMatcher(HttpRequest request);

RequestMatcher matchAny(Iterable<dynamic> matchers) {
  var _matchers = matchers.map(wrapMatcher);
  return (HttpRequest request) => _matchers.any((m) => m(request));
}

RequestMatcher wrapMatcher(dynamic matcher, {String method}) {
  if (matcher is UriPattern) {
    return new _UriPatternRequestMatcher(matcher, method);
  }
  if (matcher is Pattern) {
    return new _PatternRequestMatcher(matcher, method);
  }
  if (matcher is RequestMatcher) {
    if (method != null) throw new ArgumentError('cannot specify a method when '
        'using a RequestMatcher');
    return matcher;
  }
  throw new ArgumentError('matcher must be a UriPattern, Pattern, '
      'or RequestMatcher');
}

class _UriPatternRequestMatcher implements Function {
  final UriPattern pattern;
  final String method;

  _UriPatternRequestMatcher(this.pattern, this.method);

  bool call(HttpRequest request) {
    return pattern.matches(request.uri)
        && (method == null || equalsIgnoreCase(request.method, method));
  }
}

class _PatternRequestMatcher implements Function {
  final Pattern pattern;
  final String method;

  _PatternRequestMatcher(this.pattern, this.method);

  bool call(HttpRequest request) {
    return matchesFull(pattern, request.uri.path)
        && (method == null || equalsIgnoreCase(request.method, method));
  }
}