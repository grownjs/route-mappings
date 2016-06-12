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
  options.TREE = [];
  options.RESOURCE_KEY = options.RESOURCE_KEY || RESOURCE_KEY;
  options.PARAMS_PATTERN = options.PARAMS_PATTERN || PARAMS_PATTERN;
  options.SUPPORTED_ACTIONS = options.SUPPORTED_ACTIONS || SUPPORTED_ACTIONS;
  options.PRIVATE_PROPERTIES = ['TREE', 'RESOURCE_KEY', 'PARAMS_PATTERN', 'SUPPORTED_ACTIONS', 'PRIVATE_PROPERTIES'];

  function routeMapper(overrides) {
    return RouteMapper(util.mergeProps(options.PRIVATE_PROPERTIES, options, overrides || {}));
  }

  // bind addRoute()
  var addRoute = bindings.bindAddRouteHelper;

  // single/multiple resources
  bindings.bindResourcesHelper(options, routeMapper);

  // mounting/namespacing
  bindings.bindNamespaceHelper(addRoute(options, 'namespace'), routeMapper);

  // http-verbs support
  SUPPORTED_METHODS.forEach(function(httpVerb) {
    bindings.bindHttpVerbHelper(addRoute(options, httpVerb), routeMapper, httpVerb);
  });

  // reverse routing support
  routeMapper.map = function(routes) {
    return bindings.bindMatcherHelper(options, routes);
  };

  function fixedTree() {
    return compilers.compileTree(options);
  }

  function fixedRoutes() {
    return compilers.compileKeypaths(compilers.compileRoutes(fixedTree(), options, []), options);
  }

  // named-routes builder
  Object.defineProperty(routeMapper, 'mappings', {
    get: function() { return compilers.compileMappings(fixedRoutes(), options); }
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
