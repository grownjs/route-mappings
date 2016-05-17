## Intro

This document underlines a universal, agnostic and common DSL for organizing routes for Javascript applications.

## Feature summary

- Allows you to define any route, with placeholders, nesting and resources
- Allows you to retrieve all the compiled routing information for IoC purposes

## Background

After few hours reading the source code from the Neonode foundation I noticed that the shipped router is bloated and surely we don't need it.

### What do we have?

We're using a RouteMapper implementation which is very similar to RoR routing: this is exactly what we need. On PatOS, by example, there are only few method calls for basic http-verbs, resources and namespacing.

## Constraints

- Should be written in ES5 (which is key for our workflow)
- Should provide the same RouteMapper's API, methods and such
- Should maintain a similar output, e.g. for performing IoC outside (as Neonode does)

> Update: we don't want to constraint this implementation from specifying `Controller#action` syntax only, you should be able to pass anything do you want and then, within the IoC use the passed data as your convenience.

## Assumptions

- It will be primarly used by Neonode as RouteMapper replacement
- Then, IoC should happen somewhere else outside the router's context

> Update: formerly I assumed that building a plain list for all routes would be enough, and I loudly failed.

> That was because RouteMapper has a `routes` property that is a plain array, but in my research and reverse engineering that wasn't so obvious.

## Blackbox

