part of route.client;

/**
 * Route enter or leave event.
 */
class RouteEvent {
  final bool isEnter;
  final Uri uri;
  final Map<String, String> parameters;

  var _futures = <Future<bool>>[];

  _RouteEvent(this.isEnter, this.path, this.parameters);

  bool get isLeave => !isEnter;

  /**
   * Can be called on leave with the future which will complete with a boolean
   * value allowing (true) or disallowing (false) the current navigation.
   */
  void allowNavigation(Future<bool> allow) {
    _futures.add(allow);
  }

}
