// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.router_test;

import 'dart:async';

import 'package:route/client.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:uri/matchers.dart';

import '../html_mocks.dart';

main() {
  useHtmlEnhancedConfiguration();

  group('Router', () {

    group('new Router()', () {

      test('should always have a root Route', () {
        var router = new Router({});
        expect(router.root, isNotNull);
      });

      test('should add child routes from constructor', () {
        var router = new Router({
          'one': route(uri('/one')),
          'two': route(uri('/two')),
        });
        expect(router.root.children, hasLength(2));
        expect(router.root.children['one'].pattern.toString(), '/one');
        expect(router.root.children['two'].pattern.toString(), '/two');
        expect(router['one'].pattern.expand({}), matchesUri(path: '/one'));
        expect(router['two'].pattern.expand({}), matchesUri(path: '/two'));
      });
    });

    group('event notifications', () {

      var wnd;
      var router;

      setUp(() {
        wnd = new MockWindow();
        router = new Router({
          'one': route(uri('/one'), children: {
            'a': route(uri('a'))
          }),
          'two': route(uri('/two'), children: {
            'b': route(uri('b'))
          })
        }, window: wnd);
      });

      // TODO: test vetoing
      test('should call beforeExit', () {
        router.root.currentChild = router['one'];
        router['one'].currentChild = router['one.a'];

        return Future.wait([
          router['one'].beforeExit.first.then((e) {
            expect(e.isExit, true);
            expect(e.route, router['one']);
          }),
          router['one.a'].beforeExit.first.then((e) {
            expect(e.isExit, true);
            expect(e.route, router['one.a']);
          }),
          router.navigate(Uri.parse('/two'))
        ]);
      });

      test('should call beforeEnter', () {
        router.root.currentChild = router['one'];

        return Future.wait([
          router['two'].beforeEnter.first.then((e) {
            expect(e.route, router['two']);
            expect(e.isExit, false);
          }),
          router['two.b'].beforeEnter.first.then((e) {
            expect(e.route, router['two.b']);
            expect(e.isExit, false);
          }),
          router.navigate(Uri.parse('/two/b'))
        ]);
      });

      test('should call onExit', () {
        router.root.currentChild = router['one'];
        router['one'].currentChild = router['one.a'];

        return Future.wait([
          router['one'].onExit.first.then((e) {
            expect(e.isExit, true);
            expect(e.route, router['one']);
          }),
          router['one.a'].onExit.first.then((e) {
            expect(e.isExit, true);
            expect(e.route, router['one.a']);
          }),
          router.navigate(Uri.parse('/two'))
        ]);
      });

      test('should call onEnter', () {
        router.root.currentChild = router['one'];

        return Future.wait([
          router['two'].onEnter.first.then((e) {
            expect(e.route, router['two']);
            expect(e.isExit, false);
          }),
          router['two.b'].onEnter.first.then((e) {
            expect(e.route, router['two.b']);
            expect(e.isExit, false);
          }),
          router.navigate(Uri.parse('/two/b'))
        ]);

      });

      test('should allow vetos from beforeExit', () {
        router.root.currentChild = router['one'];
        router['one'].currentChild = router['one.a'];

        router['two.b'].onEnter.first.then((e) {
          fail('should not be called');
        });

        return Future.wait([
          router['one'].beforeExit.first.then((RouteEvent e) {
            e.allowNavigation(new Future.value(false));
          }),
          router.navigate(Uri.parse('/two/b'))
        ]);;
      });

      test('should allow vetos from beforeEnter', () {
        router.root.currentChild = router['one'];
        router['one'].currentChild = router['one.a'];

        router['two.b'].onEnter.first.then((e) {
          fail('should not be called');
        });

        return Future.wait([
          router['two'].beforeEnter.first.then((RouteEvent e) {
            e.allowNavigation(new Future.value(false));
          }),
          router.navigate(Uri.parse('/two/b'))
        ]);;
      });

    });

    group('index routes', () {

      test('should activated when matched', () {
        var router = new Router({
          'one': route(uri('/one')),
        }, indexRoute: 'one');

        return Future.wait([
          router['one'].onEnter.first.then((e) {
            expect(true, true);
          }),
          router.navigate(Uri.parse('/')),
        ]);
      });

    });

    group('default routes', () {

      test('should activated when no other route matches', () {
        var router = new Router({
          'one': route(uri('/one')),
        }, defaultRoute: 'one');

        return Future.wait([
          router['one'].onEnter.first.then((e) {
            expect(true, true);
          }),
          router.navigate(Uri.parse('/two')),
        ]);
      });

    });


    group('browser navigation', () {

      test('should call window.pushState', () {
        var wnd = new MockWindow();
        var router = new Router({'one': route(uri('/one'))}, window: wnd);
        var f2 = router.navigate(Uri.parse('/one'));
        return Future.wait([f2]).then((allowed) {
          expect(allowed[0], isTrue);
          wnd.history.getLogs(callsTo('pushState')).verify(happenedOnce);
        });
      });

    });

  });

}
