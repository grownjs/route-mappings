var util = require('./util');

// TODO: implements these methods
function compileMappings() {
  var mappings = {};

  return mappings;
}

function compileRoutes(tree, currentPath) {
  var routes = [];

  tree.forEach(function(route) {
    var fixedPath = route.path !== '/' ? currentPath.concat(route.path) : currentPath;

    if (route.tree) {
      compileRoutes(route.tree, fixedPath).forEach(function(route) {
        routes.push(route);
      });
    } else {
      var fixedRoute = util.omit(route, ['tree']);

      fixedRoute.path = fixedPath.join('') || '/';

      routes.push(fixedRoute);
    }
  });

  return routes;
}

module.exports = {
  compileRoutes: compileRoutes,
  compileMappings: compileMappings
};
