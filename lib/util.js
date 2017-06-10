'use strict';

const HTTP_VERBS = ['get', 'post', 'put', 'patch', 'delete'];

const SUPPORTED_ACTIONS = {
  resource: {
    new: { method: 'get', path: '/new' },
    create: { method: 'post' },
    show: { method: 'get' },
    edit: { method: 'get', path: '/edit' },
    update: { method: 'put' },
    destroy: { method: 'delete' },
  },
  resources: {
    index: { method: 'get' },
    new: { method: 'get', path: '/new' },
    create: { method: 'post' },
    show: { method: 'get', path: '/:id' },
    edit: { method: 'get', path: '/:id/edit' },
    update: { method: 'put', path: '/:id' },
    destroy: { method: 'delete', path: '/:id' },
  },
};

const reCamelCase = /(\b|[a-z])([A-Z]+)/g;
const reMatchParam = /:(\w+)/g;
const reParams = /:\w+/g;
const reNotWords = /\W+/g;
const reTrimDashes = /^\/|\/$/g;
const reNormalizeDashes = /\/+/g;

const pluralize = require('pluralize');

function ucfirst(value) {
  return value.substr(0, 1).toUpperCase() + value.substr(1);
}

function camelize(value) {
  return value.replace(/\W(\w+)/g, (_, $1) => ucfirst($1));
}

function dasherize(value) {
  return value.toString()
    .replace(reCamelCase, (_, $1, $2) =>
      `${$1 ? `${$1}-` : ''}${$2.toLowerCase()}`);
}

function normalizeKey(str) {
  return str
    .replace(reParams, '')
    .replace(reTrimDashes, '')
    .replace(reNormalizeDashes, '.');
}

function fixedKey(str) {
  return normalizeKey(str)
    || camelize(str).replace(reNotWords, '');
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
    /* istanbul ignore else */
    if (Array.isArray(source[key])) {
      /* istanbul ignore else */
      if (!target[key]) {
        target[key] = [];
      }

      Array.prototype.unshift.apply(target[key], source[key]);
    }

    /* istanbul ignore else */
    if (typeof target[key] === 'undefined') {
      target[key] = source[key];
    }
  });

  return target;
}

function normalizeUrl(path) {
  return function $url(params) {
    let values = arguments.length > 1
      ? Array.prototype.slice.call(arguments)
      : params;

    let isArray = Array.isArray(values);

    /* istanbul ignore else */
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
    /* istanbul ignore else */
    if (parentNode) {
      /* istanbul ignore else */
      if (parentNode.opts.as && item.route.opts.as && item.route.opts.as.indexOf('.') === -1) {
        item.route.opts.as = `${parentNode.opts.as}.${item.route.opts.as}`;
      }

      const offset = parentNode.handler.indexOf(item.route.handler[0]);

      item.route.handler = (offset >= 0
        ? parentNode.handler.slice(0, offset)
        : parentNode.handler).concat(item.route.handler);

      if (parentNode.group === 'resource' || parentNode.group === 'resources') {
        const _resource = dasherize(parentNode.handler[parentNode.handler.length - 1]);

        const _singular = _resource.length > 3
          ? pluralize.singular(_resource)
          : _resource;

        item.route.path = `${parentNode.path}/:${_singular}_id${
          item.route.path !== '/' ? item.route.path : ''
        }`;
      } else {
        item.route.path = `${parentNode.path}${item.route.path}`;
      }
    }

    /* istanbul ignore else */
    if (!item.route.opts.as) {
      item.route.opts.as = item.route.path !== '/'
        ? normalizeKey(item.route.path)
            .split('.')
            .map(camelize)
            .join('.')
        : 'root';
    }

    /* istanbul ignore else */
    if (item.route.group !== 'namespace') {
      const _path = dasherize(item.route.path);

      /* istanbul ignore else */
      if (item.route.group === 'resource' || item.route.group === 'resources') {
        Object.keys(SUPPORTED_ACTIONS[item.route.group]).forEach(key => {
          const value = SUPPORTED_ACTIONS[item.route.group][key];
          const _opts = mergeVars({}, item.route.opts);

          /* istanbul ignore else */
          if (key !== 'index') {
            _opts.as += `.${key}`;
          }

          map.push({
            handler: item.route.handler.map(camelize).concat(key),
            method: value.method.toUpperCase(),
            params: _opts,
            path: `${_path}${value.path || ''}`,
            url: normalizeUrl(`${_path}${value.path || ''}`),
          });
        });
      } else {
        map.push({
          handler: item.route.handler.map(camelize),
          method: item.route.group.toUpperCase(),
          params: item.route.opts,
          path: _path,
          url: normalizeUrl(_path),
        });
      }
    }

    /* istanbul ignore else */
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

      /* istanbul ignore else */
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
    const max = keys.length - 1;

    let i = 0;
    let bag = urlFor;

    for (; i < max; i += 1) {
      /* istanbul ignore else */
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
  setProp,
  mergeVars,
  fixedKey,
  normalizeKey,
  normalizeUrl,
  getRoutes,
  getMappings,
  compileRoutes,
};
