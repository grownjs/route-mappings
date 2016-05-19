var bindings = require('./bindings'),
    compilers = require('./compilers');

var RESOURCE_KEY = ':id';

var SUPPORTED_METHODS = ['get', 'put', 'post', 'patch', 'delete'];

var SUPPORTED_ACTIONS = {
  index: { verb: 'get' },
  create: { verb: 'post' },
  update: { verb: 'put', path: '/:id' }, // or patch?
  destroy: { verb: 'delete', path: '/:id' },
  new: { verb: 'get', path: '/new' },
  show: { verb: 'get', path: '/:id' },
  edit: { verb: 'get', path: '/:id/edit' }
};

var PARAMS_PATTERN = /[:*](\w+)/g;

// factory
function RouteMapper(options) {
  // normalize options
  options = options || {};

  // private state
  var state = {
    TREE: [],
    RESOURCE_KEY: options.RESOURCE_KEY || RESOURCE_KEY,
    PARAMS_PATTERN: options.PARAMS_PATTERN || PARAMS_PATTERN,
    SUPPORTED_ACTIONS: options.SUPPORTED_ACTIONS || SUPPORTED_ACTIONS
  };

  function routeMapper(overrides) {
    // merge options with parent ones
    return RouteMapper(overrides);
  }

  // bind addRoute()
  var addRoute = bindings.bindAddRouteHelper(state, routeMapper);

  // single/multiple resources
  bindings.bindResourcesHelper(state, routeMapper);

  // mounting/namespacing
  bindings.bindNamespaceHelper(addRoute, routeMapper);

  // http-verbs support
  SUPPORTED_METHODS.forEach(function(httpVerb) {
    bindings.bindHttpVerbHelper(addRoute, routeMapper, httpVerb);
  });

  function fixedTree() {
    return compilers.compileTree(state);
  }

  function fixedRoutes() {
    return compilers.compileKeypaths(compilers.compileRoutes(fixedTree(), state, []), state);
  }

  // named-routes builder
  Object.defineProperty(routeMapper, 'mappings', {
    get: function() { return compilers.compileMappings(fixedRoutes(), state); }
  });

  // plain-routes builder
  Object.defineProperty(routeMapper, 'routes', {
    get: function() { return fixedRoutes(); }
  });

  // read-only properties
  Object.defineProperty(routeMapper, 'tree', {
    get: function() { return fixedTree(); }
  });

  return routeMapper;
}

module.exports = RouteMapper;
