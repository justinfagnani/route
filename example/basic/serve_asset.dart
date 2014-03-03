// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.example.basic.serve_asset;

import 'dart:async';
import 'dart:io';

import 'package:observe/transformer.dart';
import 'package:barback/barback.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/dom.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/io.dart' as quiver;
import 'package:quiver/iterables.dart' as quiver;
import 'package:route/server.dart';

import 'files.dart';

final Logger _logger = new Logger('barback');

final String _packagesDir = 'packages/';

class _PackageProvider implements PackageProvider {
  final Map<String, String> _packages;

  Iterable<String> get packages {
    return _packages.keys;
  }

  static Future<_PackageProvider> create() {
    var packages = <String, String>{};
    return new Directory(_packagesDir).list(followLinks: false).listen((e) {
      var packageName = e.path.substring(_packagesDir.length);
      var parts = path.split((e as Link).resolveSymbolicLinksSync());
      var packagePath = path.joinAll(parts.getRange(0, parts.length - 1));
      packages[packageName] = packagePath;
    }).asFuture().then((_) => new _PackageProvider(packages));
  }

  _PackageProvider(this._packages);

  Future<Asset> getAsset(AssetId id) {
    var packagePath = _packages[id.package];
    var assetPath = (id.package == 'route' && !id.path.startsWith('lib'))
        ? path.join('example/basic', id.path)
        : id.path;
    var fullPath = path.join(packagePath, assetPath);
    print("getAsset: $id $fullPath");
    return new Future.value(new Asset.fromPath(id, fullPath));
  }
}

Future<List<AssetId>> _getLibAssets() =>
  new Directory(_packagesDir).list(recursive: true)
    .where((e) => e is File)
    .map((e) {
      var parts = path.split(e.path);
      var package = parts[1];
      var assetPath = path.joinAll(['lib']..addAll(parts.sublist(2)));
      return new AssetId(package, assetPath);
    })
    .toList();

//Future<List<AssetId>> _getWebAssets(String packageName) {
//  var assets = [];
//  return quiver.visitDirectory(new Directory('web'), (e) {
//    if (e is File) assets.add(new AssetId(packageName, path.joinAll(path.split(e.path).sublist(1))));
//    return new Future.value(!e.path.endsWith('packages'));
//  }).then((_) => assets);
//}

Future<List<String>> _getPackages() =>
    new Directory(_packagesDir).list(followLinks: false)
        .map((e) => e.path.substring(_packagesDir.length))
        .toList();

typedef Future<List<String>> PackagePathProvider();

Future<Barback> initBarback() {
  var phases = [[new ObservableTransformer()]];
  var pathTransformer = [[new PathTransformer('/', 'route', ['client.html'])]];
  var exampleAssets = ['client.html', 'client.dart', 'urls.dart'].map((f) =>
    new AssetId('route', f));
  return _PackageProvider.create()
    .then((provider) => _getLibAssets()
    .then((assets) {
      assets = quiver.concat([assets, exampleAssets]);
      var barback = new Barback(provider)..updateSources(assets);
      return _getPackages().then((packages) {
        for (var package in packages) {
          print(package);
          if (package == 'route') {
            barback.updateTransformers(package, quiver.concat([phases, pathTransformer]));
          } else {
            barback.updateTransformers(package, phases);
          }
        }
        return serveAsset(barback);
      });
  }));
}

serveAsset(barback) => (HttpRequest req, [String pathOverride]) {
  print("serveAsset: ${req.uri}");
  var assetId;
  var requestPath = pathOverride == null ? req.uri.path : pathOverride;
  var parts = path.split(requestPath);
  print(parts);
  if (parts.length > 3 && parts[1] == 'packages') {
    var package = parts[2];
    var libPathParts = parts.sublist(3);
    var assetPath = path.joinAll(quiver.concat([['lib'], libPathParts]));
    assetId = new AssetId(package, assetPath);
  } else {
    var assetParts = parts.first == '/' ? parts.sublist(1) : parts;
    assetId = new AssetId('route', path.joinAll(assetParts));
  }
  barback.updateSources([assetId]);
  print("getting asset");
  barback.getAssetById(assetId).then((Asset asset) {
    print("got asset");
    req.response.headers.contentType =
        ContentTypes.forExtension(path.extension(asset.id.path));
    return asset.read().pipe(req.response);
  })
  .then((_) => req.response.close())
  .catchError((e, s) {
    print("error: $e");
    send404(req);
  });
};

class PathTransformer extends Transformer {

  final String assetPathPrefix;
  final String packageName;
  final List<String> entryPoints;

  PathTransformer(this.assetPathPrefix, this.packageName, this.entryPoints);

  bool _isEntryPoint(Asset input) => (input.id.package == packageName)
      && (entryPoints.contains(input.id.path));

  Future<bool> isPrimary(Asset input) => new Future.value(_isEntryPoint(input));

  Future apply(Transform transform) {
    var asset = transform.primaryInput;
    if (_isEntryPoint(asset)) {
      return asset.readAsString().then((content) {
        var doc = _parseHtml(content, asset.id.path);
        visitNodes(Node node) {
          if (node.attributes.containsKey('path-attr')) {
            var attrName = node.attributes['path-attr'];
            var originalPath = node.attributes[attrName];
            var newPath = path.join(assetPathPrefix, originalPath);
            node.attributes[attrName] = newPath;
            node.attributes.remove('path-attr');
          }
          for (var child in node.children) {
            visitNodes(child);
          }
        }
        visitNodes(doc);
        transform.addOutput(new Asset.fromString(asset.id, doc.outerHtml));
      });
    }
    return new Future.value();
  }

}

Document _parseHtml(String contents, String sourcePath) {
  var parser = new HtmlParser(contents, encoding: 'utf8', generateSpans: true,
      sourceUrl: sourcePath);
  return parser.parse();
}
