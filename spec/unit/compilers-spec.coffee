{ compileRoutes, compileMappings } = require('../../lib/compilers')

dummyState =
  # required for parameterization
  RESOURCE_KEY: ':id'
  # required for path normalization
  PARAMS_PATTERN: /:(.+?)/g

describe 'compilers.js', ->
  describe 'compileMappings()', ->
    it 'should return map of named routes', ->
      tree = [
        { handler: 'x', path: '/' }
        # /x (resource) is mounted on /
        { path: '/y', tree: [
          { handler: ['a', 'y'], path: '/' }
          { handler: ['b', 'y'], path: '/:id' }
          { handler: ['c', 'y'], path: '/y' }
        ] }
      ]

      state = {}
      state[k] = v for k, v of dummyState
      state.TREE = tree

      result = compileMappings(state, [])

      expect(result.root).toEqual { handler: 'x', path: '/' }

  describe 'compileRoutes()', ->
    it 'should return a list of compiled routes', ->
      tree = [
        { path: '/' }
        # /x is mounted on /
        { path: '/x', tree: [
          { path: '/' }
          { path: '/y' }
          # /z is mounted on /x
          { path: '/z', tree: [
            { path: '/' }
            # /:a is mounted on /x/z
            { path: '/:a' }
          ] }
        ] }
      ]

      expect(compileRoutes(TREE: tree, [])).toEqual [
        { path: '/' }
        { path: '/x' }
        { path: '/x/y' }
        { path: '/x/z' }
        { path: '/x/z/:a' }
      ]

      expect(compileRoutes(TREE: tree, ['/osom'])).toEqual [
        { path: '/osom' }
        { path: '/osom/x' }
        { path: '/osom/x/y' }
        { path: '/osom/x/z' }
        { path: '/osom/x/z/:a' }
      ]
