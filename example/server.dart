library example.server;

import 'dart:async';
import 'dart:io';

import 'package:route/server.dart';
import 'package:route/pattern.dart';

import 'files.dart';

main() {
  final allUrls = new RegExp('/(.*)');

  HttpServer.bind('127.0.0.1', 8080).then((server) {
    var router = new Router(server)
      ..filter(allUrls, logRequest)
      ..serve(matchAny(['/one', '/two'])).listen(serveFile('client.html'))
      ..serve(allUrls).listen(serveDirectory('', as: '/'))
      ..defaultStream.listen(send404);
  });
}

Future<bool> logRequest(HttpRequest req) {
  print("request: ${req.uri.path}");
  return new Future.value(true);
}