![router](https://www.lucidchart.com/publicSegments/view/d3b23145-ff18-4124-b6f5-2e9902096eaa/image.png)

- `RouteMapper()` is a factory
- `<http-verb>`, `resources()` and `namespace()` are public methods
- `tree[]` is the instance holder for all registered routes (read-only)
- `routes[]` and `mappings{}` are generated on the fly using `Object.defineProperty()` (read-only)
- `_addRoute()` and `_buildRoute()` are hidden

## Research

I found few similar approaches but they are too tied to Express, many of them expects some handlers for IoC which is not required by default, or simply its DSL is ugly:

- https://github.com/trekjs/route-mapper
- https://github.com/expressjs/express-resource
- https://github.com/carlosmarte/expressjs-route-mapper
- https://github.com/flea89/express-routes-map
- https://github.com/petwho/express-route-mapper

### Prototyping

Gist: https://gist.github.com/pateketrueke/e3c3c2585453ecf34061ef4e691f8a04

## Functional spec

This class should provide the following methods:

- `_addRoute(path, params)`
  - Each route is normalized with its params to provide the same data as RouteMapper
  - Also a mapping is created from the given path to provide helpers from named routes
- `_buildRoute(name, ...values)`
  - Render a named path with optional values
  - Given `values` can be an array, object or extra arguments
- `namespace(path, callback)`
  - Nest several levels of route definitions within the given path
  - Any route defined from its callback will be mounted under the created namespace
- `<http-verb>(path, params)`
  - It will responds to any `<http-verb>` supported, e.g. `post('/login')`
- `resources(array, options)`
  - Should support other constraints like `except` or `only` as options
  - Shortcut for RESTful actions (`index`, `create`, `new`, `show`, `update`, `destroy`, `edit`)
  - Also, you can pass a extra arguments or a single string for specifying single or multiple resources; if the last argument is an object it will be used as `options`

> Update: the `root()` method isn't supported since it's only a convenience for `get('/')`, of course a `root` mapping is still registered since there only root-path per application

Also exposes "public" properties:

- `tree` &mdash; an array holding the parsed data from all defined routes
- `routes` &mdash; an array holding the normalized paths from all defined routes
- `mappings` &mdash; an object holding named routes for easy path-to-url generation

### Examples of usage

The implementation should provide a nice DSL using a fluent API, for doing stuff like:

```javascript
// syntax proposal (factory)
module.exports = RouteMapper()
  .get('/', { to: 'Home#index' })
  .get('/login', { to: 'Sessions#new', as: 'login' })
  .post('/login', { to: 'Sessions#create', as: 'login' });
  .namespace('admin', function() {
    // this way we can "mount" route definitions,
    // you must return another RouterMapper instance
    return RouteMapper()
      .get('/', { to: 'Admin#index' });
  });
```

> ~~Update: in order to maintain the same DSL when mounting new mappings you should reuse the same instance within the `namespace()` callback and return nothing (or return the same instance)~~

> **Update: you should always return a new RouteMapper() instance!**

## Technical spec

The function `RouteMaper` is a factory which can take an options map for setting up some internal behaviors:

```javascript
var routeMapper = RouteMapper({
  // defaults (instance properties)
  PARAMS_PATTERN: /[:*]\w+/g,
  SUPPORTED_ACTIONS: {
    index: { verb: 'get' },
    create: { verb: 'post' },
    update: { verb: 'put' /* or patch? */, path: '/:id' },
    destroy: { verb: 'delete', path: '/:id' },
    new: { verb: 'get', path: '/new' },
    show: { verb: 'get', path: '/:id' },
    edit: { verb: 'get', path: '/:id/edit' }
  }
});
```

> Update: `<http-verbs>` are predefined/private by default and cannot be override; all other passed options will do if they are present

This factory creates another factory, which is used to register all the routes.

Each factory created is decorated then with fluent-methods to provide the wanted DSL behavior.

### Options

`PARAMS_PATTERN` is used for match-and-replace placeholders from given routes, e.g. `/foo/:id` where `:id` is the parameter.

`SUPPORTED_ACTIONS` is used when calling `resources()` to automatically create predefined routes with the given actions.

### Private methods

`_addRoute(path: String, options: <Array|Object>)`

Normalize and append the given route in the current instance.

If `options` is an array, it would be attached to the handler as a `tree`, this is the principle behind mounting new mappings.

Namespaces and resources are mappings after all, so they're mounted the same  way.

- `path` is the **route** to be mounted, it MUST have a leading slash, e.g. `/`
- `options.as` is used on `mappings` for building url helpers, e.g. `my_route`
- `options.tree` is mounted from `namespace()` and `resource()` callbacks

If no `options.as` is given the named route will be generated from the namespace and path.

> Update: all other params should be passed as is, this will allow us to handle it whatever we want within IoC; profit!

Pseudocode:

```json
validate if the path has a leading slash
normalize the given options (handler/tree)
validate if the "options.as" is a string
  if is not present, generate it from given options
append the named route to the instance mappings
append the normalized route within the instance tree
the router instance is returned then
```

`_buildRoute(name: String, ...values: <Array|Object>)`

Produce a url for the given named route from the instance mappings.

- `name` is the related alias from a registered route, e.g. `my_route`
- `values` are used for interpolating the matching route, e.g. `['foo', 123]`

Pseudocode:

```json
validate if the named route exists within the instance mappings
replace all found ":params" within the route
  if an object is given use the param name to extract the values
  if an array is given use "shift()" to retrieve each value in order
  if more than two arguments are given, use the rest arguments as values
the generated url is returned then
```

### Public methods

`<http-verb>(path: String, options: Object)`

Shortcut syntax for well-known HTTP methods, sugar only.

This will call `_addRoute()` with `{ verb: '<http-verb>' }` as params.

Pseudocode:

```json
normalize the given options as an object
add the http-verb (method name) value as "verb" property
call-and-return _addRoute() with the normalized arguments
```

`namespace(path: String, callback: Function)`

- `path` is the route where all defined routes will be mounted
- `callback` should register some routes in order to be mounted

> Update: since each instance represents itself a **mount-point**, you can mount new mappings over existing ones

Pseudocode:

```json
validate the namespace (no leading slashes)
validate the callback
  given a function execute it, then
    lets assume some registration happen
    if returns a new RouterMapper instance mount it
  given a RouteMapper instance mount it
the router instance is returned then
```

`resources(paths: String[], options: Object>)`

- `paths` can be a single string, an array of strings, or simply arguments

> Update: since resources are tied to RESTful operations they will provide its related `http-verb` as method by default, of course you can change this by supplying your own `SUPPORTED_ACTIONS` as instance options

Pseudocode:

```json
validate the user input with the given constraints
create a single array holding all the normalized resources
create a new RouterMapper instance
  append all required routes
  mount it within the current instance
the router instance is returned then
```

### Public properties

`tree[]` (read only)

- Default: `[]`
- All registered-and-mounted routes
- Expected output:

```javascript
[
  { handler: 'index', path: '/', verb: 'get' },
  { handler: 'login', path: '/login', verb: 'get' },
  {
    path: '/foo',
    tree: [
      { handler: ['foo', 'index'], path: '/', verb: 'get' },
      { handler: ['foo', 'update'], path: '/:id', verb: 'put' },
      ...
    ]
  },
  ...
]
```

`routes` (read only)

- Default: `[]`
- Compiled list of all instance routes, ready for IoC
- Expected output:

```javascript
[ { handler: 'index', path: '/', verb: 'get' },
  { handler: 'login', path: '/login', verb: 'get' },
  { handler: ['foo', 'index'], path: '/foo', verb: 'get' },
  { handler: ['foo', 'index'], path: '/foo/:id', verb: 'put' },
  ... ]
```

`mappings` (read only)

- Default: `{}`
- Compiled mappings for generating urls from the registered routes
- Expected output:

```javascript
{ index: '/',
  login: '/login',
  foo: '/foo',
  updateFoo: '/foo/:id'
  ... }
```

## Integration with Express (example)

```javascript
// common stuff and such
var router = require('express').Router();

var routeMapper = RouteMapper()
  // we can pass an object for customize everything
  .get('/', { my_handler: 'foo_bar' })
  // given a string we pass it as `{ handler: 'another_handler' }`
  .get('/yay', 'another_handler')
  // namespaces support
  .namespace('/foo', function() {
    return RouteMapper()
    // nested resources within /foo namespace
    .resources('/baz', { except: 'destroy' }, function() {
      return RouteMapper()
        .resources(['/buzz', '/bazzinga'], { only: 'index' });
    });
  });

// lets grab our controllers from somewhere else
var controllers = require('./controllers');

// iterate all compiled routes and register each one
routeMapper.routes.forEach(function(route) {
  // extract the desired details from your compiled routes
  var handler = route.handler || route.my_handler,
    method = route.method || 'get';

  // perform any IoC or just add the route and callback
  router.route(route.path)[method](controllers[handler]);
});

// update: this should be provided by RouteMapper.helpers (?)
// container for url-helpers
var urlFor = {};

// bind helpers for all registered mappings
for (var fn in routeMapper.mappings) {
  urlFor[fn] = function() {
    var args = Array.prototype.slice.call(arguments);
    return routeMapper.buildRoute(fn, args);
  };
}

// now you can do this
console.log(urlFor.yay());
```
