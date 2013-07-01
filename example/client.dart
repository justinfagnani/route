library example;

import 'dart:html';
import 'package:route/client.dart';
import 'package:logging/logging.dart';

final one = new UrlPattern('/one');
final two = new UrlPattern('/two');
final example = new UrlPattern('/(.*)/example.html');

main() {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord r) { print(r.message); });

  query('#warning').remove();
  query('#one').classes.add('selected');

  var router = new Router()
    ..addHandler(one, showOne)
    ..addHandler(two, showTwo)
    ..addHandler(example, (_) => null)
    ..listen();
}

void showOne(String path) {
  print("showOne");
  query('#one').classes.add('selected');
  query('#two').classes.remove('selected');
}

void showTwo(String path) {
  print("showTwo");
  query('#one').classes.remove('selected');
  query('#two').classes.add('selected');
}
