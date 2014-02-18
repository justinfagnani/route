// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of route.client;

const String NAVIGATE = 'navigate';

/**
 * Returns a [CustomEvent] representing a navigation event.
 */
createNavigationEvent(String href) =>
    new html.CustomEvent(NAVIGATE, detail: {'href': href});

/**
 * A mixin to capture click events and fire navigation events.
 */
abstract class Navigator implements html.Element {

  initNavigator() {
    this.shadowRoot.on['click'].listen((html.MouseEvent e) {
      var target = e.target;
      if (target is html.AnchorElement) {
        e.preventDefault();
        this.dispatchEvent(createNavigationEvent(target.href));
      }
    });
  }
}
