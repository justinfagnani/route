// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A client-side routing library for Dart.
 *
 *
 */
library route.client;

import 'dart:async';
import 'dart:html' as html;
import 'dart:collection' show LinkedHashMap;

import 'package:logging/logging.dart';
import 'package:observe/observe.dart';
import 'package:quiver/core.dart' show firstNonNull;
import 'package:uri/uri.dart';

import 'src/client/utils.dart';

part 'src/client/navigation_event.dart';
part 'src/client/route.dart';
part 'src/client/route_event.dart';
part 'src/client/router.dart';

final _logger = new Logger('route.client');
