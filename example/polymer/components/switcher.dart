library switcher;

import 'package:polymer/polymer.dart';

@CustomTag('r-switcher')
class Switcher extends PolymerElement {
  static int __seq = 0;
  final _seq = __seq++;

  var _selectOn;
  get selectOn => _selectOn;
  void set selectOn(s) {
    _selectOn = notifyPropertyChange(#selectOn, _selectOn, s);
    selectChild(_selectOn);
  }

  Switcher.created() : super.created() {
    print("Switcher.created() $_seq");
  }

  ready() {
    print("Switcher.ready()");
  }

  enteredView() {
    print("Switcher.enteredView");
  }

  void selectChild(select) {
    print("selectChild: $select");
    try {
      throw null;
    } catch (e, s) {
      print(s);
    }
    for (var c in this.children) {
      c.classes.toggle('selected', c.attributes['select-case'] == select);
    }
  }

}
