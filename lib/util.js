function typeOf(value) {
  var test = Object.prototype.toString.call(value);

  return test.substr(8, test.length - 9).toLowerCase();
}

function ucfirst(value) {
  return value.substr(0, 1).toUpperCase() + value.substr(1);
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
    copy[key] = object[key];
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
      copy[key] = object[key];
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
    .replace(/^\/|\/$/g, '')
    // convert slashes into camelCase
    .replace(/\/\w/g, function($0) {
      return $0.substr(1).toUpperCase();
    });
}

function normalizeHandler(path, state, params) {
  if (typeof path !== 'string') {
    throw new TypeError('expecting String but given `' + path + '`');
  }

  if (path.charAt() !== '/') {
    throw new TypeError('missing leading slash for given path `' + path + '`');
  }

  if (path.length > 1 && path.substr(path.length - 1, 1) === '/') {
    throw new TypeError('unexpected trailing slash for given path `' + path + '`');
  }

  if (path.indexOf('//') > -1) {
    throw new TypeError('unexpected consecutive slashes for given path `' + path + '`');
  }

  if (typeof params === 'undefined') {
    params = { handler: normalizeRoute(state.PARAMS_PATTERN, path) || 'index' };
  }

  if (typeof params !== 'object') {
    params = { handler: params };
  }

  if (Array.isArray(params)) {
    params = { tree: params };
  }

  return params || {};
}

module.exports = {
  typeOf: typeOf,
  ucfirst: ucfirst,
  pick: pick,
  omit: omit,
  toArray: toArray,
  normalizeRoute: normalizeRoute,
  normalizeHandler: normalizeHandler
};
