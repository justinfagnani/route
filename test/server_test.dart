// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:route/server.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:uri';

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  HttpResponseMock response = new HttpResponseMock();
  HttpRequestMock(this.uri);
}

class HttpResponseMock extends Mock implements HttpResponse {
  int statusCode;
  var _onClose;
  void close() {
    if (_onClose != null) {
      _onClose();
    }
  }
}

main() {
  test('serve 1', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(new Uri('/foo'));
    router.serve('/foo').listen(expectAsync1((req) {
      expect(req, testReq);
    }));
    router.serve('/bar').listen(expectAsync1((req) {}, count: 0));
    controller.add(testReq);
  });

  test('serve 2', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(new Uri('/bar'));
    router.serve('/foo').listen(expectAsync1((req) {}, count: 0));
    router.serve('/bar').listen(expectAsync1((req) {
      expect(req, testReq);
    }));
    controller.add(testReq);
  });

  test('404', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(new Uri('/bar'));
    testReq.response._onClose = expectAsync0(() {
      expect(testReq.response.statusCode, 404);
    });
    router.serve('/foo').listen(expectAsync1((req) {}, count: 0));
    controller.add(testReq);
  });

  test('default', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(new Uri('/bar'));
    testReq.response._onClose = expectAsync0(() {
      expect(testReq.response.statusCode, 200);
    });
    router.defaultStream.listen(expectAsync1((HttpRequest req) {
      req.response.statusCode = 200;
      req.response.close();
    }));
    controller.add(testReq);
  });

  test('filter pass', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(new Uri('/foo'));
    router.filter('/foo', expectAsync1((req) {
      expect(req, testReq);
      return new Future.immediate(true);
    }));
    router.serve('/foo').listen(expectAsync1((req) {
      expect(req, testReq);
    }));
    controller.add(testReq);
  });

  test('filter no-pass', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(new Uri('/foo'));
    router.filter('/foo', expectAsync1((req) {
      expect(req, testReq);
      return new Future.immediate(false);
    }));
    router.serve('/foo').listen(expectAsync1((req) {}, count: 0));
    controller.add(testReq);
  });

}
