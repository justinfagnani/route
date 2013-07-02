// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library example.server;

import 'dart:async';
import 'dart:io';

import 'package:route/server.dart';
import 'package:route/pattern.dart';

import 'urls.dart' as urls;
import 'files.dart';

main() {
  final allUrls = new RegExp('/(.*)');

  HttpServer.bind('127.0.0.1', 8080).then((server) {
    var router = new Router(server)
      ..filter(allUrls, logRequest)
      ..serve(matchAny([urls.one, urls.two, urls.home])).listen(f) //serveFile('client.html'))
      ..serve(allUrls).listen(serveDirectory('', as: '/'))
      ..defaultStream.listen(send404);
  });
}

f(HttpRequest req) {
  print("${req.uri.path}");
  return serveFile('client.html')(req);
}

Future<bool> logRequest(HttpRequest req) {
  print("request: ${req.uri.path}");
  return new Future.value(true);
}
