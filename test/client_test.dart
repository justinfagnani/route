import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:route/client.dart';

main() {
  test('URL is handled by the right handler', () {
    var router = new Router();
    var url1 = new UrlPattern(r'/');
    var url2 = new UrlPattern(r'/foo/(\d+)');
    var testPath = '/foo/123';

    router.addHandler(url1, (String path) {
      fail('should not have been called');
    });

    router.addHandler(url2, (String path) {
      expect(path, testPath);
    });

    router.handle(testPath);
  });

  test('URL is handled by the right handler using fragments', () {
    var router = new Router(useFragment: true);
    var url2 = new UrlPattern(r'/foo#(\d+)');

    var testPath = '/foo/123';
    var testPathFragment = '/foo#123';

    router.addHandler(url2, (String path) {
      // always expect the non-fragment path
      expect(path, testPath);
    });

    router.handle(testPath);
    router.handle(testPathFragment);
  });
  
  test('paths are routed to routes added with addRoute', () {
    var router = new Router();
    var testPath = '/foo';
    
    router.addRoute(
      path: '/foo',
      enter: (RouteEvent e) {
        print('enter');
        expect(true, true);
      });
    
    router.handle(testPath);
  });

  test('click handler with fragment is routed when useFragment == true', () {
    var router = new Router(useFragment: true);
    var urlWithFragment = new UrlPattern(r'(.*)#fragment');
    router.addHandler(urlWithFragment, expectAsync1((String path) {
      expect(path, predicate((p) => p.endsWith('#fragment')));
    }));
    router.listen();
    query('#a_with_fragment').click();
  });

  test('addRoute', () {
    Router router = new Router();
    router.addRoute(path: '/foo', enter: expectAsync1((RouteEvent e) {
      expect(e.path, '/foo');
    }));
    router.handle('/foo');
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
          path: parentPath,
          enter: expectAsync1((RouteEvent e) {
            expect(e.path, expectedParentPath);
          }),
          mount: (Router child) {
            child.addRoute(path: childPath, enter: expectAsync1((RouteEvent e) {
              expect(e.path, expectedChildPath);
            }));
          });
      root.handle(testPath);
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

}
