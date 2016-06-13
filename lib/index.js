var util = require('./util'),
    bindings = require('./bindings'),
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
  var state = {};

  state.TREE = [];

  // overrideable
  state.RESOURCE_KEY = options.RESOURCE_KEY || RESOURCE_KEY;
  state.PARAMS_PATTERN = options.PARAMS_PATTERN || PARAMS_PATTERN;
  state.SUPPORTED_ACTIONS = options.SUPPORTED_ACTIONS || SUPPORTED_ACTIONS;

  state.INSTANCE_PROPERTIES = util.mergeProps(['TREE', 'RESOURCE_KEY', 'PARAMS_PATTERN', 'SUPPORTED_ACTIONS'], options, {});

  function routeMapper(overrides) {
    overrides = overrides || {};

    // instance properties are just copied
    Object.keys(state.INSTANCE_PROPERTIES).forEach(function(key) {
      overrides[key] = overrides[key] || state.INSTANCE_PROPERTIES[key];
    });

    overrides.RESOURCE_KEY = overrides.RESOURCE_KEY || state.RESOURCE_KEY;
    overrides.PARAMS_PATTERN = overrides.PARAMS_PATTERN || state.PARAMS_PATTERN;
    overrides.SUPPORTED_ACTIONS = overrides.SUPPORTED_ACTIONS || state.SUPPORTED_ACTIONS;

    return RouteMapper(overrides);
  }

  // bind addRoute()
  var addRoute = bindings.bindAddRouteHelper;

  // single/multiple resources
  bindings.bindResourcesHelper(state, routeMapper);

  // mounting/namespacing
  bindings.bindNamespaceHelper(addRoute(state, 'namespace'), routeMapper);

  // http-verbs support
  SUPPORTED_METHODS.forEach(function(httpVerb) {
    bindings.bindHttpVerbHelper(addRoute(state, httpVerb), routeMapper, httpVerb);
  });

  // reverse routing support
  routeMapper.map = function(routes) {
    return bindings.bindMatcherHelper(state, routes);
  };

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
