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
    var fixedNode = util.mergeProps([], state.INSTANCE_PROPERTIES, util.omit(node, ['handler', 'tree']));

    if (typeof node.handler === 'function') {
      fixedNode.tree = node.handler.tree;

      util.reduceHandlers(fixedNode);
      util.reduceResources(fixedNode);
    }

    if (Array.isArray(node.handler)) {
      fixedNode.handler = node.handler.slice();
    }

    // normalize paths
    fixedNode.path = util.dasherize(fixedNode.path);

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
  function urlFor(path) {
    try {
      var obj = urlFor;
      var keys = path.split('.');

      while (keys.length) {
        obj = obj[keys.shift()];
      }

      if (typeof obj === 'function') {
        return obj.apply(null, Array.prototype.slice.call(arguments, 1));
      }

      return obj;
    } catch (e) {
      throw new Error(path + ' mapping not found');
    }
  }

  tree.forEach(function(route) {
    if (route.as && typeof route.as !== 'string') {
      throw new TypeError('expecting String for named path but given `' + route.as + '`');
    }

    route.url = compileUrl(state.PARAMS_PATTERN, route.path);

    var keys = route.as.split('.');
    var bag = urlFor;

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

  return urlFor;
}

function compileKeypaths(routes) {
  return routes.map(function(route) {
    var keys = route.handler.slice();

    if (route._isAction && keys[keys.length - 1] === 'index') {
      keys.pop();
    }

    if (!route.as) {
      route.as = keys.join('.') || 'root';
    } else {
      // prefix named paths with its namespace
      route.as = (keys.length ? keys.join('.') + '.' : '') + route.as;
    }

    // discard last handler value (action) from resources
    if (route.action && route.handler.indexOf(route.action) === route.handler.length - 1) {
      route.handler.pop();
    }

    return route;
  });
}

function compileMatcher(path, state) {
  var keys = [],
      matcher = [];

  var length = 0,
      priority = 0;

  path.split('/').forEach(function(part) {
    var matches = part.match(state.PARAMS_PATTERN);

    if (matches) {
      var optional = part.substr(-1) === '?';

      if (optional) {
        part = part.substr(0, part.length - 1);
      }

      var matcher_tpl = part
        .replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&')
        .replace(/\\([*?])/g, '$1');

      matches.forEach(function(fragment) {
        keys.push(fragment.replace(/\W+/g, ''));

        priority += fragment.indexOf('*') === -1 ? 1 : 2;

        matcher_tpl = matcher_tpl
          .replace(fragment, fragment.indexOf('*') === -1 ? '([^/]+)' : '(.+)');
      });

      if (optional) {
        matcher_tpl = '(?:' + matcher_tpl + ')?';
      }

      priority += matches.length;
      matcher.push(matcher_tpl);
    } else {
      matcher.push(part);
      priority += part.length * 1.5;
    }

    length++;
  });

  var regex = new RegExp('^' + matcher.join('/') + '$');

  return {
    keys: keys,
    regex: regex,
    length: length,
    priority: priority
  };
}

module.exports = {
  compileTree: compileTree,
  compileRoutes: compileRoutes,
  compileMatcher: compileMatcher,
  compileMappings: compileMappings,
  compileKeypaths: compileKeypaths
};
