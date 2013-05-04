/**
 * Mock implementation of the data service library.
 */
library dataservice;

import 'dart:async';

var _companies = [
  {
    'id': 100001,
    'name': 'Company 100001',
    'revenue': 3000000.00
  },
  {
    'id': 111111,
    'name': 'Company 1111111',
    'revenue': 1001100.00
  },
  {
    'id': 100003,
    'name': 'Mom & Pop Shop',
    'revenue': 401000.00
  }
];

/// simulate an RPC call to fetch companies from a JSON source
Future<List<Map>> fetchCompanies() {
  return new Future.delayed(new Duration(seconds: 1), () => _companies);
}

/// simulate an RPC call to fetch a company from a JSON source
Future<Map> fetchCompany(int id) {
  for (var c in _companies) {
    if (c['id'] == id) {
      return new Future.delayed(new Duration(seconds: 1), () => c);
    }
  }
  return new Future.delayed(new Duration(seconds: 1), () => null);
}
