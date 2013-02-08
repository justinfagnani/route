// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:route/server.dart';
import 'dart:io';

class HttpRequestMock extends Mock implements HttpRequest {
  String path;
  HttpRequestMock(this.path);
}

main() {
  test('matchesUrl', () {
    var url = new UrlPattern(r'/foo/(\d+)');
    var request1 = new HttpRequestMock('/foo/123');
    var request2 = new HttpRequestMock('foo');

    expect(matchesUrl(url)(request1), true);
    expect(matchesUrl(url)(request2), false);
  });
}
