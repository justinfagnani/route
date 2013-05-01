library routable_component;

import 'package:route/client.dart';
import 'package:web_ui/web_ui.dart';

// This is workaround for https://github.com/dart-lang/web-ui/issues/459
class RoutableWebComponent extends WebComponent implements Routable {}