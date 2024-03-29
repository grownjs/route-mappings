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
const reMatchParam = /[:*](\w+)/g;
const reSplit = /[^\w_-]/;

const reParam = /\/?[:*]\w+\??/;
const reParams = /\/?[:*]\w+\??/g;
const reNotWords = /[^\w/_-]+/g;
const reTrimSlashes = /^\/+|\/+$/g;
const reEscapeRegex = /[-[\]/{}()*+?.\\^$|]/g;
const reCapture = /\\([*?])/g;

const pluralize = require('pluralize');

function pick(object, keys) {
  if (typeof object !== 'object') {
    throw new TypeError(`Expecting Object but given '${object}'`);
  }

  if (!Array.isArray(keys)) {
    throw new TypeError(`Expecting Array but given '${keys}'`);
  }

  const copy = {};

  keys.forEach(key => {
    copy[key] = object[key];
  });

  return copy;
}

function omit(object, keys) {
  if (typeof object !== 'object') {
    throw new TypeError(`Expecting Object but given '${object}'`);
  }

  if (!Array.isArray(keys)) {
    throw new TypeError(`Expecting Array but given '${keys}'`);
  }

  const copy = {};

  Object.keys(object).forEach(key => {
    if (keys.indexOf(key) === -1) {
      copy[key] = object[key];
    }
  });

  return copy;
}

function ucfirst(value) {
  return value.substr(0, 1).toUpperCase() + value.substr(1);
}

function camelize(value) {
  return value.replace(/\W(\w+)/g, (_, $1) => ucfirst($1));
}

function dasherize(value) {
  return value.toString()
    .replace(reCamelCase, (_, $1, $2) => `${$1 ? `${$1}-` : ''}${$2.toLowerCase()}`);
}

function fixedKey(str) {
  return str
    .replace(reParams, '')
    .replace(reTrimSlashes, '')
    || camelize(str
      .replace(reNotWords, '')
      .replace(reTrimSlashes, ''));
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

    /* istanbul ignore else */
    if (!reParam.test(path) && isArray) {
      return `${path}${values.join('/')}`;
    }

    return path.replace(reMatchParam, (_, $1) => {
      const value = isArray ? values.shift() : values[$1];
      const result = Array.isArray(value) ? value.join('/') : value;

      return typeof result !== 'undefined' ? result : '';
    });
  };
}

