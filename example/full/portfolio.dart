library portfolio;

import 'dart:html';

import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';

import 'index.dart';
import 'data.dart' as data;


class PortfolioComponent extends WebComponent {
  RouteHandle route;
  RouteHandle companyRoute;
  @observable var tabs = toObservable([]);
  @observable var activeTab;
  @observable var companies;

  created() {
    data.fetchCompanies().then((result) => companies = result);
  }

  inserted() {
    tabs.add({
      'name': 'Portfolio',
      'link': router.url('list', startingFrom: route)
    });

    companyRoute = route.getRoute('company');
    route.getRoute('list').onRoute.listen((RouteEvent e) {
      activeTab = tabs[0];
      if (e.path != '/list') {
        router.go('list', {}, startingFrom: route, replace: true);
      }
    });
    companyRoute.onRoute.listen(showCompanyTab);
  }

  removed() {
    route.discart();
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
        newTab['link'] = companyLink(company);
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

  String companyLink(company) {
    return router.url('company',
        parameters: {'tabId': '${company['id']}'}, startingFrom: route);
  }

  String activeClass(tab) {
    if (tab == activeTab) {
      return "active";
    }
    return "";
  }
}