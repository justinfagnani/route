// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.utils;

Uri mergeUris(Uri base, Uri merge) {
  var path = base.path + merge.path;
  var queryParameters = new Map()
      ..addAll(base.queryParameters)
      ..addAll(merge.queryParameters);
  return new Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      port: base.port,
      path: path,
      queryParameters: queryParameters,
      fragment: base.fragment);
}

