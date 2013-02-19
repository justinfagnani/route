// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.url_pattern;

// From the PatternCharacter rule here:
// http://ecma-international.org/ecma-262/5.1/#sec-15.10
// removed '( and ')' since we'll never escape them when not in a group
final _specialChars = new RegExp(r'[\^\$\.\|\+\[\]\{\}]');

UrlPattern urlPattern(String p) => new UrlPattern(p);

/**
 * A pattern, similar to a [RegExp] that is designed to match against URL paths,
 * easily return groups of a matchand path, and produce URLs path from a list of
 * values.
 *
 * The differences from a plain [RegExp]:
 *  * There can only be one match, and it must match the entire string. `^` and
 *    `$` are automatically added to the pattern.
 *  * The pattern must be reversible, that is it must be possible to reconstruct
 *    a String that matches the pattern given a list of values. This means we
 *    further deviate from plain [RegExp]s by:
 *  * The pattern must be un-ambiguous, eg `(.*)(.*)` is not allowed at the
 *    top-level.
 *  * All non-literals must be in a group. This is so that the values used to
 *    reverse the match can be substituted for the top-level groups.
 *  * All characters not in a group are considered literals, so characters with
 *    special meaning to [RexExp]s are escaped.
 *
 * With those differences, `UrlPatterns` become much more useful for routing
 * URLs and constructing them, both on the client and server. The best practice
 * is to define your application's set of URLs in a shared library.
 *
 * urls.dart:
 *
 *    library urls;
 *
 *    final articleUrl = new UrlPattern(r'/articles/(\d+)');
 *
 * server.dart:
 *
 *    import 'urls.dart';
 *    import 'package:route/server.dart';
 *
 *    main() {
 *      var server = new HttpServer();
 *      server.addRequestHandler(matchesUrl(articleUrl), serveArticle);
 *    }
 *
 *    serveArcticle(req, res) {
 *      var articleId = articleUrl.parse(req.path)[0];
 *      // ...
 *    }
 */
class UrlPattern implements Pattern {
  final String _pattern;
  final RegExp regex;

  UrlPattern(String pattern)
    :  _pattern = pattern,
      regex = _regexpFromUrlPattern(pattern);

  String reverse(Iterable args) {
    var sb = new StringBuffer();
    var chars = _pattern.split('');
    var argsIter = args.iterator;

    int depth = 0;
    int groupCount = 0;
    bool escaped = false;

    for (int i = 0; i < chars.length; i++) {
      var c = chars[i];
      if (c == '\\' && escaped == false) {
        escaped = true;
      } else {
        if (c == '(') {
          if (escaped && depth == 0) {
            sb.add(c);
          }
          if (!escaped) depth++;
        } else if (c == ')') {
          if (escaped && depth == 0) {
            sb.add(c);
          } else if (!escaped) {
            if (depth == 0) throw new ArgumentError('unmatched parentheses');
            depth--;
            if (depth == 0) {
              // append the nth arg
              if (argsIter.moveNext()) {
                sb.add(argsIter.current.toString());
              } else {
                throw new ArgumentError('more groups than args');
              }
            }
          }
        } else if (depth == 0) {
          sb.add(c);
        }
        escaped = false;
      }
    }
    if (depth > 0) {
      throw new ArgumentError('unclosed group');
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
    var iter = regex.allMatches(str).iterator;
    if (iter.moveNext()) {
      var match = iter.current;
      return (match.start == 0) && (match.end == str.length)
          && (!iter.moveNext());
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

RegExp _regexpFromUrlPattern(String pattern) {
  var sb = new StringBuffer();
  int depth = 0;
  int lastGroupEnd = -2;
  bool escaped = false;

  sb.add('^');
  var chars = pattern.split('');
  for (var i = 0; i < chars.length; i++) {
    var c = chars[i];
    if (c == '\\' && !escaped) {
      escaped = true;
      if (depth != 0) {
        sb.add(c);
      }
    } else {
      if (_specialChars.hasMatch(c) && depth == 0) {
        sb.add('\\$c');
      } else if (c == r'\' && depth == 0) {
        sb.add(r'\\');
      } else if (c == '(') {
        if (escaped && depth == 0) {
          sb.add('\\(');
        } else {
          sb.add(c);
        }
        if (!escaped) {
          if (lastGroupEnd == i - 1) {
            throw new ArgumentError('ambiguous adjecent top-level groups');
          }
          depth++;
        }
      } else if (c == ')') {
        if (escaped && depth == 0) {
          sb.add('\\)');
        } else {
          if (depth < 1) throw new ArgumentError('unmatched parenthesis');
          sb.add(c);
        }
        if (!escaped) {
          depth--;
          if (depth == 0) {
            lastGroupEnd = i;
          }
        }
      } else {
        sb.add(c);
      }
      escaped = false;
    }
  }
  sb.add(r'$');
  return new RegExp(sb.toString());
}
