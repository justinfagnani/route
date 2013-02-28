// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pattern;

class _MultiPattern extends Pattern {
  final Iterable<Pattern> include;
  final Iterable<Pattern> exclude;

  _MultiPattern(Iterable<Pattern> this.include,
      {Iterable<Pattern> this.exclude});

  Iterable<Match> allMatches(String str) {
    for (var pattern in include) {
      var matches = pattern.allMatches(str);
      if (_hasMatch(matches)) {
        if (exclude != null) {
          for (var excludePattern in exclude) {
            if (_hasMatch(excludePattern.allMatches(str))) {
              return [];
            }
          }
        }
        return matches;
      }
    }
    return [];
  }
}

Pattern matchAny(Iterable<Pattern> include, {Iterable<Pattern> exclude}) =>
    new _MultiPattern(include, exclude: exclude);

bool matchesFull(Pattern pattern, String str) {
  var iter = pattern.allMatches(str).iterator;
  if (iter.moveNext()) {
    var match = iter.current;
    return (match.start == 0) && (match.end == str.length)
        && (!iter.moveNext());
  }
  return false;
}

bool _hasMatch(Iterable<Match> matches) => matches.iterator.moveNext();