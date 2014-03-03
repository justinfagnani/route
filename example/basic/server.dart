// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library example.server;

import 'dart:async';
import 'dart:io';

import 'package:route/server.dart';
import 'package:quiver/pattern.dart' show Glob;

import 'serve_asset.dart';
import 'urls.dart' as urls;

/**
 * This server is neccessary to respond to all URLs that are valid for the
 * client app. Since the client app uses Window.pushState, the location can be
 * set to serveral different URLs, and if the user hits reload the server needs
 * to be able to respond. We send the same HTML and Dart (client.html and
 * client.dart) for the URLs /, /one and /two.
 */
main() {
  final allUrls = new RegExp('/(.*)');

  // We serve through barback to do path fixes in HTML and the @observable
  // transform for polymer
  initBarback().then((serveAsset) {

    HttpServer.bind('127.0.0.1', 8080).then((server) {
      var router = new Router(server)
      ..filter(allUrls, logRequest)
      ..serve(matchAny([urls.one, urls.two, '/']))
          .listen((r) => serveAsset(r, 'client.html'))
      ..serve(new Glob('/packages/**')).listen(serveAsset)
      ..serve(matchAny(['/client.dart', '/urls.dart'])).listen(serveAsset)
      ..defaultStream.listen(send404);
    });

  });

}

Future<bool> logRequest(HttpRequest req) {
  print("request: ${req.uri.path}");
  return new Future.value(true);
}
