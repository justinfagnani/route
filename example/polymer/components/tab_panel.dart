import 'package:polymer/polymer.dart';
import 'dart:html';

@CustomTag('r-tab-panel')
class TabPanel extends PolymerElement with ChangeNotifierMixin {
  int _selectedIndex = 0;

  String get selectedIndex => _selectedIndex.toString();

  void set selectedIndex(String indexString) {
    print('TabPanel set selectedIndex: $indexString');
    print('TabPanel bindings: ${this.bindings}');
    int index = int.parse(indexString, onError: (_) => 0);
    int i = 0;
    for (var c in this.query('r-tab-panels').children) {
      c.classes.toggle('selected', i++ == index);
    }
    i = 0;
    for (var c in this.query('r-tabs').children) {
      c.classes.toggle('selected', i++ == index);
    }
    print("TabPanel.hasObservers: $hasObservers");
    _selectedIndex = notifyPropertyChange(const Symbol('selectedIndex'),
        _selectedIndex, index);
  }

  inserted() {
    selectedIndex = '0';
  }

  clicked(event, detail, Element target) {
    if (event.target.tagName == 'R-TAB') {
      selectedIndex = '${this.query('r-tabs').children.indexOf(event.target)}';
    }
  }
}
