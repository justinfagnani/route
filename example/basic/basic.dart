library example;

import 'dart:html';

import 'package:logging/logging.dart';
import '../../lib/client.dart';

main() {
  Logger.root
    ..level = Level.FINEST
    ..onRecord.listen((r) => print('[${r.level}] ${r.message}'));

  query('#warning').remove();

  var router = new Router({
    'one': route('/one')..onEnter.listen(showOne),
    'two': route('/two')..onEnter.listen(showTwo),
    'catchAll': route('/{a}')..onEnter.listen(showHome),
  }, index: 'one');

  query('#linkOne').attributes['href'] = router['one'].getUri();
  query('#linkTwo').attributes['href'] = router['two'].getUri();

  router.listen();
}

void showHome(RouteEvent e) {
  print("showHome: ${e.route.parent}");
  e.route.parent.navigate('one');
}

void showOne(RouteEvent e) {
  print("showOne");
  query('#one').classes.add('selected');
  query('#two').classes.remove('selected');
}

void showTwo(RouteEvent e) {
  print("showTwo");
  query('#one').classes.remove('selected');
  query('#two').classes.add('selected');
}
