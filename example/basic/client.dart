library example;

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:route/client.dart';

import 'urls.dart' as urls;

main() {
  Logger.root
    ..level = Level.FINEST
    ..onRecord.listen((r) => print('[${r.level}] ${r.message}'));

  querySelector('#warning').remove();

  var router = new Router({
    'home': route(urls.home)..onEnter.listen(showHome),
    'one': route(urls.one)..onEnter.listen(showOne),
    'two': route(urls.two)..onEnter.listen(showTwo),
    'catchAll': route('/{a}')..onEnter.listen(showHome),
  }, index: 'one');

  querySelector('#linkOne').attributes['href'] = router['one'].getUri();
  querySelector('#linkTwo').attributes['href'] = router['two'].getUri();

  router.listen();
}

void showHome(RouteEvent e) {
  print("showHome: ${e.route.parent}");
  e.route.parent.navigate('one');
}

void showOne(RouteEvent e) {
  print("showOne");
  querySelector('#one').classes.add('selected');
  querySelector('#two').classes.remove('selected');
}

void showTwo(RouteEvent e) {
  print("showTwo");
  querySelector('#one').classes.remove('selected');
  querySelector('#two').classes.add('selected');
}
