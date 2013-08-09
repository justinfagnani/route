library route.urils;

Object firstWhere(Iterable i, bool predicate(e)) {
  var matching = i.where(predicate);
  return matching.isEmpty ? null : matching.first;
}

bool mapsEqual(Map a, Map b) =>
    a.keys.length == b.keys.length &&
    a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);

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
