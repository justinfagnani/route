part of route.client;

typedef void RouteEventHandler(RouteEvent path);

/**
 * Route enter or leave event.
 */
class RouteEvent {
  /// The route that fired this RouteEvent
  final Route route;

  /// True if the event is an exit event
  final bool isExit;

  /// For an enter event, the new URI that is being navigated to
  final Uri uri;

  /// The parameters extracted from parsing the URI with the route's template
  final Map<String, String> parameters;

  var _allowNavigationFutures = <Future<bool>>[];

  RouteEvent(this.route, this.uri, this.parameters, {bool this.isExit: false});

  /// True if the event is an enter event
  bool get isEnter => !isExit;

  /**
   * Allows or denies navigation based on the completed value of [allow]
   */
  void allowNavigation(Future<bool> allow) {
    _allowNavigationFutures.add(allow);
  }

  /**
   * Returns a Future that completes with true if all Futures passed to
   * [allowNavigation] complete to true, otherwise completes to false.
   */
  Future<bool> checkNavigationAllowed() {
    if (_allowNavigationFutures.isEmpty) {
      return new Future.value(true);
    } else {
      return Future.wait(_allowNavigationFutures)
          .then((results) => results.every((allow) => allow == true));
    }
  }

  String toString() => 'RouteEvent route: $route, uri: $uri, isExit: $isExit,'
      'parameters: $parameters';
}
