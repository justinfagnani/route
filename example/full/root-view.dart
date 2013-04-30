library companyinfo;

import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';
import 'home.dart';
import 'company-info-loader.dart';
import 'portfolio.dart';

class RootView extends WebComponent implements Routable {

  WebComponent currentComponent;

  WebComponent home;
  WebComponent companyInfo;
  WebComponent porfolio;

  RootView() {
    home = new HomeComponent();
    home.host = new DivElement();

    companyInfo = new CompanyInfoLoaderComponent();
    companyInfo.host = new DivElement();

    porfolio = new PortfolioComponent();
    porfolio.host = new DivElement();
  }

  created() {
    var router = new Router(useFragment: true)
      ..addRoute(name: 'root', path: '', mount: this);
    router.listen();
  }

  void configureRouter(Router router) {
    router
      ..addRoute(
          name: 'home',
          defaultRoute: true,
          path: '/home',
          enter: (_) => createAndInsertComponent(home),
          mount: home)
      ..addRoute(
          name: 'companyInfo',
          path: '/companyInfo',
          enter: (_) => createAndInsertComponent(companyInfo),
          mount: companyInfo)
      ..addRoute(
          name: 'portfolio',
          path: '/portfolio',
          enter: (_) => createAndInsertComponent(porfolio),
          mount: porfolio);
  }

  createAndInsertComponent(WebComponent comp) {
    print('do it.... $comp');
    if (currentComponent != null) {
      var lifecycleCaller = new ComponentItem(currentComponent);
      currentComponent.host.remove();
      lifecycleCaller.remove();
    }
    currentComponent = comp;
    var lifecycleCaller = new ComponentItem(comp);
    lifecycleCaller.create();
    host.children.add(comp.host);
    lifecycleCaller.insert();
    return comp;
  }
}