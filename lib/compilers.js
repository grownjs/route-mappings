var pluralize = require('pluralize'),
    singularize = pluralize.singular;

var util = require('./util');

function compileRoutes(state, currentPath) {
  var routes = [];

  state.TREE.forEach(function(route) {
    var fixedPath = route.path !== '/' ? currentPath.concat(route.path) : currentPath;

    if (route.tree) {
      compileRoutes({ TREE: route.tree }, fixedPath).forEach(function(subroute) {
        routes.push(subroute);
      });
    } else {
      var fixedRoute = util.omit(route, ['tree']);

      fixedRoute.path = fixedPath.join('') || '/';

      routes.push(fixedRoute);
    }
  });

  return routes;
}

function compileMappings(state, currentPath) {
  var mappings = {};

  compileRoutes(state, currentPath).forEach(function(route) {
    if (route.as && typeof route.as !== 'string') {
      throw new TypeError('expecting String for named path but given `' + route.as + '`');
    }

    var prefix = currentPath.join('/');
    var alias = route.as || '';

    if (!alias && Array.isArray(route.handler)) {
      var fixedResource = route.handler[1] !== 'index' ? singularize : pluralize;

      alias = [route.handler[1], util.ucfirst(fixedResource(route.handler[0]))].join('');
    }

    if (!alias) {
      var name = util.normalizeRoute(state.PARAMS_PATTERN, route.path);

      if (!prefix) {
        alias += route.path === '/' ? 'root' : name;
      } else {
        alias += prefix + util.ucfirst(name);
      }
    }

    mappings[alias] = route;
  });

  return mappings;
}

module.exports = {
  compileRoutes: compileRoutes,
  compileMappings: compileMappings
};
