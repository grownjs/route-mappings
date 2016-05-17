// var pluralize = require('pluralize'),
//     singularize = pluralize.singular;

var util = require('./util');

// TODO: implements these methods
function reduceMappingsTree(state, currentPath) {
  var list = [];

  state.TREE.forEach(function(route) {
    if (route.tree) {
      var fixedPath = route.path !== '/' ? currentPath.concat(route.path) : currentPath;

      reduceMappingsTree({ TREE: route.tree }, fixedPath).forEach(function(subroute) {
        subroute._parentHandler = route.handler || [];
        list.push(subroute);
      });
    } else {
      list.push(util.omit(route, ['tree']));
    }
  });

  return list;
}

function compileMappings(state, currentPath) {
  var mappings = {};

  reduceMappingsTree(state, currentPath).forEach(function(route) {
    if (route.as && typeof route.as !== 'string') {
      throw new TypeError('expecting String for named path but given `' + route.as + '`');
    }

    var prefix = currentPath.join('/');
    var alias = route.as || '';

    if (!alias) {
      var name = util.normalizeRoute(state.PARAMS_PATTERN, route.path);

      if (!prefix) {
        alias += route.path === '/' ? 'root' : name;
      } else {
        alias += prefix + util.ucfirst(name);
      }
    }

    if (!route._parentHandler) {
      mappings[alias] = route;
    } else {
      console.log(alias, route);
    }
  });

  return mappings;
}

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

module.exports = {
  compileRoutes: compileRoutes,
  compileMappings: compileMappings
};