function compileRoutes(tree, context, routeMappings) {
  const nodes = [];

  tree.forEach(route => {
    nodes.push({
      route,
      tree: typeof route.cb === 'function'
        ? route.cb(opts => routeMappings(mergeVars(opts || {}, context))).tree
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

      Object.keys(parentNode.opts).forEach(key => {
        if (!['as', 'placeholder'].includes(key) && typeof item.route.opts[key] === 'undefined') {
          item.route.opts[key] = parentNode.opts[key];
        }
      });

      const offset = parentNode.handler.indexOf(item.route.handler[0]);

      /* istanbul ignore else */
      if (parentNode.path !== '/') {
        item.route.handler = (offset >= 0
          ? parentNode.handler.slice(0, offset)
          : parentNode.handler).concat(item.route.handler);

        if (parentNode.group === 'resource' || parentNode.group === 'resources') {
          const _resource = dasherize(parentNode.handler[parentNode.handler.length - 1]);

          const _singular = _resource.length > 3
            ? pluralize.singular(_resource)
            : _resource;

          const _param = item.route.placeholder
            || parentNode.opts.placeholder
            || `${_singular}_id`;

          item.route.path = `${parentNode.path}/:${_param.toLowerCase()}${item.route.path}`;
          item.route.resource = item.route.resource || parentNode.resource;
        } else {
          item.route.path = `${parentNode.path}${item.route.path !== '/' ? item.route.path : ''}`;
        }

        item.route.keypath = [parentNode.opts.as].concat(item.route.keypath || []);
      }

      /* istanbul ignore else */
      if (parentNode.resource !== item.route.resource) {
        item.route.resource = parentNode.resource
          ? `${parentNode.resource}${item.route.resource
            ? `.${item.route.resource}` : ''}` : item.route.resource;
      }
    }

    /* istanbul ignore else */
    if (!item.route.opts.as) {
      item.route.opts.as = item.route.path !== '/'
        ? fixedKey(item.route.path)
          .split(reSplit)
          .map(camelize)
          .join('.')
        : 'root';
    }

    /* istanbul ignore else */
    if (item.route.group !== 'namespace') {
      const _path = dasherize(item.route.path);

      /* istanbul ignore else */
      if (item.route.group === 'resource' || item.route.group === 'resources') {
        let _actions = mergeVars({}, SUPPORTED_ACTIONS[item.route.group]);

        /* istanbul ignore else */
        if (item.route.opts.except) {
          _actions = omit(_actions, item.route.opts.except);
        }

        /* istanbul ignore else */
        if (item.route.opts.only) {
          _actions = pick(_actions, item.route.opts.only);
        }

        Object.keys(_actions).forEach(key => {
          const value = _actions[key];
          const _opts = mergeVars({}, item.route.opts);

          /* istanbul ignore else */
          if (key !== 'index') {
            _opts.as += `.${key}`;
          }

          let _params = value.path || '';

          /* istanbul ignore else */
          if (item.route.opts.placeholder) {
            // allow custom placeholders
            _params = _params.replace('/:id', `/:${item.route.opts.placeholder}`);
          }

          map.push(mergeVars({
            resource: item.route.resource,
            keypath: (item.route.keypath || []).concat(item.route.opts.as),
            handler: item.route.handler.map(camelize).concat(key),
            verb: value.method.toUpperCase(),
            path: `${_path}${_params}`,
            url: normalizeUrl(`${_path}${_params}`),
          }, _opts));
        });
      } else {
        map.push(mergeVars({
          handler: item.route.handler.map(camelize),
          verb: item.route.group.toUpperCase(),
          path: _path,
          url: normalizeUrl(_path),
        }, item.route.opts));
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
    const keys = route.as.split('.');
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

function sortByPriority(routes) {
  return routes.sort((a, b) => {
    /* istanbul ignore else */
    if (b.matcher.priority === a.matcher.priority) {
      return b.matcher.depth - a.matcher.depth;
    }

    return b.matcher.priority - a.matcher.priority;
  });
}

function compileMatcher(path) {
  const keys = [];
  const matcher = [];

  let length = 0;
  let priority = 0;

  path.split('/').forEach(part => {
    const matches = part.match(reMatchParam);

    /* istanbul ignore else */
    if (matches) {
      const optional = part.substr(-1) === '?' || part.charAt(1) === '_';

      /* istanbul ignore else */
      if (optional) {
        part = part.charAt(1) !== '_'
          ? part.substr(0, part.length - 1)
          : part;
      }

      let template = part
        .replace(reEscapeRegex, '\\$&')
        .replace(reCapture, '$1');

      matches.forEach(fragment => {
        /* istanbul ignore else */
        if (!optional) {
          keys.push(fragment.replace(reNotWords, ''));
        }

        priority += fragment.indexOf('*') === -1 ? 200 : 100;

        template = template.replace(fragment,
          fragment.indexOf('*') === -1
            ? '[^/]+'
            : '.+');
      });

      /* istanbul ignore else */
      if (optional) {
        template = `(?:${template})?`;
        priority *= 0.85;
      } else {
        template = `(${template})`;
      }

      priority += matches.length;
      matcher.push(template);
    } else {
      matcher.push(part);
      priority += part.length * 1000;
    }

    length += 1;
  });

  return {
    keys,
    priority,
    depth: length - 1,
    regex: new RegExp(`^${matcher.join('/')}$`),
  };
}

function bindMatcherHelper(routes) {
  return (path, count) => {
    /* istanbul ignore else */
    if (typeof path === 'undefined') {
      return sortByPriority(routes.map(mapping => {
        mapping.matcher = compileMatcher(mapping.path);
        return mapping;
      }));
    }

    count = typeof count === 'number' ? count : -1;
    path = decodeURIComponent(path);

    const input = path.split('?')[0];
    const depth = input.split('/').length - 1;
    const max = routes.length;
    const found = [];

    /* eslint-disable no-continue */
    for (let i = 0; i < max; i += 1) {
      const mapping = routes[i];

      /* istanbul ignore else */
      if (!mapping.matcher) {
        mapping.matcher = compileMatcher(mapping.path);
      }

      /* istanbul ignore else */
      if (depth < mapping.matcher.depth) {
        continue;
      }

      /* istanbul ignore else */
      if (mapping.path === path) {
        found.push(mapping);
        continue;
      }

      const matches = input.match(mapping.matcher.regex);

      /* istanbul ignore else */
      if (matches) {
        mapping.matcher.values = matches.slice(1)
          .filter(x => typeof x !== 'undefined');
        found.push(mapping);
      }
    }

    /* istanbul ignore else */
    if (found.length > 1) {
      sortByPriority(found);
    }

    /* istanbul ignore else */
    if (count > 1) {
      return found.slice(0, count);
    }

    /* istanbul ignore else */
    if (count === 1) {
      return found[0];
    }

    return found;
  };
}

function RouteMappings(context) {
  /* istanbul ignore else */
  if (!(this instanceof RouteMappings)) {
    return new RouteMappings(context);
  }

  context = context || {};

  const tree = [];

  function add(group, path, opts, cb) {
    let handle;

    /* istanbul ignore else */
    if (typeof opts === 'string') {
      handle = opts;
      opts = cb;
      cb = arguments[4];
    }

    /* istanbul ignore else */
    if (typeof opts === 'function') {
      cb = opts;
      opts = {};
    }

    opts = mergeVars(opts || {}, context);

    /* istanbul ignore else */
    if (typeof cb === 'function' && HTTP_VERBS.indexOf(group) > -1) {
      opts.pipeline = [cb].concat(Array.prototype.slice.call(arguments, 3)).filter(x => x);
      cb = null;
    }

    /* istanbul ignore else */
    if (opts.to && !handle) {
      handle = opts.to;
    }

    const _prefix = opts.prefix;

    delete opts.prefix;
    delete opts.to;

    (!Array.isArray(path) && path ? [path] : path)
      .forEach(_path => {
        /* istanbul ignore else */
        if (_prefix) {
          _path = `${_prefix}${(_path !== '/' && _path) || ''}`;
        }

        tree.push({
          cb,
          group,
          path: _path,
          opts: mergeVars({}, opts),
          handler: (handle && handle.split(reSplit))
            || (fixedKey(_path) || '').split(reSplit).filter(x => x),
          resource: opts.resource || (group === 'resource' || group === 'resources'
            ? pluralize.singular(camelize(_path))
            : undefined),
        });
      });
  }

  ['namespace', 'resources', 'resource'].concat(HTTP_VERBS).forEach(prop => {
    this[prop] = (path, opts, cb) => {
      add(prop, path, opts, cb);
      return this;
    };
  });

  setProp(this, 'map', () => routes => bindMatcherHelper(routes || this.routes));

  function map() {
    return compileRoutes(tree, context, ctx => new RouteMappings(ctx));
  }

  setProp(this, 'tree', () => map());
  setProp(this, 'routes', () => getRoutes(this.tree));
  setProp(this, 'mappings', () => getMappings(this.routes));
}

module.exports = RouteMappings;
