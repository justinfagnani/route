// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.test.server_test;

import 'dart:async';
import 'dart:io';

import 'package:route/server.dart';
import 'package:unittest/unittest.dart';
import 'package:uri/uri.dart';

import 'http_mocks.dart';

main() {

  group('Router', () {

    StreamController<HttpRequest> controller;
    Router router;

    setUp(() {
      controller = new StreamController<HttpRequest>();
      router = new Router(controller.stream);
    });

    group('serve()', () {

      test('should route requests based on http method', () {
        var request = new HttpRequestMock(Uri.parse('/foo'), method:'GET');
        router.serve('/foo', method:'GET').listen(expectAsync1((req) {
          expect(req, request);
        }));
        router.serve('/foo', method:'POST').listen(expectAsync1((_) {},
            count:0));
        controller.add(request);
      });

      test('should serve all http methods if none provided', () {
        var getRequest = new HttpRequestMock(Uri.parse('/foo'), method:'GET');
        var postRequest = new HttpRequestMock(Uri.parse('/foo'), method:'POST');
        var requests = <HttpRequest>[];
        router.serve('/foo').listen(expectAsync1((request) {
          requests.add(request);
          if (requests.length == 2){
            expect(requests, [getRequest, postRequest]);
          }
        }, count: 2));
        controller.add(getRequest);
        controller.add(postRequest);
      });

      test('should route requests based on the matcher', () {
        var request = new HttpRequestMock(Uri.parse('/foo'));
        router.serve('/foo').listen(expectAsync1((req) {
          expect(req, request);
        }));
        router.serve('/bar').listen(expectAsync1((req) {}, count: 0));
        controller.add(request);
      });

      test('should route requests based on the matcher 2', () {
        var request = new HttpRequestMock(Uri.parse('/bar'));
        router.serve('/foo').listen(expectAsync1((req) {}, count: 0));
        router.serve('/bar').listen(expectAsync1((req) {
          expect(req, request);
        }));
        controller.add(request);
      });

      test('should support UriPatterns', () {
        var request = new HttpRequestMock(Uri.parse('/foo/bar'));
        router.serve(new UriParser(new UriTemplate('/foo')))
          .listen(expectAsync1((req) {
            expect(req, request);
          }));
        router.serve('/bar').listen(expectAsync1((req) {}, count: 0));
        controller.add(request);
      });

      test('should support RequestMatchers', () {
        var request = new HttpRequestMock(Uri.parse('/foo'));
        router.serve((HttpRequest r) => r.uri.path == '/foo')
          .listen(expectAsync1((req) {
            expect(req, request);
          }));
        router.serve('/bar').listen(expectAsync1((req) {}, count: 0));
        controller.add(request);
      });

      test('should disallow RequestMatchers and http methods', () {
        expect(() => router.serve((HttpRequest r) => r.uri.path == '/foo',
            method: 'GET'), throwsArgumentError);
      });

      test('should send a 404 if no matchers match', () {
        var request = new HttpRequestMock(Uri.parse('/bar'));
        request.response.onClose = expectAsync0(() {
          expect(request.response.statusCode, 404);
        });
        router.serve('/foo').listen(expectAsync1((req) {}, count: 0));
        controller.add(request);
      });

      test('should route to the default stream if no matchers match', () {
        var request = new HttpRequestMock(Uri.parse('/bar'));
        router.defaultStream.listen(expectAsync1((HttpRequest req) {
          expect(req, request);
        }));
        controller.add(request);
      });
    });

    group('filter()', () {

      test('should call a filter when it matches', () {
        var request = new HttpRequestMock(Uri.parse('/foo'));
        router.filter('/foo', expectAsync1((req) {
          expect(req, request);
          return new Future.value(true);
        }));
        controller.add(request);
      });

      test('should not call a filter when it does not match', () {
        var request = new HttpRequestMock(Uri.parse('/bar'));
        router.filter('/foo', expectAsync1((req) {}, count: 0));
        controller.add(request);
      });

      test('should call consequtive filters', () {
        var request = new HttpRequestMock(Uri.parse('/foo'));
        router.filter('/foo', expectAsync1((req) {
          expect(req, request);
          return new Future.value(true);
        }));
        router.filter('/foo', expectAsync1((req) {
          expect(req, request);
          return new Future.value(true);
        }));
        controller.add(request);
      });

      test('should continue routing when the filter returns true', () {
        var request = new HttpRequestMock(Uri.parse('/foo'));
        router.filter('/foo', expectAsync1((req) {
          expect(req, request);
          return new Future.value(true);
        }));
        router.serve('/foo').listen(expectAsync1((req) {
          expect(req, request);
        }));
        controller.add(request);
      });

      test('should stop routing when the filter returns false', () {
        var request = new HttpRequestMock(Uri.parse('/foo'));
        router.filter('/foo', expectAsync1((req) {
          expect(req, request);
          return new Future.value(false);
        }));
        router.filter('/foo', expectAsync1((req) {}, count: 0));
        router.serve('/foo').listen(expectAsync1((req) {}, count: 0));
        controller.add(request);
      });

    });

  });

}
