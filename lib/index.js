'use strict';

const $ = require('./util');

function RouteMappings(context) {
  if (!(this instanceof RouteMappings)) {
    return new RouteMappings(context);
  }

  context = context || {};

  const tree = [];

  function add(group, path, opts, cb) {
    let handle;

    if (typeof opts === 'string') {
      handle = opts;
      opts = cb;
      cb = arguments[4];
    }

    if (typeof opts === 'function') {
      cb = opts;
      opts = {};
    }

    opts = $.mergeVars(opts || {}, context);

    // normalize given handler
    const handler = (handle && handle.split('.'))
      || (path !== '/' ? $.normalizeKey(path).split('.') : ['index']);

    tree.push({ handler, group, path, opts, cb });
  }

  // FIXME: pluralize support for many resources vs single resource
  ['namespace', 'resources', 'resource'].concat($.HTTP_VERBS).forEach(prop => {
    this[prop] = function $route(path, opts, cb) {
      add(prop, path, opts, cb);
      return this;
    };
  });

  $.setProp(this, 'tree', () =>
    $.compileRoutes(tree, context, ctx => new RouteMappings(ctx)));

  $.setProp(this, 'routes', () =>
    $.getRoutes($.compileRoutes(tree, context, ctx => new RouteMappings(ctx))));

  $.setProp(this, 'mappings', () =>
    $.getMappings($.getRoutes($.compileRoutes(tree, context, ctx => new RouteMappings(ctx)))));
}

module.exports = RouteMappings;
