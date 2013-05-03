library companyinfo;

import 'dart:html';

import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';

import 'index.dart';
import 'stream-cleaner.dart';


class CompanyInfoComponent extends WebComponent {
  var company;
  Route route;
  @observable String section;
  @observable String infoUrl;
  @observable String activitiesUrl;
  @observable String notesUrl;

  StreamCleaner cleaner = new StreamCleaner();

  inserted() {
    cleaner.add(route.getRoute('info').onRoute.listen((_) => showSection('info')));
    cleaner.add(route.getRoute('activities').onRoute.listen((_) => showSection('activities')));
    cleaner.add(route.getRoute('notes').onRoute.listen((_) => showSection('notes')));

    infoUrl = router.url('info', startingFrom: route);
    activitiesUrl = router.url('activities', startingFrom: route);
    notesUrl = router.url('notes', startingFrom: route);
  }

  removed() {
    cleaner.cancelAll();
  }

  showSection(section) {
    this.section = section;
  }

  gotoSection(section, e) {
    if (e != null) {
      e.preventDefault();
    }
    router.go(section, {}, startingFrom: route).then((allowed) {
      if (allowed) {
        showSection(section);
        watchers.dispatch();
      }
    });
  }

  String activeClass(sect) {
    if (sect == section) {
      return "active";
    }
    return "";
  }
}