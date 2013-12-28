// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:unittest/mock.dart';

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;
  HttpResponseMock response = new HttpResponseMock();

  HttpRequestMock(this.uri, {this.method});
  noSuchMethod(i) => super.noSuchMethod(i);
}

class HttpResponseMock extends Mock implements HttpResponse {
  int statusCode;
  var onClose;

  Future close() {
    if (onClose != null) {
      onClose();
    }
    return new Future.value();
  }
  noSuchMethod(i) => super.noSuchMethod(i);
}
