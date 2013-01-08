// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.url_pattern;

// From the PatternCharacter rule here:
// http://ecma-international.org/ecma-262/5.1/#sec-15.10
// removed '( and ')' since we'll never escape them when not in a group
final _specialChars = new RegExp(r'[\\\^\$\.\|\+\[\]\{\}]');

UrlPattern urlPattern(String p) => new UrlPattern(p);

/**
 * A pattern, similar to a [RegExp] that is designed to match against URL paths,
 * easily return groups of a matchand path, and produce URLs path from a list of
 * values.
 *
 * The differences from a plain [RegExp]:
 *  * There can only be one match, and it must match the entire string. `^` and
 *    `$` are automatically added to the pattern.
 *  * The pattern must be un-ambiguous, eg `(.*)(.*)` is not allowed. (TODO)
 *  * The pattern must be reversible, that is it must be possible to reconstruct
 *    a String that matches the pattern given a list of values. This means we
 *    further deviate from plain [RegExp]s by:
 *  * All non-literals must be in a group. This is so that the values used to
 *    reverse the match can be substituted for the top-level groups.
 *  * All characters not in a group are considered literals, so characters with
 *    special meaning to [RexExp]s are escaped. (TODO)
 *
 * With those differences, `UrlPatterns` become much more useful for routing
 * URLs and constructing them, both on the client and server. The best practice
 * is to define your application's set of URLs in a shared library.
 *
 * urls.dart:
 *
 *    library urls;
 *
 *    final ARTICLE_URL = new UrlPattern(r'/articles/(\d+)');
 *
 * server.dart:
 *
 *    import 'urls.dart';
 *    import 'package:route/server.dart';
 *
 *    main() {
 *      var server = new HttpServer();
 *      server.addRequestHandler(matchesUrl(ARTICLE_URL), serveArticle);
 *    }
 *
 *    serveArcticle(req, res) {
 *      var articleId = ARTICLE_URL.parse(req.path)[0];
 *      // ...
 *    }
 */
class UrlPattern implements Pattern {
  final String _pattern;
  final RegExp regex;

  UrlPattern(String pattern)
    :  _pattern = pattern,
      regex = new RegExp('^$pattern\$');

  String reverse(Iterable args) {
    var sb = new StringBuffer();
    var chars = _pattern.splitChars();
    var argsIter = args.iterator();

    int groupCount = 0;
    int depth = 0;
    int groupStart = 0;
    int groupEnd = -1;

    for (int i = 0; i < chars.length; i++) {
      var c = chars[i];
      if (c == '(') {
        if (depth == 0) groupStart = i;
        depth++;
        // append everything form the last groupEnd
        var part = _pattern.substring(groupEnd + 1, groupStart);
        sb.add(part);
      } else if (c == ')') {
        if (depth == 0) throw new ArgumentError('unmatched parentheses');
        depth--;
        if (depth == 0) {
          groupEnd = i;
          // append the nth arg
          if (argsIter.hasNext) {
            sb.add(argsIter.next().toString());
          } else {
            throw new ArgumentError('more groups than args');
          }
        }
      }
    }
    if (depth > 0) {
      throw new ArgumentError('unclosed group');
    }
    if (groupEnd + 1 < chars.length) {
      sb.add(_pattern.substring(groupEnd + 1, chars.length));
    }
    return sb.toString();
  }

  List<String> parse(String path) {
    var match = regex.firstMatch(path);
    var result = <String>[];
    for (int i = 1; i <= match.groupCount; i++) {
      result.add(match[i]);
    }
    return result;
  }

  bool matches(String str) {
    var iter = regex.allMatches(str).iterator();
    if (iter.hasNext) {
      var match = iter.next();
      return (match.start == 0) && (match.end == str.length) && (!iter.hasNext);
    }
    return false;
  }

  Iterable<Match> allMatches(String str) {
    return regex.allMatches(str);
  }

  bool operator ==(other) =>
      (other is UrlPattern) && (other._pattern == _pattern);

  int get hashCode => _pattern.hashCode;

  String toString() => _pattern.toString();
}
