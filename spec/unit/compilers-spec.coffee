{ compileRoutes } = require('../../lib/compilers')

describe 'compilers.js', ->
  describe 'compileMappings()', ->
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

      expect(compileRoutes(tree, [])).toEqual [
        { path: '/' }
        { path: '/x' }
        { path: '/x/y' }
        { path: '/x/z' }
        { path: '/x/z/:a' }
      ]

      expect(compileRoutes(tree, ['/osom'])).toEqual [
        { path: '/osom' }
        { path: '/osom/x' }
        { path: '/osom/x/y' }
        { path: '/osom/x/z' }
        { path: '/osom/x/z/:a' }
      ]
