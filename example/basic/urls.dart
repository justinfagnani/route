// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library example.urls;

import 'package:uri/uri.dart';

final one = uri('/one');
final two = uri('/two');
final home = '/';

UriParser uri(String s) => new UriParser(new UriTemplate(s));
