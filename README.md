# RouteMappings

[![travis-ci](https://api.travis-ci.org/pateketrueke/route-mappings.svg)](https://travis-ci.org/pateketrueke/route-mappings)
[![codecov](https://codecov.io/gh/pateketrueke/route-mappings/branch/master/graph/badge.svg)](https://codecov.io/gh/pateketrueke/route-mappings)

Function factory to create nested definitions of routes, with namespaces and resources support.

```javascript
var RouteMappings = require('route-mappings');

// create a new RouteMapper instance
var routeMappings = RouteMappings()
  .get('/', { to: 'home_handler' })
  .get('/login', { to: 'login_handler' })
  .delete('/logout', { to: 'logout_handler' })
  .resources('/articles')
  .namespace('/account', function() {
    return RouteMappings()
      .get('/', { to: 'show_account_handler' })
      .put('/', { to: 'update_account_handler' })
      .get('/edit', { to: 'edit_account_handler' });
  });

// print all registered routes
routeMappings.routes.forEach(function(route) {
  // 1) the "to" option is not used internally, but this demonstrate you can pass whatever you want
  // 2) all routes have a "handler" property which holds its namespace,
  // which is useful on resource definitions since they can't be named directly
  console.log(route.verb.toUpperCase(), route.path, route.to || route.handler.join('_'));
});

// access url() helper for building routes
console.log(routeMappings.mappings.root.url());
console.log(routeMappings.mappings.login.url());
console.log(routeMappings.mappings.logout.url());
console.log(routeMappings.mappings.account.url());
console.log(routeMappings.mappings.account.edit.url());
console.log(routeMappings.mappings.articles.edit.url(42));
```

## Instance settings

`RouteMappings(options: Object)` &mdash; Create a new function factory from given options:

- `RESOURCE_KEY: String` &mdash; Used on resources to name the `/<id>` segment (default is `:id`)

  On nested resources it becomes from `:id` to `:resource_id` automatically, so you'll end up with something like this `/posts/:post_id/comments/:id`

- `PARAMS_PATTERN: RegExp` &mdash; Used for match-and-replace params from given routes (default is `/[:*](\w+)/g`)

  Note the global `g` flag and the first capture `(\w+)` on the regular expression, don't forget it, otherwise all stuff related with urls won't work as expected.

- `SUPPORTED_ACTIONS: Object` &mdash; Settings for translating resource actions to routes (defaults are in [./lib/index.js#L8-L16](https://github.com/pateketrueke/route-mappings/blob/master/lib/index.js#L8-L16))

  If you provide your own options don't forget to use `:id` as the `RESOURCE_KEY` is defined, otherwise replacements won't occur.

## Methods

 - `<http-verb>(path: String, params: Object)` &mdash; Basic method for call any HTTP method, e.g. `get('/', { as: 'root' })`

  The `as` option is used for named routes, if missing it will be constructed from the route name and handler.

  Internally it will add a `handler` option containing all parent handlers (if present) from a single route, all other values will be passed as is.

 - `namespace(path: String, factory: <Function|Object>)` &mdash; This method allows to mount other route mappings (instances) into the current instance.

  The `factory` can be also a function which returns a new RouteMappings instance when called.

 - `resources(...path: <String|Array>, params: Object, factory: <Function|Object>)` &mdash; Shortcut for creating route mappings from resources

  In fact, a resource is a new RouteMappings instance mounted within the given namespace.

### Nesting support

Consider the following example:

```javascript
var $ = RouteMappings()
  .resources('/Parent', function () {
    return RouteMappings()
      .resources('/Children');
  })
  .namespace('/Section', function () {
    return RouteMappings()
      .resources('/Parent', function () {
        return RouteMappings()
          .resources('/Children');
      });
  }).mappings;
```

Where:

- `$.Parent.Children.path` will be `/Parent/:parent_id/Children`
- `$.Parent.Children.handler` will be `['Children']`
- `$.Section.Parent.Children.path` will be `/Section/Parent/:parent_id/Children`
- `$.Section.Parent.Children.handler` will be `['Section', 'Children']`

As you can see, nested resources will not carry their parent details when building handlers, only namespaces are taken into account for that.

## Properties

- `tree: Array` &mdash; Read-only property containing all the route definitions

- `routes: Array` &mdash; Read-only property containing all the route definitions as a flattened list

  Each route will have, at least:
  - `as` &mdash; The computed name for accesing this route through `mappings`, if missing it will be computed from the route details
  - `verb` &mdash; The specified HTTP verb uses from `<http-verb>()` calls, if missing you can assume the route is `GET`
  - `path` &mdash; The provided path from any call, as is, without modifications
  - `handler` &mdash; The computed handler for each single route as array

- `mappings: Object` &mdash; Read-only property containing a tree of all named routes namespaced

  Each route hold the same data as accesing `routes` but with an extra `url()` function, useful for generating routes from given paths.

  Given `/foo/:bar` you can use `url(123)` to produce `/foo/123`, if you pass an object it should be called as `url({ bar: 123 })` to produce the same url.

## Integration example

```javascript
// example modules
var path = require('path'),
    express = require('express');

var expressRouter = express.Router();

// iterate all compiled routes
routeMappings.routes.forEach(function(route) {
  // append custom "to" handler
  if (route.to) {
    route.handler.push(route.to);
  }

  // hipotetical modules as controllers
  var controller = path.join(__dirname, 'controllers', route.handler.join('/') + '.js');

  // load the resolved module
  var handler = require(controller);

  // specific action/function from module?
  if (route.action) {
    handler = handler[route.action];
  }

  // finally, we can register the route and handler
  expressRouter.route(route.path)[route.verb](handler);
});
```

Made with &hearts; at [Empathia](http://empathia.agency/)
