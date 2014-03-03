library example;

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:route/client.dart';

import 'urls.dart' as urls;


var router;

main() {
  Logger.root
    ..level = Level.FINEST
    ..onRecord.listen((r) => print('[${r.level}] ${r.message}'));

  querySelector('#warning').remove();

  router = new Router({
    'home': route(urls.home, matchFull: true, onEnter: showHome),
    'one': route(urls.one, onEnter: showOne),
    'two': route(urls.two, onEnter: showTwo),
    'default': route(uri('/{+a}'), onEnter: showHome),
  }, index: 'one' /* , defaultRoute: 'home' */);

  querySelector('#linkOne').attributes['href'] = router['one'].getUri();
  querySelector('#linkTwo').attributes['href'] = router['two'].getUri();

  router.listen();
}

void showHome(RouteEvent e) {
  print("showHome: ${e.route.parent}");
  // redirects to /one
  router['one'].navigate();
}

void showOne(RouteEvent e) {
  print("showOne");
  querySelector('#one').classes.add('selected');
  querySelector('#two').classes.remove('selected');
  querySelector('#linkOne').classes.add('selected');
  querySelector('#linkTwo').classes.remove('selected');
}

void showTwo(RouteEvent e) {
  print("showTwo");
  querySelector('#one').classes.remove('selected');
  querySelector('#two').classes.add('selected');
  querySelector('#linkOne').classes.remove('selected');
  querySelector('#linkTwo').classes.add('selected');
}
