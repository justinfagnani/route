// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.url_pattern_test;

import 'package:unittest/unittest.dart';
import 'package:route/url_pattern.dart';

main() {
  test('matches1', () {
    var pattern = new UrlPattern('/');
    expect(pattern.matches(''), false);
    expect(pattern.matches('/'), true);
  });

  test('matches2', () {
    var pattern = new UrlPattern('/(/w+)');
    expect(pattern.matches(''), false);
    expect(pattern.matches('/'), false);
  });

  test('forward and reverse', () {
    expectPattern(r'foo', [], 'foo');
    expectPattern(r'(\w+)', ['foo'], 'foo');
    expectPattern(r'/(\w+)', ['foo'], '/foo');
    //TODO(justinfagnani): validate ambiguous patterns
    //expectPattern(r'/(\w+)(\w+)', ['foo', 'bar'], '/foobar');
    expectPattern(r'/(\w+)/(\w+)', ['foo', 'bar'], '/foo/bar');
  });
}

expectPattern(String pattern, List args, String url) {
  var p = new UrlPattern(pattern);
  expect(p.matches(url), true);
  expect(p.reverse(args), url);
  expect(p.parse(url), orderedEquals(args));
}
