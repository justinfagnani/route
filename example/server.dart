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

const HOST = '127.0.0.1';
const PORT = 8080;
main() {
  final allUrls = new RegExp('/(.*)');

  HttpServer.bind(HOST, PORT).then((server) {
    var router = new Router(server)
      ..filter(allUrls, logRequest)
      ..serve(matchAny([urls.one, urls.two, urls.home])).listen(f) //serveFile('client.html'))
      ..serve(allUrls).listen(serveDirectory('', as: '/'))
      ..defaultStream.listen(send404);
    print('started server at http://$HOST:$PORT');
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
