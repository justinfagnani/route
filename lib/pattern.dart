// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Pattern utilities for use with server.Router.
 *
 * Example:
 *
 *     var router = new Router(server);
 *     router.filter(matchesAny(new UrlPattern(r'/(\w+)'),
 *         exclude: [new UrlPattern('/login')]), authFilter);
 */
library pattern;

class _MultiPattern extends Pattern {
  final Iterable<Pattern> include;
  final Iterable<Pattern> exclude;

  _MultiPattern(this.include, {this.exclude});

  Iterable<Match> allMatches(String str) {
    var _allMatches = [];
    for (var pattern in include) {
      var matches = pattern.allMatches(str);
      if (matches.isNotEmpty) {
        if (exclude != null) {
          for (var excludePattern in exclude) {
            if (excludePattern.allMatches(str).isNotEmpty) return [];
          }
        }
        _allMatches.addAll(matches);
      }
    }
    return _allMatches;
  }

  Match matchAsPrefix(String str, [int start = 0]) {
    return allMatches(str).firstWhere((match) => match.start == start,
        orElse: () => null);
  }
}

/**
 * Returns a [Pattern] that matches against every pattern in [include] and
 * returns all the matches. If the input string matches against any pattern in
 * [exclude] no matches are returned.
 */
Pattern matchAny(Iterable<Pattern> include, {Iterable<Pattern> exclude}) =>
    new _MultiPattern(include, exclude: exclude);

/**
 * Returns true if [pattern] has a single match in [str] that matches the whole
 * string, not a substring.
 */
bool matchesFull(Pattern pattern, String str) {
  var matches = pattern.allMatches(str);
  if (matches.length != 1) return false;
  var match = matches.elementAt(0);
  return match.start == 0 && match.end == str.length;
}