var bindings = require('./bindings'),
    compilers = require('./compilers');

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
  bindings.bindResourcesHelper(state, addRoute, routeMapper);

  // mounting/namespacing
  bindings.bindNamespaceHelper(addRoute, routeMapper);

  // http-verbs support
  SUPPORTED_METHODS.forEach(function(httpVerb) {
    bindings.bindHttpVerbHelper(addRoute, routeMapper, httpVerb);
  });

  // named-routes builder
  Object.defineProperty(routeMapper, 'mappings', {
    get: function() { return compilers.compileMappings(state.TREE, state.PARAMS_PATTERN, []); }
  });

  // plain-routes builder
  Object.defineProperty(routeMapper, 'routes', {
    get: function() { return compilers.compileRoutes(state.TREE, []); }
  });

  // read-only properties
  Object.defineProperty(routeMapper, 'tree', {
    get: function() { return state.TREE; }
  });

  return routeMapper;
}

module.exports = RouteMapper;
