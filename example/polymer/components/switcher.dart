import 'package:polymer/polymer.dart';

@CustomTag('r-switcher')
class Switcher extends PolymerElement with ChangeNotifierMixin {
  var _selectOn;
  get selectOn => _selectOn;
  void set selectOn(s) {
    _selectOn = notifyPropertyChange(const Symbol('selectOn'), _selectOn, s);
    selectChild(_selectOn);
  }

  void selectChild(select) {
    print("selectChild: $select");
    for (var c in this.children) {
      c.classes.toggle('selected', c.attributes['select-case'] == select);
    }
  }
}
