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
import 'dart:collection';
import 'dart:html' as html;

import 'package:logging/logging.dart';
import 'package:observe/observe.dart';
import 'package:uri_template/uri_template.dart';

part 'src/client/route.dart';
part 'src/client/router.dart';

final _logger = new Logger('route');

typedef void RouteEventHandler(RouteEvent path);

/**
 * Route enter or leave event.
 */
class RouteEvent {
  final Route route;
  final Uri uri;
  final Map parameters;
  final _allowNavigationFutures = <Future<bool>>[];

  RouteEvent._(this.route, this.uri, this.parameters);

  /**
   * Can be called on leave with the future which will complete with a boolean
   * value allowing (true) or disallowing (false) the current navigation.
   */
  void allowNavigation(Future<bool> allow) {
    _allowNavigationFutures.add(allow);
  }

//  void redirect(String routeName, {Map<String, String> parameters}) {
//    route.navigate(routeName, parameters);
//  }
}
