// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library example;

import 'dart:html';
import 'package:route/client.dart';
import 'package:logging/logging.dart';
import 'urls.dart' as urls;

main() {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord r) { print(r.message); });

  query('#warning').remove();
  query('#one').classes.add('selected');

  var router = new Router()
    ..addHandler(urls.one, showOne)
    ..addHandler(urls.two, showTwo)
    ..addHandler(urls.home, (_) => null)
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
