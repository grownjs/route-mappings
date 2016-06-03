var pluralize = require('pluralize');

var util = require('./util');

function bindHttpVerbHelper(addRoute, routeMapper, httpVerb) {
  routeMapper[httpVerb] = function(path, params) {
    var fixedRoute = addRoute(path, params);

    fixedRoute.verb = httpVerb;

    return routeMapper;
  };
}

function bindAddRouteHelper(state, method) {
  // named funcion because is never attached to any object
  // see: https://github.com/greduan/js-error-stacks-experiments
  return function addRoute(path, params) {
    params = util.normalizeHandler(path, state, params, method);

    var prefix = params.scope || '';

    var fixedPath = (prefix ? '/' + prefix : '') + (prefix && path === '/' ? '' : path);

    params.path = fixedPath;

    state.TREE.push(params);

    return params;
  };
}

function bindResourcesHelper(state, routeMapper) {
  routeMapper.resources = function() {
    var args = Array.prototype.slice.call(arguments);
    var params = {};
    var factory;

    if (typeof args[args.length - 1] === 'function') {
      factory = args.pop();
    }

    if (util.typeOf(args[args.length - 1]) === 'object') {
      params = args.pop();
    }

    var fixedResources = Array.isArray(args[0]) ? args[0] : args;
    var fixedActions = state.SUPPORTED_ACTIONS;

    // filter out actions by omitting first except-keys
    if (params.except) {
      fixedActions = util.omit(fixedActions, util.toArray(params.except));
    }

    if (params.only) {
      fixedActions = util.pick(fixedActions, util.toArray(params.only));
    }

    // iterate all resources
    fixedResources.forEach(function(resourcePath) {
      if (resourcePath.length < 2) {
        throw new TypeError('expecting a valid path but given `' + resourcePath + '` resource');
      }

      var resourceMapper = routeMapper();

      resourceMapper._isResource = true;

      if (factory) {
        var resourceName = resourcePath.substr(1);
        var fixedKey = state.RESOURCE_KEY.replace(/\W+/g, '');

        // normalize /:resource_id
        fixedKey = state.RESOURCE_KEY.replace(fixedKey,
          pluralize.singular(resourceName.toLowerCase()) + '_' + fixedKey);

        resourceMapper.namespace('/' + fixedKey, {
          handler: factory.namespace ? factory : factory()
        });
      }

      Object.keys(fixedActions).forEach(function(action) {
        // resources are mounted from a new routerMapper instance
        var fixedPath = fixedActions[action].path || '/';
        var fixedMethod = fixedActions[action].verb;

        resourceMapper[fixedMethod](fixedPath, {
          handler: [resourcePath.substr(1), action],
          action: action
        });
      });

      routeMapper.namespace(resourcePath, resourceMapper);
    });

    return routeMapper;
  };
}

function bindNamespaceHelper(addRoute, routeMapper) {
  routeMapper.namespace = function(path, callback) {
    var namespaceMapper;

    if (typeof callback === 'function') {
      namespaceMapper = callback.namespace ? callback : callback();
    } else {
      namespaceMapper = callback;
    }

    if (!namespaceMapper._isResource) {
      namespaceMapper._isNamespace = true;
    }

    addRoute(path, namespaceMapper);

    return routeMapper;
  };
}

module.exports = {
  bindHttpVerbHelper: bindHttpVerbHelper,
  bindAddRouteHelper: bindAddRouteHelper,
  bindResourcesHelper: bindResourcesHelper,
  bindNamespaceHelper: bindNamespaceHelper
};
