'use strict';

const $ = require('./util');

const reSplit = /[^\w_-]/;

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

    /* istanbul ignore else */
    if (typeof cb === 'function' && $.HTTP_VERBS.indexOf(group) > -1) {
      throw new Error(`Expecting 'opts' to be an object, given '${cb}'`);
    }

    opts = $.mergeVars(opts || {}, context);

    /* istanbul ignore else */
    if (opts.to && !handle) {
      handle = opts.to;
    }

    delete opts.to;

    (!Array.isArray(path) && path ? [path] : path)
      .forEach(_path => {
        tree.push({
          cb,
          opts,
          group,
          handler: (handle && handle.split(reSplit))
            || ($.fixedKey(_path) || 'root').split(reSplit),
          path: _path,
        });
      });
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
