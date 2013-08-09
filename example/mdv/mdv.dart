library example;

import 'dart:async';
import 'dart:html';

import 'package:custom_element/custom_element.dart';
import 'package:fancy_syntax/syntax.dart';
import 'package:logging/logging.dart';
import 'package:mdv/mdv.dart' as mdv;
import 'package:observe/observe.dart';
import 'package:route/client.dart';

import 'switcher.dart';

class App extends ChangeNotifierBase {
  String _section;
  String get section => _section;
  void set section(s) {
    _section = notifyPropertyChange(const Symbol('section'), _section, s);
  }

  int _countdown;
  int get countdown => _countdown;
  void set countdown(c) {
    _countdown = notifyPropertyChange(const Symbol('countdown'), _countdown, c);
  }

  Router _router;
  Router get router => _router;

  App() {
    _router = new Router({
      'one': route('/one')
          ..onEnter.listen((e) => section = 'one'),
      'two': route('/two')
          ..onEnter.listen((e) => section = 'two')
          ..onExit.listen(hideTwo),
      'catchAll': route('/{a}')
          ..onEnter.listen((e) => e.route.parent.navigate('one')),
    }, index: 'one');
  }

  void hideTwo(RouteEvent e) {
    var completer = new Completer<bool>();
    countdown = 5;
    new Timer.periodic(new Duration(seconds: 1), (t) {
      if (--countdown <= 0) {
        t.cancel();
        completer.complete(true);
      }
    });
    e.allowNavigation(completer.future);
  }
}

var app = new App()..section = 'one';

main() {
  new Logger('')
    ..level = Level.FINEST
    ..onRecord.listen((r) => print('[${r.level}] ${r.message}'));

  mdv.initialize();
  registerCustomElement('fs-switcher', () => new Switcher());

  query('#main')
    ..bindingDelegate = new FancySyntax()
    ..model = app;
  app.router.listen();
}
