library portfolio;

import 'dart:html';

import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';

import 'index.dart';
import 'data.dart' as data;
import 'stream-cleaner.dart';

class PortfolioComponent extends WebComponent {
  Route route;
  Route companyRoute;
  @observable var tabs = toObservable([{
    'name': 'Portfolio'
  }]);
  @observable var activeTab;
  @observable var companies;

  StreamCleaner cleaner = new StreamCleaner();

  created() {
    data.fetchCompanies().then((result) => companies = result);
  }

  inserted() {
    companyRoute = route.getRoute('company');
    cleaner.add(route.getRoute('home').onRoute.listen((RouteEvent e) {
      activeTab = tabs[0];
      if (e.path != '/home') {
        navigateToTab(tabs[0], null, replace: true);
      }
    }));
    cleaner.add(companyRoute.onRoute.listen(showCompanyTab));
  }

  removed() {
    cleaner.cancelAll();
  }

  navigateToTab(tab, e, {replace: false}) {
    if (e != null) {
      e.preventDefault();
    }
    if (tab['name'] == 'Portfolio') {
      router.go('home', {}, startingFrom: route, replace: replace);
    } else {
      router.go('company', {'tabId': tab['userValue']['id']}, startingFrom: route);
    }
  }

  void showCompanyTab(RouteEvent e) {
    var tokenInt = int.parse(e.parameters['tabId']);

    // If it's one of the current tabs, we show that tab
    for (var tab in tabs) {
      if (tab['userValue'] != null && tab['userValue']['id'] == tokenInt) {
        activeTab = tab;
        return;
      }
    }

    // Otherwise we try to load the company
    var newTab = toObservable({
      'name': 'Loading...',
    });
    tabs.add(newTab);
    activeTab = tabs[tabs.length - 1];
    data.fetchCompany(tokenInt).then((company) {
      if (company != null) {
        newTab['name'] = company['name'];
        newTab['userValue'] = company;
      } else {
        // TODO: show a message that company id is invalid or something
      }
    });
  }

  void openCompany(company, MouseEvent e) {
    if (e != null) {
      e.preventDefault();
    }
    // set new history token...
    router.go('company', {
      'tabId': '${company['id']}'
    }, startingFrom: route);
  }

  String activeClass(tab) {
    if (tab == activeTab) {
      return "active";
    }
    return "";
  }
}