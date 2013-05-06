library company_info_loader;

import 'dart:html';

import 'package:web_ui/web_ui.dart';
import 'package:route/client.dart';

import 'data.dart' as data;
import 'stream-cleaner.dart';


class CompanyInfoLoaderComponent extends WebComponent {
  Route route;
  @observable var company;
  @observable Route companyRoute;
  StreamCleaner cleaner = new StreamCleaner();

  inserted() {
    companyRoute = route.getRoute('companyId');
    cleaner.add(companyRoute.onRoute.listen(_showCompanyInfo));
  }

  removed() {
    cleaner.cancelAll();
  }

  _showCompanyInfo(RouteEvent e) {
    var tokenInt = int.parse(e.parameters['companyId'], onError: (s) => -1);
    if (tokenInt > -1) {
      data.fetchCompany(tokenInt).then((result) {
        if (result == null) {
          window.alert('Unable to fetch company $tokenInt');
        }
        company = result;
      });
    } else {
      // TODO: navigate to invalid company route...
      window.alert('Invalid company id $tokenInt');
    }
  }
}