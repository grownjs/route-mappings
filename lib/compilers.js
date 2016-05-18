var pluralize = require('pluralize'),
    singularize = pluralize.singular;

var util = require('./util');

function compileRoutes(state, currentPath) {
  var routes = [];

  state.TREE.forEach(function(route) {
    var fixedPath = route.path !== '/' ? currentPath.concat(route.path) : currentPath;

    if (route.tree) {
      compileRoutes({ TREE: route.tree }, fixedPath).forEach(function(subroute) {
        if (route.handler && Array.isArray(subroute.handler)) {
          subroute.handler.unshift(route.handler);
        }

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
      var fixedHandler = route.handler.slice();
      var fixedAction = fixedHandler.pop();

      alias = [fixedAction].concat(fixedHandler).reduce(function(acc, path, index) {
        if (index === 1 || (index && fixedAction !== 'index')) {
          path = util.ucfirst(singularize(path));
        } else if (index > 1) {
          path = util.ucfirst(pluralize(path));
        }

        acc.push(path);

        return acc;
      }, []).join('');
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
