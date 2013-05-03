library companyinfo;

import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';
import 'home.dart';
import 'company-info-loader.dart';
import 'portfolio.dart';

class RootView extends WebComponent {
  Route route;
  WebComponent currentComponent;

  inserted() {
    var homeRoute = route.getRoute('home')
      ..onRoute.listen((_) {
          var home = new HomeComponent();
          createAndInsertComponent(home);
        })
      ..onLeave.listen(cleanup);
    var companyInfoRoute = route.getRoute('companyInfo');
    companyInfoRoute
      ..onRoute.listen((_) {
        var comp = new CompanyInfoLoaderComponent();
        comp.route = companyInfoRoute;
        createAndInsertComponent(comp);
      })
      ..onLeave.listen(cleanup);
    var portfolioRoute = route.getRoute('portfolio');
    portfolioRoute
      ..onRoute.listen((_) {
        var comp = new PortfolioComponent();
        comp.route = portfolioRoute;
        createAndInsertComponent(comp);
      })
      ..onLeave.listen(cleanup);
  }

  void cleanup(_) {
    if (currentComponent != null) {
      var lifecycleCaller = new ComponentItem(currentComponent);
      currentComponent.host.remove();
      lifecycleCaller.remove();
      currentComponent = null;
    }
  }

  createAndInsertComponent(WebComponent comp) {
    comp.host = new DivElement();
    currentComponent = comp;
    var lifecycleCaller = new ComponentItem(comp);
    lifecycleCaller.create();
    host.children.add(comp.host);
    lifecycleCaller.insert();
    return comp;
  }
}