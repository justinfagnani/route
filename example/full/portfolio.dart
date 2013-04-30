library portfolio;

import 'package:web_ui/web_ui.dart';
import 'package:web_ui/watcher.dart' as watchers;
import 'dart:html';
import 'dart:async';
import 'package:route/client.dart';

class PortfolioComponent extends WebComponent implements Routable {
  var expandedCompany;
  var expanded;
  var tabs = [{
    'name': 'Porfolio'
  }];
  var activeTab;
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

  }

  inserted() {
    chopin.onTokenChange(this, (newToken) {
      if (newToken == null) {
        newToken = '';
      }
      var tokenInt = int.parse(newToken, onError: (s) => -1);
      if (newToken == '' || newToken == 'home' || tokenInt == -1) {
        showTab(tabs[0], null, updateUrl: true, replace: true, silent: true);
        return;
      }
      bool done = false;
      tabs.forEach((tab) {
        if (!done && tab['userValue'] != null && tab['userValue']['id'] == tokenInt) {
          showTab(tab, null, updateUrl: false, silent: true, setToken: false);
          done = true;
        }
      });
      if (done) return;
      companies.forEach((c) {
        if (c['id'] == tokenInt) {
          openCompany(c, null, setToken: false);
          done = true;
        }
      });
    });
  }

  void expandCompany(company, MouseEvent e) {
    if (expanded == company['id']) {
      expanded = null;
    } else {
      expanded = company['id'];
    }
    e.preventDefault();
    watchers.dispatch();
  }

  bool isExpanded(company) {
    return expanded == company['id'];
  }

  void openCompany(company, MouseEvent e, {setToken: true}) {
    if (e != null) {
      e.preventDefault();
    }

    tabs.add({
      'name': company['name'],
      'userValue': company
    });
    activeTab = tabs[tabs.length - 1];
    watchers.dispatch();

    if (setToken) {
      // set new history token...
      chopin.setToken(this, "${company['id']}", silent: false);
    }
  }

  String activeClass(tab) {
    if (tab == activeTab) {
      return "active";
    }
    return "";
  }

  showTab(tab, e, {updateUrl: true, replace: false, silent: false, setToken: true}) {
    if (e != null) {
      e.preventDefault();
    }
    activeTab = tab;
    watchers.dispatch();

    if (setToken) {
      var tkn = activeTab['userValue'] != null ? "${activeTab['userValue']['id']}" : "home";
      chopin.setToken(this, tkn, silent: silent, updateUrl: updateUrl, replace: replace);
    }
  }
}