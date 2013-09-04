import 'package:polymer/polymer.dart';
import 'package:mdv/mdv.dart' as mdv;

import 'dart:html';

@CustomTag('r-tab-panel')
class TabPanel extends PolymerElement with ChangeNotifierMixin {
  String _selectedTab;

  String get selectedTab => _selectedTab;

  void set selectedTab(String name) {
    print("set selectedTab: $name");
    int selectedIndex;
    var i = 0;
    for (var c in this.query('r-tabs').children) {
      c.classes.toggle('selected', c.attributes['name'] == name);
      if (c.attributes['name'] == name) selectedIndex = i;
      i++;
    }
    i = 0;
    for (var c in this.query('r-tab-panels').children) {
      c.classes.toggle('selected', i++ == selectedIndex);
    }
    _selectedTab = notifyPropertyChange(const Symbol('selectedTab'),
        _selectedTab, name);
  }

  createBinding(String name, model, String path) {
    print("TabPanel createBinding($name, $model, $path)");
    if (name == 'selected-tab') {
      return new _SelectedTabBinding(this, model, path);
    } else {
      return super.createBinding(name, model, path);
    }
  }

  inserted() {
    var tab = this.query('r-tabs').children.first;
//    selectedTab = tab.attributes['name'];
  }

  clicked(event, detail, Element target) {
    if (event.target.tagName == 'R-TAB') {
      selectedTab = event.target.attributes['name'];
    }
  }
}

class _SelectedTabBinding extends mdv.NodeBinding {
  _SelectedTabBinding(node, model, path)
      : super(node, 'selectedTab', model, path) {
    (node as TabPanel).changes.listen((changes) {
      changes.forEach((PropertyChangeRecord c) {
        if (c.changes(const Symbol('selectedTab'))) {
          value = node.selectedTab;
        }
      });
    });
  }

  void boundValueChanged(newValue) {
    print("boundValueChanged: $newValue");
    (node as TabPanel).selectedTab = newValue;
  }
}
