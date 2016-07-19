{ compileRoutes, compileMappings, compileKeypaths } = require('../../lib/compilers')

dummyState =
  # required for path normalization
  PARAMS_PATTERN: /[:*](\w+)/g

describe 'compilers.js', ->
  describe 'compileRoutes()', ->
    it 'should return a list of flattened routes', ->
      input = [
        { handler: ['root'], path: '/' }
        { handler: ['login'], path: '/login' }
        { handler: ['logout'], path: '/logout' }
        { path: '/admin', tree: [
          { handler: ['admin'], path: '/' }
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

      routes = compileRoutes(input, [])

      expect(routes[0].handler).toEqual ['root']
      expect(routes[0].path).toEqual '/'

      expect(routes[1].handler).toEqual ['login']
      expect(routes[1].path).toEqual '/login'

      expect(routes[2].handler).toEqual ['logout']
      expect(routes[2].path).toEqual '/logout'

      expect(routes[3].handler).toEqual ['admin']
      expect(routes[3].path).toEqual '/admin'

      expect(routes[4].handler).toEqual ['posts', 'index']
      expect(routes[4].path).toEqual '/admin/posts'

      expect(routes[5].handler).toEqual ['posts', 'new']
      expect(routes[5].path).toEqual '/admin/posts/new'

      expect(routes[6].handler).toEqual ['posts', 'show']
      expect(routes[6].path).toEqual '/admin/posts/:id'

      expect(routes[7].handler).toEqual ['posts', 'edit']
      expect(routes[7].path).toEqual '/admin/posts/:id/edit'

      expect(routes[8].handler).toEqual ['comments', 'index']
      expect(routes[8].path).toEqual '/admin/posts/:post_id/comments'

      expect(routes[9].handler).toEqual ['comments', 'show']
      expect(routes[9].path).toEqual '/admin/posts/:post_id/comments/:id'

  describe 'compileMappings()', ->
    it 'should return a tree of named routes from flattened routes with keypaths', ->
      input = [
        { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit', as: 'admin.posts.edit' }
      ]

      _ = compileMappings(input, dummyState)

      expect(typeof _.admin?.posts?.edit?.url).toEqual 'function'
