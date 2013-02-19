// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.url_pattern_test;

import 'package:unittest/unittest.dart';
import 'package:route/url_pattern.dart';

main() {
  test('no groups', () {
    checkPattern('/', '/', [], ['', 'a', '/a']);
    checkPattern('a', 'a', [], ['', '/', '/a']);
  });

  test('basic groups', () {
    checkPattern(r'(\w+)', 'ab', ['ab'], ['(ab)', '', ' ']);
  });

  test('escaping', () {
    checkPattern(r'\\', r'\', []);
    // it's ok to leave a hanging escape?
    checkPattern(r'\\\', r'\', []);
    checkPattern(r'\a', r'a', []);
    checkPattern(r'\(a\)', '(a)', [], ['a']);
    checkPattern(r'(a\))', 'a)', ['a)'], ['a']);
    checkPattern(r'(\\w)', r'\w', [r'\w'], [r'\a']);
  });

  test('more groups', () {
    checkPattern(r'/(\w+)', '/foo', ['foo'], ['foo']);
    checkPattern(r'/(\w+)/(\w+)', '/foo/bar', ['foo', 'bar']);
    // these are odd cases. maybe we should ban nested groups.
    checkPattern(r'((\w+))', 'a', ['a', 'a'], ['(a)']);
    checkPattern(r'((\w+)(\d+))', 'a1', ['a1', 'a', '1'], ['(a1)']);
  });

  test('ambiguous groups', () {
    expect(() => new UrlPattern(r'(\w+)(\w+)'), throws);
  });

  test('unmatching parens', () {
    expect(() => new UrlPattern('('), throws);
    expect(() => new UrlPattern(')'), throws);
    expect(() => new UrlPattern('(()'), throws);
    expect(() => new UrlPattern('())'), throws);
  });

  test('special chars outside groups', () {
    checkPattern('^', '^', []);
    checkPattern(r'$', r'$', []);
    checkPattern('.', '.', [], ['a']);
    checkPattern('|', '|', [], ['a']);
    checkPattern('+', '+', [], ['a']);
    checkPattern('[', '[', [], ['a']);
    checkPattern(']', ']', [], ['a']);
    checkPattern('{', '{', [], ['a']);
    checkPattern('}', '}', [], ['a']);
  });
}

checkPattern(String p, String url, List args, [List nonMatches]) {
  var pattern = new UrlPattern(p);
  expect(pattern.matches(url), true);
  expect(pattern.reverse(args), url);
  expect(pattern.parse(url), orderedEquals(args));
  if (nonMatches != null) {
    for (var url in nonMatches) {
      expect(pattern.matches(url), false);
    }
  }
}
