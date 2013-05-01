library companyinfoloader;

import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';
import 'routable-component.dart';
import 'company-info.dart';
import 'dart:async';
import 'dart:html';

class CompanyInfoLoaderComponent extends RoutableWebComponent {

  @observable var company;
  Router router;
  Router childRouter;
  var currentComponent;

  void configureRouter(Router router) {
    print('CompanyInfoLoaderComponent.configureRouter');
    this.router = router
      ..addRoute(
          name: 'company',
          path: '/:companyId',
          enter: _showCompanyInfo,
          leave: _hideCompanyInfo,
          mount: (r) => childRouter = r);
  }

  _showCompanyInfo(RouteEvent e) {
    print('_companyInfoRouter ${e.parameters['companyId']}');
    var tokenInt = int.parse(e.parameters['companyId'], onError: (s) => -1);
    if (tokenInt > -1) {
      company = {
        'id': tokenInt,
        'name': 'Company $tokenInt',
        'revenue': 3000000.00
      };
      var info = new CompanyInfoComponent();
      info.company = company;
      createAndInsertComponent(info);
      childRouter.addRoute(name: 'info', defaultRoute: true, path: '', mount: info);
      router.reroute();
    }
  }

  createAndInsertComponent(WebComponent comp) {
    comp.host = new DivElement();
    currentComponent = comp;
    var lifecycleCaller = new ComponentItem(comp);
    lifecycleCaller.create();
    host.children.clear();
    host.children.add(comp.host);
    lifecycleCaller.insert();
  }

  _hideCompanyInfo(RouteEvent e) {
    if (currentComponent != null) {
      var lifecycleCaller = new ComponentItem(currentComponent);
      currentComponent.host.remove();
      lifecycleCaller.remove();
      childRouter.removeRoute('info');
    }
    currentComponent = null;
  }
}