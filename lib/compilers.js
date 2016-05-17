var pluralize = require('pluralize'),
    singularize = pluralize.singular;

var util = require('./util');

// TODO: implements these methods
function compileMappings(state, currentPath) {
  var mappings = {};

  state.TREE.forEach(function(route) {
    if (route.as && typeof route.as !== 'string') {
      throw new TypeError('expecting String for named path but given `' + route.as + '`');
    }

    var prefix = currentPath.join('/');
    var alias = route.as || '';

    if (!alias) {
      var fixedPath = util.normalizeRoute(state.PARAMS_PATTERN, route.path);

      if (!prefix) {
        alias += route.path === '/' ? 'root' : fixedPath;
      } else {
        alias += prefix + util.ucfirst(fixedPath);
      }
    }

    if (!route.tree) {
      mappings[alias] = util.omit(route, ['tree']);
    } else {
      // TODO: this shit...
      // console.log(route, alias);
    }
  });

  return mappings;
}

function compileRoutes(state, currentPath) {
  var routes = [];

  state.TREE.forEach(function(route) {
    var fixedPath = route.path !== '/' ? currentPath.concat(route.path) : currentPath;

    if (route.tree) {
      compileRoutes({ TREE: route.tree }, fixedPath).forEach(function(route) {
        routes.push(route);
      });
    } else {
      var fixedRoute = util.omit(route, ['tree']);

      fixedRoute.path = fixedPath.join('') || '/';

      routes.push(fixedRoute);
    }
  });

  return routes;
}

module.exports = {
  compileRoutes: compileRoutes,
  compileMappings: compileMappings
};
