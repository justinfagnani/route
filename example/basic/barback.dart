library route.example.basic.barback;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/dom.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/io.dart' as quiver;
import 'package:quiver/iterables.dart' as quiver;

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
    var assetPath = id.path.startsWith('lib') ? id.path
        : path.join('web', id.path);
    var fullPath = path.join(packagePath, assetPath);
    return new Future.value(new Asset.fromPath(id, fullPath));
  }
}

Future<List<AssetId>> _getLibAssets() =>
  new Directory('packages').list(recursive: true)
    .where((e) => e is File)
    .map((e) {
      var parts = path.split(e.path);
      var package = parts[1];
      var assetPath = path.joinAll(['lib']..addAll(parts.sublist(2)));
      return new AssetId(package, assetPath);
    })
    .toList();

Future<List<AssetId>> _getWebAssets(String packageName) {
  var assets = [];
  return quiver.visitDirectory(new Directory('web'), (e) {
    if (e is File) assets.add(new AssetId(packageName, path.joinAll(path.split(e.path).sublist(1))));
    return new Future.value(!e.path.endsWith('packages'));
  }).then((_) => assets);
}

Future<List<String>> _getPackages() =>
    new Directory(_packagesDir).list(followLinks: false)
        .map((e) => e.path.substring(_packagesDir.length))
        .toList();

Future<Barback> initBarback(String packageName, List<List<Transformer>> phases) {

  return _PackageProvider.create()
    .then((provider) => Future.wait([_getLibAssets(), _getWebAssets(packageName)])
    .then((r) {
      var barback = new Barback(provider);
      var assets = quiver.concat(r);
      barback.updateSources(assets);

      return _getPackages().then((packages) {
        for (var package in packages) {
          barback.updateTransformers(package, phases);
        }
        return barback;
      });
  }));
}

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
