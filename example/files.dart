// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library example.files;

import 'dart:async';
import 'dart:io';
import 'package:route/server.dart';
import 'package:path/path.dart' as path;

class ContentTypes {
  static final ContentType CSS =
      ContentType.parse("text/css");
  static final ContentType DART =
      ContentType.parse("application/dart");
  static final ContentType HTML =
      ContentType.parse("text/html; charset=UTF-8");
  static final ContentType JAVASCRIPT =
      ContentType.parse("application/javascript");
  static final ContentType JPEG =
      ContentType.parse("image/jpeg");
  static final ContentType JSON =
      ContentType.parse("application/json");
  static final ContentType TEXT =
      ContentType.parse("text/plain");

  static final Map<String, ContentType> _extensions = {
    'css': CSS,
    'dart': DART,
    'html': HTML,
    'jpg': JPEG,
    'js': JAVASCRIPT,
    'json': JSON,
    'txt': TEXT,
  };

  static ContentType addTypeForExtension(String extension, ContentType type) =>
      _extensions[extension] = type;

  static ContentType forExtension(String extension) => _extensions[extension];

  static ContentType forFile(File file) =>
      _extensions[path.extension(file.path)];
}

/**
 * Loads a file and sends it's contents to [request.response].
 */
typedef void FileHandler(HttpRequest request, String path);

/**
 * Returns a request handler that serves the local file that's located at
 * [path].
 *
 * [fileHandler] allows special file handling, like loading from a database or
 * setting custom headers.
 *
 * Example usage:
 *
 *     router.serve('/').listen(serveFile('web/index.html');
 */
Function serveFile(String path, {FileHandler fileHandler: sendFile}) =>
  (HttpRequest req) => fileHandler(req, path);

/**
 * Returns a request handler that serves local files from a directory located at
 * [path]. The request path has the prefix [as] removed and the remaining path
 * is used to find the file in the directory, allowing remapping a URL prefix
 * into the filesystem. If [as] is not specified, [path] is used as the prefix.
 *
 * Requests passed to the handler must have paths that start with [as] or an
 * error will be thrown.
 *
 * [fileHandler] allows special file handling, like loading from a database or
 * setting custom headers.
 *
 * Example usage:
 *
 *     router.serve(glob(webDir)).listen(serveDirectory('web', as: webDir);
 */
Function serveDirectory(String dirPath, {String as,
    FileHandler fileHandler: sendFile}) {
  var prefix = (as == null) ? dirPath : as;

  return (HttpRequest req) {
    var reqPath = req.uri.path;
    var relativePath = path.relative(reqPath, from: prefix);
    var filePath = path.join(dirPath, relativePath);

    // don't serve hidden files or allow ../ shenanigans
    if (filePath.startsWith('.') ||
        reqPath.toString().contains('..')) {
      send404(req);
      return;
    }

    fileHandler(req, filePath.toString());
  };
}

void sendFile(HttpRequest req, String path) {
  var response = req.response;
  File file = new File(path);
  file.exists().then((bool exists) {
    if (exists) {
      Future.wait([file.length(), file.lastModified()]).then((args) {
        int length = args[0];
        DateTime lastModified = args[1];
        response
          ..statusCode = 200
          ..headers.contentType = ContentTypes.forFile(file)
          ..headers.contentLength = length
          ..headers.add(HttpHeaders.LAST_MODIFIED, lastModified);
        file.openRead().pipe(req.response).then((_) => response.close());
      });
    } else {
      send404(req);
    }
  });
}
