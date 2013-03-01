Route
=====

Route is a client + server routing library for Dart that helps make building
single-page web apps and using `HttpServer` easier.

UrlPattern
----------

Route is built around `UrlPattern` a class that matches, parses and produces
URLs. A `UrlPattern` is similar to a regex, but constrained so that it is
_reversible_, given a `UrlPattern` and a set or arguments you can produce the
URL that when parsed returns those same arguments. This is important for keeping
the URL space for your app flexible so that you can change a URL for a resource
in one place and keep your app working.

Route lets you use the same URL patterns for client-side and server-side
routing. Just define a library containing all your URLs.

As an example, consider a blog with a home page and an article page. The article
URL has the form /article/1234. We want to show articles without reloading the
page.

Example (urls.dart):

    library urls;

    import 'package:route/url_pattern.dart';

    final homeUrl = new UrlPattern(r'/');
    final articleUrl = new UrlPattern(r'/article/(\d+)');
    final allUrls = [homeUrl, articleUrl];

Client Routing
--------------

On the client, there is a `Router` class that associates `UrlPattern`s
to handlers. Given a URL, the router finds a pattern that matches, and invokes
it's handler. This is similar to
`HttpServer.addRequestHandler(matcher, handler)` on the server. The handlers
are then responsible for rendering the appropriate changes to the page.

The `Router` can listen to `Window.onPopState` events and invoke the correct
handler so that the back button seamlessly works.

Example (client.dart):

    library client;

    import 'package:route/client.dart';

    main() {
      var router = new Router();
      router.addHandler(homeUrl, showHome);
      router.addHandler(articleUrl, showArticle);
    }

    void showHome(String path) {
      // nothing to parse from path, since there are no groups
    }

    void showArticle(String path) {
      var articleId = articleUrl.parse(req.path)[0];
      // show article page with loading indicator
      // load article from server, then render article
    }

Server Routing
--------------

On the server, route gives you a utility function to match `HttpRequest`s
against `UrlPatterns`.

    import 'urls.dart';
    import 'package:route/server.dart';

    import 'package:route/server.dart';
    import 'package:route/pattern.dart';

    HttpServer.bind().then((server) {
      var router = new Router(server);
      router.filter(matchesAny(allUrls), authFilter);
      router.serve(homeUrl).listen(serverHome);
      router.serve(articleUrl).listen(serveArticle);
    });

    Future<bool> authFilter(req) {
      return getUser(getUserIdCookie(req)).then((user) {
        if (user != null) {
          return true;
        }
        serveLoginPage(req);
        return false;
      });
    }

    serveArcticle(req) {
      var articleId = articleUrl.parse(req.path)[0];
      // retreive article data
    }

Further Goals
-------------

 * Integration with Web UI so that the changing of UI views can happen
   automatically.
 * Handling different HTTP methods to help implement REST APIs.
 * Automatic generation of REST URLs from a single URL pattern, similar to Ruby
   on Rails
 * Helpers for nested views and key-value URL schemes common with complex apps.
 * [Done] ~~Server-side routing for the dart:io v2 `HttpServer`.~~
 * [Done] ~~IE 9 support~~
