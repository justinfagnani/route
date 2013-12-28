// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library example.server;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:observe/transformer.dart';
import 'package:path/path.dart' as path;
import 'package:route/server.dart';
import 'package:quiver/iterables.dart' as quiver;

import 'barback.dart';
import 'urls.dart' as urls;
import 'files.dart';

main() {
  final allUrls = new RegExp('/(.*)');

  initBarback('route', [
      [new ObservableTransformer(),
        new PathTransformer('/_web', 'route', ['client.html'])],
      ]).then((barback) {


    serveAsset(HttpRequest req, [String pathOverride]) {
      var assetId;
      var requestPath = pathOverride == null ? req.uri.path : pathOverride;
      var parts = path.split(requestPath);
      if (parts.length >= 3 && parts[2] == 'packages') {
        var package = parts[3];
        var libPathParts = parts.sublist(4);
        var assetPath = path.joinAll(quiver.concat([['lib'], libPathParts]));
        assetId = new AssetId(package, assetPath);
      } else {
        assetId = new AssetId('route', path.joinAll(parts.sublist(2)));
      }
      barback.updateSources([assetId]);
      barback.getAssetById(assetId).then((Asset asset) {
        req.response.headers.contentType =
            ContentTypes.forExtension(path.extension(asset.id.path));
        asset.read().pipe(req.response).then((_) => req.response.close());
      }).catchError((e, s) {
        print("error: $e");
        send404(req);
      });
    }

    HttpServer.bind('127.0.0.1', 8080).then((server) {
      var router = new Router(server)
      ..filter(allUrls, logRequest)
      ..serve(matchAny([urls.one, urls.two, urls.home])).listen((r) => serveAsset(r, 'client.html'))
      ..serve(allUrls).listen(serveAsset)
      ..defaultStream.listen(send404);
    });


  });

}

Future<bool> logRequest(HttpRequest req) {
  print("request: ${req.uri.path}");
  return new Future.value(true);
}
