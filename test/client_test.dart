import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:route/client.dart';
import 'mocks.dart';

main() {

  test('paths are routed to routes added with addRoute', () {
    var router = new Router();
    var testPath = '/foo';

    router.addRoute(
      name: 'foo',
      path: '/foo',
      enter: (RouteEvent e) {
        print('enter');
        expect(true, true);
      });

    router.route(testPath);
  });

  test('addRoute', () {
    Router router = new Router();
    router.addRoute(
        name: 'foo',
        path: '/foo',
        enter: expectAsync1((RouteEvent e) {
          expect(e.path, '/foo');
        }));
    router.route('/foo');
  });

  group('hierarchical routing', () {

    _testParentChild(
        Pattern parentPath,
        Pattern childPath,
        String expectedParentPath,
        String expectedChildPath,
        String testPath) {
      Router root = new Router();
      root.addRoute(
          name: 'parent',
          path: parentPath,
          enter: expectAsync1((RouteEvent e) {
            expect(e.path, expectedParentPath);
          }),
          mount: (Router child) {
            child.addRoute(
                name: 'child',
                path: childPath,
                enter: expectAsync1((RouteEvent e) {
                  expect(e.path, expectedChildPath);
                }));
          });
      root.route(testPath);
    }

    test('child router with UrlPattern', () {
      _testParentChild(
          new UrlPattern(r'/foo/(\w+)'),
          new UrlPattern(r'/bar'),
          '/foo/abc',
          '/bar',
          '/foo/abc/bar');
    });

    test('child router with Strings', () {
      _testParentChild(
          '/foo',
          '/bar',
          '/foo',
          '/bar',
          '/foo/bar');
    });

  });

  group('leave', () {

    test('should leave previous route and enter new', () {
      Map<String, int> counters = <String, int>{
        'fooEnter': 0,
        'fooLeave': 0,
        'barEnter': 0,
        'barLeave': 0,
        'bazEnter': 0,
        'bazLeave': 0
      };
      Router root = new Router()
        ..addRoute(path: '/foo',
            name: 'foo',
            enter: (RouteEvent e) => counters['fooEnter']++,
            leave: (RouteEvent e) => counters['fooLeave']++,
            mount: (Router router) =>
                router
                    ..addRoute(path: '/bar',
                        name: 'bar',
                        enter: (RouteEvent e) => counters['barEnter']++,
                        leave: (RouteEvent e) => counters['barLeave']++)
                    ..addRoute(path: '/baz',
                        name: 'baz',
                        enter: (RouteEvent e) => counters['bazEnter']++,
                        leave: (RouteEvent e) => counters['bazLeave']++));

      expect(counters, {
        'fooEnter': 0,
        'fooLeave': 0,
        'barEnter': 0,
        'barLeave': 0,
        'bazEnter': 0,
        'bazLeave': 0
      });

      root.route('/foo/bar').then(expectAsync1((_) {
        expect(counters, {
          'fooEnter': 1,
          'fooLeave': 0,
          'barEnter': 1,
          'barLeave': 0,
          'bazEnter': 0,
          'bazLeave': 0
        });

        root.route('/foo/baz').then(expectAsync1((_) {
          expect(counters, {
            'fooEnter': 1,
            'fooLeave': 0,
            'barEnter': 1,
            'barLeave': 1,
            'bazEnter': 1,
            'bazLeave': 0
          });
        }));
      }));
    });

    _testAllowLeave(bool allowLeave) {
      Completer<bool> completer = new Completer<bool>();
      bool barEntered = false;
      bool bazEntered = false;

      Router root = new Router()
        ..addRoute(name: 'foo', path: '/foo',
            mount: (Router router) =>
              router
                ..addRoute(name: 'bar', path: '/bar',
                    enter: (RouteEvent e) => barEntered = true,
                    leave: (RouteEvent e) => e.allowLeave(completer.future))
                ..addRoute(name: 'baz', path: '/baz',
                    enter: (RouteEvent e) => bazEntered = true));

      root.route('/foo/bar').then(expectAsync1((_) {
        expect(barEntered, true);
        expect(bazEntered, false);
        root.route('/foo/baz').then(expectAsync1((_) {
          expect(bazEntered, allowLeave);
        }));
        completer.complete(allowLeave);
      }));
    }

    test('should allow navigation', () {
      _testAllowLeave(true);
    });

    test('should veto navigation', () {
      _testAllowLeave(false);
    });
  });

  group('Default route', () {

    _testHeadTail(String path, String expectFoo, String expectBar) {
      Router root = new Router()
        ..addRoute(
            name: 'foo',
            path: '/foo',
            defaultRoute: true,
            enter: expectAsync1((RouteEvent e) {
              expect(e.path, expectFoo);
            }),
            mount: (router) =>
                router
                  ..addRoute(
                      name: 'bar',
                      path: '/bar',
                      defaultRoute: true,
                      enter: expectAsync1((RouteEvent e) =>
                          expect(e.path, expectBar))));

      root.route(path);
    }

    test('should correctly calculate head/tail of empty route', () {
      _testHeadTail('', '', '');
    });

    test('should correctly calculate head/tail of partial route', () {
      _testHeadTail('/foo', '/foo', '');
    });

    test('should correctly calculate head/tail of a route', () {
      _testHeadTail('/foo/bar', '/foo', '/bar');
    });

    test('should correctly calculate head/tail of an invalid parent route', () {
      _testHeadTail('/garbage/bar', '', '');
    });

    test('should correctly calculate head/tail of an invalid child route', () {
      _testHeadTail('/foo/garbage', '/foo', '');
    });

    test('should follow default routes', () {
      Map<String, int> counters = <String, int>{
        'list_entered': 0,
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      };

      Router root = new Router()
        ..addRoute(
            name: 'articles',
            path: '/articles',
            defaultRoute: true,
            enter: (_) => counters['list_entered']++)
        ..addRoute(
            name: 'article',
            path: '/article/123',
            enter: (_) => counters['article_123_entered']++,
            mount: (Router router) =>
              router
                ..addRoute(
                    name: 'viewArticles',
                    path: '/view',
                    defaultRoute: true,
                    enter: (_) => counters['article_123_view_entered']++)
                ..addRoute(
                    name: 'editArticles',
                    path: '/edit',
                    enter: (_) => counters['article_123_edit_entered']++));

      root.route('').then((_) {
        expect(counters, {
          'list_entered': 1, // default to list
          'article_123_entered': 0,
          'article_123_view_entered': 0,
          'article_123_edit_entered': 0
        });
        root.route('/articles').then((_) {
          expect(counters, {
            'list_entered': 1, // already current route
            'article_123_entered': 0,
            'article_123_view_entered': 0,
            'article_123_edit_entered': 0
          });
          root.route('/article/123').then((_) {
            expect(counters, {
              'list_entered': 1,
              'article_123_entered': 1,
              'article_123_view_entered': 1, // default to view
              'article_123_edit_entered': 0
            });
            root.route('/article/123/view').then((_) {
              expect(counters, {
                'list_entered': 1,
                'article_123_entered': 1,
                'article_123_view_entered': 1, // already current route
                'article_123_edit_entered': 0
              });
              root.route('/article/123/edit').then((_) {
                expect(counters, {
                  'list_entered': 1,
                  'article_123_entered': 1,
                  'article_123_view_entered': 1,
                  'article_123_edit_entered': 1
                });
              });
            });
          });
        });
      });
    });

  });

  group('go', () {

    test('shoud location.assign/replace when useFragment=true', () {
      MockWindow mockWindow = new MockWindow();
      Router root = new Router(useFragment: true, windowImpl: mockWindow)
        ..addRoute(
            name: 'articles',
            path: '/articles');

      root.go('articles', {}).then(expectAsync1((_) {
        var mockLocation = mockWindow.location;

        mockLocation.getLogs(callsTo('assign', anything))
            .verify(happenedExactly(1));
        expect(mockLocation.getLogs(callsTo('assign', anything)).last.args,
            ['#/articles']);
        mockLocation.getLogs(callsTo('replace', anything))
            .verify(happenedExactly(0));

        root.go('articles', {}, replace: true).then(expectAsync1((_) {
          mockLocation.getLogs(callsTo('replace', anything))
              .verify(happenedExactly(1));
          expect(mockLocation.getLogs(callsTo('replace', anything)).last.args,
              ['#/articles']);
          mockLocation.getLogs(callsTo('assign', anything))
              .verify(happenedExactly(1));
        }));
      }));
    });

    test('shoud history.push/replaceState when useFragment=false', () {
      MockWindow mockWindow = new MockWindow();
      Router root = new Router(useFragment: false, windowImpl: mockWindow)
        ..addRoute(
            name: 'articles',
            path: '/articles');

      root.go('articles', {}).then(expectAsync1((_) {
        var mockHistory = mockWindow.history;

        mockHistory.getLogs(callsTo('pushState', anything))
            .verify(happenedExactly(1));
        expect(mockHistory.getLogs(callsTo('pushState', anything)).last.args,
            [null, '', '/articles']);
        mockHistory.getLogs(callsTo('replaceState', anything))
            .verify(happenedExactly(0));

        root.go('articles', {}, replace: true).then(expectAsync1((_) {
          mockHistory.getLogs(callsTo('replaceState', anything))
              .verify(happenedExactly(1));
          expect(mockHistory.getLogs(callsTo('replaceState', anything)).last.args,
              [null, '', '/articles']);
          mockHistory.getLogs(callsTo('pushState', anything))
              .verify(happenedExactly(1));
        }));
      }));
    });

    test('should work with hierarchical go', () {
      MockWindow mockWindow = new MockWindow();
      Router bRouter;
      Router root = new Router(windowImpl: mockWindow)
        ..addRoute(
            name: 'a',
            path: '/:foo',
            mount: (router) =>
                bRouter = router
                  ..addRoute(
                      name: 'b',
                      path: '/:bar'));

      root.go('a.b', {}).then(expectAsync1((_) {
        var mockHistory = mockWindow.history;

        mockHistory.getLogs(callsTo('pushState', anything))
            .verify(happenedExactly(1));
        expect(mockHistory.getLogs(callsTo('pushState', anything)).last.args,
            [null, '', '/null/null']);

        root.go('a.b', {'foo': 'aaaa', 'bar': 'bbbb'}).then(expectAsync1((_) {
          mockHistory.getLogs(callsTo('pushState', anything))
              .verify(happenedExactly(2));
          expect(mockHistory.getLogs(callsTo('pushState', anything)).last.args,
              [null, '', '/aaaa/bbbb']);

          bRouter.go('b', {'bar': 'bbbb'}).then(expectAsync1((_) {
            mockHistory.getLogs(callsTo('pushState', anything))
               .verify(happenedExactly(3));
            expect(mockHistory.getLogs(callsTo('pushState', anything)).last.args,
                [null, '', '/aaaa/bbbb']);
          }));

        }));
      }));

    });

    test('shold attempt to reverse default routes', () {
      Map<String, int> counters = <String, int>{
        'aEnter': 0,
        'bEnter': 0
      };

      MockWindow mockWindow = new MockWindow();
      var bRouter;
      Router root = new Router(windowImpl: mockWindow)
        ..addRoute(
            name: 'a',
            defaultRoute: true,
            path: '/:foo',
            enter: (_) => counters['aEnter']++,
            mount: (router) =>
                bRouter = router
                  ..addRoute(
                      name: 'b',
                      defaultRoute: true,
                      path: '/:bar',
                      enter: (_) => counters['bEnter']++));

      expect(counters, {
        'aEnter': 0,
        'bEnter': 0
      });

      root.route('').then((_) {
        expect(counters, {
          'aEnter': 1,
          'bEnter': 1
        });

        bRouter.go('b', {'bar': 'bbb'}).then((_) {
          var mockHistory = mockWindow.history;

          mockHistory.getLogs(callsTo('pushState', anything))
             .verify(happenedExactly(1));
          expect(mockHistory.getLogs(callsTo('pushState', anything)).last.args,
              [null, '', '/null/bbb']);
        });
      });
    });

  });

}
