var util = require('./util');

function compileUrl(re, path) {
  return function(params) {
    var values = arguments.length > 2 ? Array.prototype.slice.call(arguments, 1) : params;
    var isArray = Array.isArray(values);

    if (!isArray && typeof values !== 'object') {
      isArray = true;
      values = [values];
    }

    return path.replace(re, function(_, $1) {
      return isArray ? values.shift() : values[$1];
    });
  };
}

function compileTree(state) {
  var tree = [];

  state.TREE.forEach(function(node) {
    var fixedNode = util.omit(node, ['handler']);

    if (typeof node.handler === 'function') {
      fixedNode.tree = node.handler.tree;

      if (node.handler._isNamespace) {
        fixedNode._parentHandler = util.normalizeRoute(state.PARAMS_PATTERN, fixedNode.path);
      }
    } else if (node.handler) {
      fixedNode.handler = node.handler;
    }

    tree.push(fixedNode);
  });

  return tree;
}

function compileRoutes(tree, state, currentPath) {
  var routes = [];

  tree.forEach(function(route) {
    var fixedPath = route.path !== '/' ? currentPath.concat(route.path) : currentPath;

    if (route.tree) {
      compileRoutes(route.tree, state, fixedPath).forEach(function(subroute) {
        if (route._parentHandler) {
          subroute.handler = subroute.handler || [];

          if (subroute.handler[0] !== route._parentHandler) {
            subroute.handler.unshift(route._parentHandler);
          }
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

function compileMappings(tree, state, currentPath) {
  var mappings = {};

  compileRoutes(tree, state, currentPath).forEach(function(route) {
    if (route.as && typeof route.as !== 'string') {
      throw new TypeError('expecting String for named path but given `' + route.as + '`');
    }

    route.url = compileUrl(state.PARAMS_PATTERN, route.path);

    var alias = route.as || '';

    if (alias) {
      mappings[alias] = route;
    } else {
      var action;

      if (Array.isArray(route.handler)) {
        alias = route.handler.join('/');
        action = route.handler[route.handler.length - 1];
      }

      var keys = util.normalizeRoute(state.PARAMS_PATTERN, route.path).split('/');

      if (action && action !== 'index' && action !== keys[keys.length - 1]) {
        keys.push(action);
      }

      var bag = mappings;

      for (var i = 0, c = keys.length - 1; i < c; i++) {
        if (!bag[keys[i]]) {
          bag[keys[i]] = {};
        }

        bag = bag[keys[i]];
      }

      bag[keys[i] || 'root'] = route;
    }
  });

  return mappings;
}

module.exports = {
  compileTree: compileTree,
  compileRoutes: compileRoutes,
  compileMappings: compileMappings
};
