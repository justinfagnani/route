library client_test;

import 'package:unittest/unittest.dart';
import 'package:route/client.dart';

main() {
  test('handle', () {
    var router = new Router();
    var url1 = new UrlPattern(r'/');
    var url2 = new UrlPattern(r'/foo/(\d+)');
    var testPath = '/foo/123';

    router.addRoute(path: url1, enter: (RouteEvent e) {
      fail('should not have been called');
    });

    router.addRoute(path: url2, enter: (RouteEvent e) {
      expect(e.current.path, testPath);
    });

    router.route(testPath);
  });

  test('fragment', () {
    var router = new Router(useFragment: true);
    var url2 = new UrlPattern(r'/foo#(\d+)');

    var testPath = '/foo/123';
    var testPathFragment = '/foo#123';

    var wasCalled = 0;
    router.addRoute(path: url2, enter: (RouteEvent e) {
      wasCalled++;
      // always expect the non-fragment path
      expect(e.current.path, testPath);
    });

    expect(wasCalled, equals(0));
    router.route(testPath);
    expect(wasCalled, equals(1));
    router.route(testPathFragment);
    expect(wasCalled, equals(2));
  });

}
