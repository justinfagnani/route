// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library provides a simple API for routing HttpRequests based on thier
 * URL.
 */
library route.server;

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:quiver/async.dart' show doWhileAsync;
import 'package:uri/uri.dart';

import 'src/server/request_matcher.dart';
export 'src/server/request_matcher.dart' show RequestMatcher, matchAny;

final Logger _logger = new Logger('route.server');

typedef Future<bool> RequestFilter(HttpRequest request);

/**
 * A request router that makes it easier to handle [HttpRequest]s from an
 * [HttpServer].
 *
 * [serve] creates a new [Stream] of requests whose paths match against the
 * given pattern. Matching requests are not sent to any other streams created by
 * a server() call.
 *
 * [filter] registers a [Filter] function to run against matching requests. On
 * each request the filters that match are run in order, waiting for each to
 * complete since filters return a Future. If any filter completes false, the
 * subsequent filters and request handlers are not run. This way a filter can
 * prevent further processing, like needed for authentication.
 *
 * Requests not matched by a call to [serve] are sent to the [defaultStream].
 * If there's no subscriber to the defaultStream then a 404 is sent to the
 * response.
 *
 * Example:
 *     import 'package:route/server.dart';
 *     import 'package:route/pattern.dart';
 *
 *     HttpServer.bind().then((server) {
 *       var router = new Router(server);
 *       router.filter(matchesAny(['/foo', '/bar']), authFilter);
 *       router.serve('/foo').listen(fooHandler);
 *       router.serve('/bar').listen(barHandler);
 *       router.defaultStream.listen(send404);
 *     });
 */
class Router {
  final Stream<HttpRequest> _incoming;

  final List<_Route> _routes = <_Route>[];

  final List<_Filter> _filters = <_Filter>[];

  final StreamController<HttpRequest> _defaultController =
      new StreamController<HttpRequest>();

  /**
   * Create a new Router that listens to the [incoming] stream, usually an
   * instance of [HttpServer].
   */
  Router(Stream<HttpRequest> incoming) : _incoming = incoming {
    _incoming.listen(_handleRequest);
  }

  /**
   * Request whose URI matches [matcher] and [method] (if provided) are sent to
   * the stream created by this method, and not sent to any other router
   * streams.
   *
   * [matcher] must either be a [Pattern], [UriPattern] or [RequestMatcher]. If
   * [matcher] is a [Pattern] such as a [String] or [RegExp], incoming requests
   * are matched by their URIs path, and [method] if given. If [matcher] is a
   * [UriPattern] incoming requests are matched by their URI using
   * [UriPattern.matches]. If [matcher] is a [RequestMatcher] it is invoked on
   * incoming requests.
   */
  Stream<HttpRequest> serve(dynamic matcher, {String method}) {
    var controller = new StreamController<HttpRequest>();
    _routes.add(new _Route(controller, wrapMatcher(matcher, method: method)));
    return controller.stream;
  }

  /**
   * A [Filter] returns a [Future<bool>] that tells the router whether to apply
   * the remaining filters and send requests to the streams created by [serve].
   *
   * If the filter returns true, the request is passed to the next filter, and
   * then to the first matching server stream. If the filter returns false, it's
   * assumed that the filter is handling the request and it's not forwarded.
   */
  void filter(dynamic matcher, RequestFilter filter) {
    _filters.add(new _Filter(wrapMatcher(matcher), filter));
  }

  Stream<HttpRequest> get defaultStream => _defaultController.stream;

  void _handleRequest(HttpRequest req) {
    bool _continue = true;
    doWhileAsync(_filters, (_Filter filter) {
      var matches = filter.matches(req)
        ? filter.filter(req).then((c) => _continue = c)
        : new Future.value(true);
      _logger.fine("filter $filter $matches");
      return matches;
    })
    .then((_) {
      if (_continue) {
        bool handled = false;
        var route = _routes.firstWhere((r) => r.matches(req),
            orElse: () => null);
        if (route != null) {
          route.controller.add(req);
        } else {
          if (_defaultController.hasListener) {
            _defaultController.add(req);
          } else {
            send404(req);
          }
        }
      }
    });
  }
}

void send404(HttpRequest req) {
  req.response.statusCode = HttpStatus.NOT_FOUND;
  req.response.write("Not Found");
  req.response.close();
}

class _Filter {
  final RequestMatcher matcher;
  final RequestFilter filter;

  _Filter(this.matcher, this.filter);

  bool matches(HttpRequest request) => matcher(request);
}

class _Route {
  final RequestMatcher matcher;
  final StreamController controller;

  _Route(this.controller, this.matcher);

  bool matches(HttpRequest request) => matcher(request);
}
