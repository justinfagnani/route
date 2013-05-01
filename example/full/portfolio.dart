library portfolio;

import 'dart:async';
import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';
import 'routable-component.dart';

class PortfolioComponent extends RoutableWebComponent {
  var router;
  @observable var tabs = toObservable([{
    'name': 'Porfolio'
  }]);
  @observable var activeTab;
  var companies = [
    {
      'id': 100001,
      'name': 'Company 100001',
      'revenue': 3000000.00
    },
    {
      'id': 1111111,
      'name': 'Company 1111111',
      'revenue': 1001100.00
    },
    {
      'id': 100003,
      'name': 'Mom & Pop Shop',
      'revenue': 401000.00
    }
  ];

  created() {
    activeTab = tabs[0];
  }

  void configureRouter(Router router) {
    this.router = router
      ..addRoute(
          name: 'home',
          path: '/home',
          defaultRoute: true,
          enter: (_) => showTab(tabs[0], null))
      ..addRoute(
          name: 'company',
          path: '/:tabId',
          enter: showCompanyTab);
  }
  
  void showCompanyTab(RouteEvent e) {
    var tokenInt = int.parse(e.parameters['tabId']);
    print('showCompanyTab ${e.path} $tokenInt');
    // If it's one of the current tabs, we show that tab
    for (var tab in tabs) {
      if (tab['userValue'] != null && tab['userValue']['id'] == tokenInt) {
        showTab(tab, null);
        return;
      }
    }
    // Otherwise we try to load the company
    getCompany(tokenInt).then((company) {
      if (company != null) {
        _openCompanyTab(company);
      } else {
        // TODO: show a message that company id is invalid or something
      }
    });
  }
  
  Future getCompany(int id) {
    for (var c in companies) {
      if (c['id'] == id) {
        return new Future.value(c);
      }
    }
    return new Future.value(null);
  }

  void openCompany(company, MouseEvent e) {
    print('openCompany $company');
    if (e != null) {
      e.preventDefault();
    }
    // set new history token...
    router.go('company', {
      'tabId': '${company['id']}'
    });
  }

  void _openCompanyTab(company) {
    print('_openCompanyTab $company');
    tabs.add({
      'name': company['name'],
      'userValue': company
    });
    activeTab = tabs[tabs.length - 1];
    print('activeTab set to ${activeTab['name']}');
  }

  String activeClass(tab) {
    if (tab == activeTab) {
      return "active";
    }
    return "";
  }

  showTab(tab, e) {
    print('showTab $tab');
    if (e != null) {
      e.preventDefault();
    }
    activeTab = tab;
  }
}