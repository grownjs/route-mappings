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
      routes.push(route.verb.toUpperCase() + ' ' + (fixedPath.join('') || '/') + ' -> ' + route.handler);
    }
  });

  return routes;
}

module.exports = {
  compileRoutes: compileRoutes,
  compileMappings: compileMappings
};
