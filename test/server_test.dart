// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mock/mock.dart';
import 'package:route/server.dart';
import 'package:unittest/unittest.dart';

class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  String method;
  HttpResponseMock response = new HttpResponseMock();

  HttpRequestMock(this.uri, {this.method});

  noSuchMethod(i) => super.noSuchMethod(i);
}

class HttpResponseMock extends Mock implements HttpResponse {
  int statusCode;
  var _onClose;

  Future close() {
    if (_onClose != null) {
      _onClose();
    }
    return new Future.value();
  }

  noSuchMethod(i) => super.noSuchMethod(i);
}

main() {
  test ('http method can be used to distinguish route', (){
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(Uri.parse('/foo'),method:'GET');
    router.serve('/foo', method:'GET').listen(expectAsync((req) {
      expect(req, testReq);
    }));
    router.serve('/foo', method:'POST').listen(expectAsync((_) {}, count:0));
    controller.add(testReq);
  });

  test ('if no http method provided, all methods match', (){
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testGetReq = new HttpRequestMock(Uri.parse('/foo'), method:'GET');
    var testPostReq = new HttpRequestMock(Uri.parse('/foo'), method:'POST');
    var requests = <HttpRequest>[];
    router.serve('/foo').listen(expectAsync((request) {
      requests.add(request);
      if (requests.length == 2){
        expect(requests, [testGetReq, testPostReq]);
      }
    }, count: 2));
    controller.add(testGetReq);
    controller.add(testPostReq);

  });

  test('serve 1', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(Uri.parse('/foo'));
    router.serve('/foo').listen(expectAsync((req) {
      expect(req, testReq);
    }));
    router.serve('/bar').listen(expectAsync((req) {}, count: 0));
    controller.add(testReq);
  });

  test('serve 2', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(Uri.parse('/bar'));
    router.serve('/foo').listen(expectAsync((req) {}, count: 0));
    router.serve('/bar').listen(expectAsync((req) {
      expect(req, testReq);
    }));
    controller.add(testReq);
  });

  test('404', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(Uri.parse('/bar'));
    testReq.response._onClose = expectAsync(() {
      expect(testReq.response.statusCode, 404);
    });
    router.serve('/foo').listen(expectAsync((req) {}, count: 0));
    controller.add(testReq);
  });

  test('default', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(Uri.parse('/bar'));
    testReq.response._onClose = expectAsync(() {
      expect(testReq.response.statusCode, 200);
    });
    router.defaultStream.listen(expectAsync((HttpRequest req) {
      req.response.statusCode = 200;
      req.response.close();
    }));
    controller.add(testReq);
  });

  test('filter pass', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(Uri.parse('/foo'));
    router.filter('/foo', expectAsync((req) {
      expect(req, testReq);
      return new Future.value(true);
    }));
    router.serve('/foo').listen(expectAsync((req) {
      expect(req, testReq);
    }));
    controller.add(testReq);
  });

  test('filter no-pass', () {
    var controller = new StreamController<HttpRequest>();
    var router = new Router(controller.stream);
    var testReq = new HttpRequestMock(Uri.parse('/foo'));
    router.filter('/foo', expectAsync((req) {
      expect(req, testReq);
      return new Future.value(false);
    }));
    router.serve('/foo').listen(expectAsync((req) {}, count: 0));
    controller.add(testReq);
  });

}
