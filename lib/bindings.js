var pluralize = require('pluralize');

var util = require('./util'),
    compilers = require('./compilers');

function bindHttpVerbHelper(addRoute, routeMapper, httpVerb) {
  routeMapper[httpVerb] = function(path, params, options) {
    var fixedRoute = addRoute(path, params, options);

    fixedRoute.verb = httpVerb;

    return routeMapper;
  };
}

function bindAddRouteHelper(state, method) {
  // named funcion because is never attached to any object
  // see: https://github.com/greduan/js-error-stacks-experiments
  return function addRoute(path, params, options) {
    params = util.normalizeHandler(path, state, params, method);
    params.path = path;

    // append extra options
    if (options) {
      Object.keys(options).forEach(function(key) {
        params[key] = params[key] || options[key];
      });
    }

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

    // normalize all given params
    var newParams = util.mergeProps(['handler', 'tree', 'except', 'only'], params, {});

    // iterate all resources
    fixedResources.forEach(function(resourcePath) {
      if (resourcePath.length < 2) {
        throw new TypeError('expecting a valid path but given `' + resourcePath + '` resource');
      }

      var resourceMapper = routeMapper(newParams);
      var resourceName = resourcePath.substr(1);

      resourceMapper._isResource = true;

      var fixedKey = state.RESOURCE_KEY.replace(/\W+/g, '');
      var fixedResource = params.as ? params.as.split('.') : [resourceName];

      // normalize /:resource_id
      fixedKey = state.RESOURCE_KEY.replace(fixedKey,
        pluralize.singular(resourceName.toLowerCase()) + '_' + fixedKey);

      // sub routes
      if (factory) {
        resourceMapper.namespace('/', {
          _resourceKey: fixedKey,
          _resourceName: resourceName,
          handler: factory.namespace ? factory : factory(resourceMapper)
        });
      }

      // actions
      var resourceActionsMapper = resourceMapper();

      Object.keys(fixedActions).forEach(function(action) {
        // resources are mounted from a new routerMapper instance
        var fixedPath = fixedActions[action].path || '/';
        var fixedMethod = fixedActions[action].verb;

        resourceActionsMapper[fixedMethod](fixedPath, {
          _isAction: true,
          _actionName: action,
          _resourceName: resourceName,
          handler: fixedResource.concat(action)
        });
      });

      resourceMapper.namespace('/', {
        _isResourceMapper: true,
        handler: resourceActionsMapper
      });

      // mount resource
      routeMapper.namespace(resourcePath, {
        _isResource: true,
        _resourceKey: fixedKey,
        _resourceName: resourceName,
        handler: resourceMapper
      });
    });

    return routeMapper;
  };
}

function bindNamespaceHelper(addRoute, routeMapper) {
  routeMapper.namespace = function(path, callback) {
    var _fixedNamespace = {};
    var namespaceMapper;

    if (typeof arguments[2] === 'function') {
      _fixedNamespace = callback || {};
      callback = arguments[2];
    }

    if (typeof callback === 'function') {
      // passing down the routeMapper instance allows inheritance
      namespaceMapper = callback.namespace ? callback : callback(routeMapper);
    } else {
      namespaceMapper = callback;
    }

    if (!namespaceMapper) {
      throw new Error('Expecting a routeMappings instance but given `' + namespaceMapper + '`');
    }

    if (!namespaceMapper._isResource) {
      _fixedNamespace._isNamespace = true;
    }

    addRoute(path, namespaceMapper, _fixedNamespace);

    return routeMapper;
  };
}

function bindMatcherHelper(state, fixedRoutes) {
  return function(path, count) {
    if (typeof path === 'undefined') {
      return util.sortByPriority(fixedRoutes.map(function(mapping) {
        mapping.matcher = compilers.compileMatcher(mapping.route.path, state);
        return mapping;
      }));
    }

    count = typeof count === 'number' ? count : -1;
    path = decodeURIComponent(path);

    var length = path.split('/').length;
    var found = [];

    for (var i in fixedRoutes) {
      var mapping = fixedRoutes[i];

      if (count !== -1 && (found.length === count)) {
        break;
      }

      if (mapping.route.path === path) {
        found.push(mapping);
        break;
      }

      if (!mapping.matcher) {
        mapping.matcher = compilers.compileMatcher(mapping.route.path, state);
      }

      if (length < mapping.matcher.length) {
        continue;
      }

      var matches = path.split('?')[0].match(mapping.matcher.regex);

      if (matches) {
        mapping.matcher.values = (matches || []).slice(1);
        found.push(mapping);
      }
    }

    if (found.length > 1) {
      util.sortByPriority(found);
    }

    if (count === 1) {
      return found[0];
    }

    return found;
  };
}

module.exports = {
  bindMatcherHelper: bindMatcherHelper,
  bindHttpVerbHelper: bindHttpVerbHelper,
  bindAddRouteHelper: bindAddRouteHelper,
  bindResourcesHelper: bindResourcesHelper,
  bindNamespaceHelper: bindNamespaceHelper
};
