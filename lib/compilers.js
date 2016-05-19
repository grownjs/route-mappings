var util = require('./util');

function compileUrl(re, path) {
  return function(params) {
    var values = arguments.length > 1 ? Array.prototype.slice.call(arguments) : params;
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
        var fixedParent = route._parentHandler || route._resourcePath;

        if (fixedParent) {
          var fixedHandler = subroute.handler || [];

          if (!Array.isArray(fixedHandler)) {
            fixedHandler = [fixedHandler];
          }

          if (fixedHandler.indexOf(fixedParent) === -1) {
            fixedHandler.unshift(fixedParent);

            // prefix named routes to avoid collisions
            if (subroute.as) {
              subroute.as = fixedParent + '.' + subroute.as;
            }
          }

          subroute.handler = fixedHandler;
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

function compileMappings(tree, state) {
  var mappings = {};

  tree.forEach(function(route) {
    if (route.as && typeof route.as !== 'string') {
      throw new TypeError('expecting String for named path but given `' + route.as + '`');
    }

    route.url = compileUrl(state.PARAMS_PATTERN, route.path);
    route.url.name = route.as;

    var keys = route.as.split('.');
    var bag = mappings;

    for (var i = 0, c = keys.length - 1; i < c; i++) {
      if (!bag[keys[i]]) {
        bag[keys[i]] = {};
      }

      bag = bag[keys[i]];
    }

    bag[keys[i]] = bag[keys[i]] || {};

    // copy all properties
    for (var k in route) {
      bag[keys[i]][k] = route[k];
    }
  });

  return mappings;
}

function compileKeypaths(routes, state) {
  return routes.map(function(route) {
    if (!route.as) {
      var action = '';

      if (Array.isArray(route.handler)) {
        action = route.handler[route.handler.length - 1];
      }

      var keys = util.normalizeRoute(state.PARAMS_PATTERN, route.path).split('/');

      if (action && action !== 'index' && action !== keys[keys.length - 1]) {
        keys.push(action);
      }

      keys = keys.map(function(key) {
        return key || 'root';
      });

      route.as = keys.join('.');
    }

    return route;
  });
}

module.exports = {
  compileTree: compileTree,
  compileRoutes: compileRoutes,
  compileMappings: compileMappings,
  compileKeypaths: compileKeypaths
};
