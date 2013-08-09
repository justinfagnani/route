library route.mdv.switcher;

import 'dart:html';
import 'package:custom_element/custom_element.dart';
import 'package:mdv/mdv.dart' as mdv;

class Switcher extends CustomElement {
  void created() {
    print("Switcher.created");
  }

  void inserted() {
    print("Switcher.inserted");
  }

  bind(String name, model, String path) {
    print("Switcher.bind($name, $model, $path)");
    if (name == 'select-on') {
      return new SelectBinding(this, name, model, path);
    } else {
      return super.bind(name, model, path);
    }
  }

  void selectChild(selectCase) {
    var content = this.children;
    for (var node in this.children) {
      node.classes.toggle('selected', node.attributes['select-case'] == selectCase);
    }
  }
}

class SelectBinding extends mdv.NodeBinding {
  SelectBinding(node, name, model, path)
      : super(node, name, model, path);

  void boundValueChanged(newValue) {
    print("SelectBinding newValue: $newValue");
    (node as Switcher).selectChild(newValue);
  }
}