function typeOf(value) {
  var test = Object.prototype.toString.call(value);

  return test.substr(8, test.length - 9).toLowerCase();
}

function ucfirst(value) {
  return value.substr(0, 1).toUpperCase() + value.substr(1);
}

function clone(object) {
  if (typeof object !== 'object') {
    return object;
  }

  if (Array.isArray(object)) {
    return object.map(clone);
  }

  var copy = {};

  Object.keys(object).forEach(function(key) {
    copy[key] = clone(object[key]);
  });

  return copy;
}

function pick(object, keys) {
  if (typeOf(object) !== 'object') {
    throw new TypeError('expecting Object but given `' + object + '`');
  }

  if (!Array.isArray(keys)) {
    throw new TypeError('expecting Array but given `' + keys + '`');
  }

  var copy = {};

  keys.forEach(function(key) {
    copy[key] = clone(object[key]);
  });

  return copy;
}

function omit(object, keys) {
  if (typeOf(object) !== 'object') {
    throw new TypeError('expecting Object but given `' + object + '`');
  }

  if (!Array.isArray(keys)) {
    throw new TypeError('expecting Array but given `' + keys + '`');
  }

  var copy = {};

  for (var key in object) {
    if (keys.indexOf(key) === -1) {
      copy[key] = clone(object[key]);
    }
  }

  return copy;
}

function toArray(value) {
  if (typeof value === 'undefined') {
    return [];
  }

  return Array.isArray(value) ? value : [value];
}

function mergeProps(skip, source, target) {
  Object.keys(source || {}).forEach(function(key) {
    if (skip.indexOf(key) === -1) {
      if (typeof source[key] === 'object' && typeof target[key] === 'object') {
        if (!(Array.isArray(source[key]) && Array.isArray(target[key]))) {
          // objects are fully-merged
          target[key] = mergeProps(skip, source[key], target[key] || {});
        } else {
          // if both sides are arrays they are combined
          Array.prototype.unshift.apply(target[key], source[key].filter(function(value) {
            return target[key].indexOf(value) === -1;
          }));
        }
      } else {
        // other values are just replaced
        target[key] = typeof target[key] === 'undefined' ? source[key] : target[key];
      }
    }
  });

  return target;
}

function dasherize(value) {
  // CamelCase => camel-case
  return value.replace(/(\b|[a-z])([A-Z])/g, function(_, $1, $2) {
    return ($1 ? $1 + '-' : '') + $2.toLowerCase();
  });
}

function normalizeRoute(re, path) {
  if (typeOf(re) !== 'regexp') {
    throw new TypeError('expecting RegExp but given `' + re + '`');
  }

  if (typeof path !== 'string') {
    throw new TypeError('expecting String but given `' + path + '`');
  }

  return path
    // remove all params from the route
    .replace(re, '')
    // remove all non-word (and slashes) characters
    .replace(/[^\/\w]+/g, '')
    // normalize duplicated slashes
    .replace(/\/{2,}/g, '/')
    // trim extra slashes
    .replace(/^\/|\/$/g, '');
}

function normalizeHandler(path, state, params, method) {
  if (typeof path !== 'string') {
    throw new TypeError('expecting String but given ' + method + '(`' + path + '`, ...)');
  }

  if (path.charAt() !== '/') {
    throw new TypeError('missing leading slash for given ' + method + '(`' + path + '`, ...)');
  }

  if (path.length > 1 && path.substr(path.length - 1, 1) === '/') {
    throw new TypeError('unexpected trailing slash for given ' + method + '(`' + path + '`, ...)');
  }

  if (path.indexOf('//') > -1) {
    throw new TypeError('unexpected consecutive slashes for given ' + method + '(`' + path + '`, ...)');
  }

  if (typeof params === 'undefined') {
    params = { handler: normalizeRoute(state.PARAMS_PATTERN, path) || 'index' };
  }

  if (typeof params !== 'object') {
    params = { handler: params };
  }

  if (typeof params.handler === 'string') {
    params.handler = params.handler.split(/\W+/);
  }

  // support for known aliasing
  if (typeof params.to === 'string') {
    var _parts = params.to.split(/\W+/);

    params._resourceName = _parts[0];

    if (_parts[1]) {
      params._actionName = _parts[1];
    }
  }

  delete params.to;

  return params;
}

function sortByPriority(routes) {
  return routes.sort(function(a, b) {
    if (b.matcher.priority === a.matcher.priority) {
      if (a.matcher.depth !== b.matcher.depth) {
        return a.matcher.depth - b.matcher.depth;
      }

      return 0;
    }

    return b.matcher.priority - a.matcher.priority;
  });
}

function reduceResources(node, namespace) {
  if (node.tree) {
    node.tree.forEach(function (subroute) {
      reduceResources(subroute, node._isNamespace && node._resourceKey);
    });
  }

  if (node._isResource && namespace && node.path.indexOf(namespace) === -1) {
    node.path = '/' + namespace + node.path;
  }
}

function reduceHandlers(node, parent, resource) {
  parent = parent || [];

  node.handler = node.handler || node.path.substr(1) || [];
  node.handler = Array.isArray(node.handler) ? node.handler : [node.handler];

  if (node.tree) {
    node.tree.forEach(function(route) {
      reduceHandlers(route, parent.concat(node.handler), node._isResource);
    });
  }

  if (!resource) {
    var _handler = parent.slice();
    var _offset = _handler.indexOf(node.handler[0]);

    if (_offset > -1) {
      _handler.splice(_offset);
    }

    node.handler = _handler.concat(node.handler);
  }
}

module.exports = {
  typeOf: typeOf,
  ucfirst: ucfirst,
  dasherize: dasherize,
  pick: pick,
  omit: omit,
  toArray: toArray,
  mergeProps: mergeProps,
  normalizeRoute: normalizeRoute,
  normalizeHandler: normalizeHandler,
  sortByPriority: sortByPriority,
  reduceResources: reduceResources,
  reduceHandlers: reduceHandlers
};
