'use strict';

const HTTP_VERBS = ['get', 'post', 'put', 'patch', 'delete'];

const SUPPORTED_ACTIONS = {
  index: { verb: 'get' },
  create: { verb: 'post' },
  update: { verb: 'put', path: '/:id' },
  patch: { verb: 'patch', path: '/:id' },
  destroy: { verb: 'delete', path: '/:id' },
  new: { verb: 'get', path: '/new' },
  show: { verb: 'get', path: '/:id' },
  edit: { verb: 'get', path: '/:id/edit' }
};

const reCamelCase = /(\b|[a-z])([A-Z]+)/g;
const reMatchParam = /:(\w+)/g;
const reParams = /:\w+/g;
const reTrimDashes = /^\/|\/$/g;
const reNormalizeDashes = /\/+/g;

function ucfirst(value) {
  return value.substr(0, 1).toUpperCase() + value.substr(1);
}

function camelize(value) {
  return value.replace(/\W(\w+)/g, (_, $1) => ucfirst($1))
}

function dasherize(value) {
  return value.toString()
    .replace(reCamelCase, (_, $1, $2) =>
      `${$1 ? `${$1}-` : ''}${$2.toLowerCase()}`);
}

function normalizeKey(str) {
  return camelize(str
    .replace(reParams, '')
    .replace(reTrimDashes, '')
    .replace(reNormalizeDashes, '.'));
}

function setProp(target, name, cb) {
  Object.defineProperty(target, name, {
    configurable: false,
    enumerable: false,
    get: cb,
  });
}

function mergeVars(target, source) {
  Object.keys(source).forEach(key => {
    if (Array.isArray(source[key])) {
      if (!target[key]) {
        target[key] = [];
      }

      Array.prototype.unshift.apply(target[key], source[key]);
    }

    if (typeof target[key] === 'undefined') {
      target[key] = source[key];
    }
  });

  return target;
}

function normalizeUrl(path) {
  return params => {
    let values = arguments.length > 1
      ? Array.prototype.slice.call(arguments)
      : params;

    let isArray = Array.isArray(values);

    if (!isArray && typeof values !== 'object') {
      isArray = true;
      values = [values];
    }

    return path.replace(reMatchParam, (_, $1) =>
      (isArray ? values.shift() : values[$1]));
  };
}

function compileRoutes(tree, context, routeMappings) {
  const nodes = [];

  tree.forEach(route => {
    nodes.push({
      route,
      tree: typeof route.cb === 'function'
        ? route.cb(opts =>
            routeMappings(mergeVars(opts || {}, context))).tree
        : [],
    });
  });

  return nodes;
}

function getRoutes(tree, parentNode) {
  const map = [];

  tree.forEach(item => {
    if (parentNode) {
      if (parentNode.group === 'namespace') {
        item.route.path = [parentNode.path, item.route.path].join('');

        if (item.route.handler.length === 1) {
          item.route.handler = (parentNode.handler || [])
            .concat(item.route.handler);
        }
      }
    }

    if (!item.route.opts.as) {
      item.route.opts.as = item.route.path !== '/'
        ? normalizeKey(item.route.path)
        : 'root';
    }

    const _path = dasherize(item.route.path);

    map.push({
      handler: item.route.handler.map(camelize),
      params: item.route.opts,
      path: _path,
      url: normalizeUrl(_path),
    });

    if (item.tree) {
      Array.prototype.push.apply(map, getRoutes(item.tree, item.route));
    }
  });

  return map;
}

function getMappings(routes) {
  function urlFor(path) {
    try {
      const keys = path.split('.');

      let obj = urlFor;

      while (keys.length) {
        obj = obj[keys.shift()];
      }

      if (typeof obj === 'function') {
        return obj.apply(null, Array.prototype.slice.call(arguments, 1));
      }

      return obj;
    } catch (e) {
      throw new Error(`${path} mapping not found`);
    }
  }

  routes.forEach(route => {
    const keys = route.params.as.split('.');

    let i = 0;
    let bag = urlFor;
    let max = keys.length - 1;

    for (; i < max; i += 1) {
      if (!bag[keys[i]]) {
        bag[keys[i]] = {};
      }

      bag = bag[keys[i]];
    }

    bag[keys[i]] = bag[keys[i]] || {};

    Object.keys(route).forEach(k => {
      bag[keys[i]][k] = route[k];
    });
  });

  return urlFor;
}

module.exports = {
  SUPPORTED_ACTIONS,
  HTTP_VERBS,
  ucfirst,
  camelize,
  dasherize,
  normalizeKey,
  setProp,
  mergeVars,
  normalizeUrl,
  compileRoutes,
  getRoutes,
  getMappings,
};
