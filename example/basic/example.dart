library example;

import 'dart:html';
import 'package:route/client.dart';

final one = new UrlPattern('/one');
final two = new UrlPattern('/two');

main() {
  query('#warning').remove();
  query('#one').classes.add('selected');

  var router = new Router(useFragment: true)
    ..addRoute(name: 'one', path: one, enter: showOne)
    ..addRoute(name: 'two', path: two, enter: showTwo)
    ..listen();
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
