// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.test.request_matcher_test;

import 'package:route/src/server/request_matcher.dart';
import 'package:unittest/unittest.dart';

import 'http_mocks.dart';

main() {
  group('matchAny', () {

    test('should match if any matchers match', () {
      var request = new HttpRequestMock(Uri.parse('/foo'));
      expect(matchAny(['/foo'])(request), isTrue);
      expect(matchAny([(r) => true])(request), isTrue);
      expect(matchAny(['/bar', '/foo'])(request), isTrue);
    });

    test('should not match if no matchers match', () {
      var request = new HttpRequestMock(Uri.parse('/foo'));
      expect(matchAny([])(request), isFalse);
      expect(matchAny(['/bar', (r) => false])(request), isFalse);
    });

  });
}
