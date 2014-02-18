library example;

import 'dart:async';
import 'dart:html' hide Navigator;

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:route/client.dart';
import 'package:template_binding/template_binding.dart';

@CustomTag('route-app')
class App extends PolymerElement with Navigator {
  String _section;
  String get section => _section;
  void set section(s) {
    _section = notifyPropertyChange(#section, _section, s);
  }

  int _countdown;
  int get countdown => _countdown;
  void set countdown(c) {
    _countdown = notifyPropertyChange(#countdown, _countdown, c);
  }

  final Router router;

  App.created()
      : super.created(),
      router = new Router({
        'one': route('/one'),
        'two': route('/two'),
        'catchAll': route('/')
      }, index: 'one') {

    print("App.created");

    initNavigator();

    router
      ..['one'].onEnter.listen((e) {
        print('one onEnter');
        section = 'one';
      })
      ..['two'].onEnter.listen((e) {
        print('two onEnter');
        section = 'two';
      })
      ..['two'].onExit.listen(hideTwo)
      ..['catchAll'].onEnter.listen((e) {
        print('catchAll onEnter');
        router.navigate(Uri.parse('/one'));
      });

    router.listen();
  }

  enteredView() {
    print("App.enteredView");
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

main() {
  new Logger('')
    ..level = Level.FINEST
    ..onRecord.listen((r) => print('[${r.level}] ${r.message}'));

  initPolymer();
}
