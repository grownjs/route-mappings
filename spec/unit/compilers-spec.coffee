{ compileRoutes, compileMappings, compileKeypaths } = require('../../lib/compilers')

dummyState =
  # required for path normalization
  PARAMS_PATTERN: /[:*](\w+)/g

describe 'compilers.js', ->
  describe 'compileRoutes()', ->
    it 'should return a list of flattened routes', ->
      input = [
        { handler: 'root', path: '/' }
        { handler: 'login', path: '/login' }
        { handler: 'logout', path: '/logout' }
        { path: '/admin', tree: [
          { handler: 'admin', path: '/' }
          { path: '/', tree: [
            { path: '/posts', tree: [
              { handler: ['posts', 'index'], path: '/' }
              { handler: ['posts', 'new'], path: '/new' }
              { handler: ['posts', 'show'], path: '/:id' }
              { handler: ['posts', 'edit'], path: '/:id/edit' }
              { path: '/:post_id', tree: [
                { path: '/comments', tree: [
                  { handler: ['comments', 'index'], path: '/' }
                  { handler: ['comments', 'show'], path: '/:id' }
                ] }
              ] }
            ] }
          ] }
        ] }
      ]

      routes = compileRoutes(input, dummyState, [])

      expect(routes[0]).toEqual { handler: 'root', path: '/' }
      expect(routes[1]).toEqual { handler: 'login', path: '/login' }
      expect(routes[2]).toEqual { handler: 'logout', path: '/logout' }
      expect(routes[3]).toEqual { handler: 'admin', path: '/admin' }
      expect(routes[4]).toEqual { handler: ['posts', 'index'], path: '/admin/posts' }
      expect(routes[5]).toEqual { handler: ['posts', 'new'], path: '/admin/posts/new' }
      expect(routes[6]).toEqual { handler: ['posts', 'show'], path: '/admin/posts/:id' }
      expect(routes[7]).toEqual { handler: ['posts', 'edit'], path: '/admin/posts/:id/edit' }
      expect(routes[8]).toEqual { handler: ['comments', 'index'], path: '/admin/posts/:post_id/comments' }
      expect(routes[9]).toEqual { handler: ['comments', 'show'], path: '/admin/posts/:post_id/comments/:id' }


  describe 'compileKeypaths()', ->
    it 'should generated named paths from flattened routes', ->
      input = [
        { handler: ['admin', 'posts', 'index'], path: '/admin/posts' }
        { handler: ['admin', 'posts', 'new'], path: '/admin/posts/new' }
        { handler: ['admin', 'posts', 'show'], path: '/admin/posts/:id' }
        { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit' }
      ]

      paths = compileKeypaths(input, dummyState)

      expect(paths[0]).toEqual { handler: ['admin', 'posts', 'index'], path: '/admin/posts', as: 'admin.posts.index' }
      expect(paths[1]).toEqual { handler: ['admin', 'posts', 'new'], path: '/admin/posts/new', as: 'admin.posts.new' }
      expect(paths[2]).toEqual { handler: ['admin', 'posts', 'show'], path: '/admin/posts/:id', as: 'admin.posts.show' }
      expect(paths[3]).toEqual { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit', as: 'admin.posts.edit' }

  describe 'compileMappings()', ->
    it 'should return a tree of named routes from flattened routes with keypaths', ->
      input = [
        { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit', as: 'admin.posts.edit' }
      ]

      _ = compileMappings(input, dummyState)

      expect(typeof _.admin?.posts?.edit?.url).toEqual 'function'
