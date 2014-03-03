library route.router_test;

import 'dart:async';
//import 'dart:html';

import 'package:route/client.dart';
import 'package:uri/uri.dart';
import 'package:uri/matchers.dart';

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:unittest/html_enhanced_config.dart';

import '../html_mocks.dart';

main() {
  useHtmlEnhancedConfiguration();

  group('Router', () {

    var _window = new MockWindow();

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

    group('navigation', () {

      // TODO: test vetoing
      test('should call beforeExit', () {
        var wnd = new MockWindow();
        var router = new Router({
          'one': route(uri('/one'), children: {
            'a': route(uri('a'))
          }),
          'two': route(uri('/two'))
        }, window: wnd);
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
        var wnd = new MockWindow();
        var router = new Router({
          'one': route(uri('/one')),
          'two': route(uri('/two'), children: {
            'a': route(uri('a'))
          })
        }, window: wnd);
        router.root.currentChild = router['one'];

        return Future.wait([
          router['two'].beforeEnter.first.then((e) {
            expect(e.route, router['two']);
            expect(e.isExit, false);
          }),
          router['two.a'].beforeEnter.first.then((e) {
            expect(e.route, router['two.a']);
            expect(e.isExit, false);
          }),
          router.navigate(Uri.parse('/two/a'))
        ]);

      });

      test('should call onExit', () {
        var wnd = new MockWindow();
        var router = new Router({
          'one': route(uri('/one'), children: {
            'a': route(uri('a'))
          }),
          'two': route(uri('/two'))
        }, window: wnd);
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
        var wnd = new MockWindow();
        var router = new Router({
          'one': route(uri('/one')),
          'two': route(uri('/two'), children: {
            'a': route(uri('a'))
          })
        }, window: wnd);
        router.root.currentChild = router['one'];

        return Future.wait([
          router['two'].onEnter.first.then((e) {
            expect(e.route, router['two']);
            expect(e.isExit, false);
          }),
          router['two.a'].onEnter.first.then((e) {
            expect(e.route, router['two.a']);
            expect(e.isExit, false);
          }),
          router.navigate(Uri.parse('/two/a'))
        ]);

      });

      test('should call window.pushState', () {
        var wnd = new MockWindow();
        var router = new Router({
          'one': route(uri('/one'))
        }, window: wnd);
        var f2 = router.navigate(Uri.parse('/one'));
        return Future.wait([f2]).then((allowed) {
          expect(allowed[0], isTrue);
          wnd.history.getLogs(callsTo('pushState')).verify(happenedOnce);
        });
      });

    });

  });

}
