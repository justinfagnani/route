library companyinfo;

import 'package:web_ui/web_ui.dart';
import 'routable-component.dart';
import 'dart:html';
import 'package:web_ui/watcher.dart' as watchers;
import 'package:route/client.dart';

class CompanyInfoComponent extends RoutableWebComponent {

  var company;
  Router router;
  @observable String section;
  @observable String infoUrl;
  @observable String activitiesUrl;
  @observable String notesUrl;

  void configureRouter(Router router) {
    print('CompanyInfoComponent configure router');
    this.router = router
      ..addRoute(
          name: 'info',
          defaultRoute: true,
          path: '/info',
          enter: (_) => showSection('info'))
      ..addRoute(
          name: 'activities',
          path: '/activities',
          enter: (_) => showSection('activities'))
      ..addRoute(
          name: 'notes',
          path: '/notes',
          enter: (_) => showSection('notes'));

    router.onRoute.listen((_) {
      infoUrl = router.url('info');
      activitiesUrl = router.url('activities');
      notesUrl = router.url('notes');
    });
  }

  showSection(section) {
    print('show section $section');
    this.section = section;
  }

  gotoSection(section, e) {
    if (e != null) {
      e.preventDefault();
    }
    router.go(section, {}).then((allowed) {
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