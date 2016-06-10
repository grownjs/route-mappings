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
          { _parentHandler: 'admin', path: '/', tree: [
            { path: '/posts', tree: [
              { handler: ['posts', 'index'], path: '/' }
              { handler: ['posts', 'new'], path: '/new' }
              { handler: ['posts', 'show'], path: '/:id' }
              { handler: ['posts', 'edit'], path: '/:id/edit' }
              { _parentHandler: 'posts', path: '/:post_id', tree: [
                { path: '/comments', tree: [
                  { handler: ['comments', 'index'], path: '/' }
                  { handler: ['comments', 'show'], path: '/:id' }
                ] }
              ] }
            ] }
          ] }
        ] }
      ]

      expect(compileRoutes(input, dummyState, [])).toEqual [
        { handler: 'root', path: '/' }
        { handler: 'login', path: '/login' }
        { handler: 'logout', path: '/logout' }
        { handler: 'admin', path: '/admin' }
        { handler: ['admin', 'posts', 'index'], path: '/admin/posts' }
        { handler: ['admin', 'posts', 'new'], path: '/admin/posts/new' }
        { handler: ['admin', 'posts', 'show'], path: '/admin/posts/:id' }
        { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit' }
        { handler: ['admin', 'posts', 'comments', 'index'], path: '/admin/posts/:post_id/comments' }
        { handler: ['admin', 'posts', 'comments', 'show'], path: '/admin/posts/:post_id/comments/:id' }
      ]

  describe 'compileKeypaths()', ->
    it 'should generated named paths from flattened routes', ->
      input = [
        { handler: ['admin', 'posts', 'index'], path: '/admin/posts' }
        { handler: ['admin', 'posts', 'new'], path: '/admin/posts/new' }
        { handler: ['admin', 'posts', 'show'], path: '/admin/posts/:id' }
        { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit' }
      ]

      expect(compileKeypaths(input, dummyState)).toEqual [
        { handler: ['admin', 'posts', 'index'], path: '/admin/posts', as: 'admin.posts' }
        { handler: ['admin', 'posts', 'new'], path: '/admin/posts/new', as: 'admin.posts.new' }
        { handler: ['admin', 'posts', 'show'], path: '/admin/posts/:id', as: 'admin.posts.show' }
        { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit', as: 'admin.posts.edit' }
      ]

  describe 'compileMappings()', ->
    it 'should return a tree of named routes from flattened routes with keypaths', ->
      input = [
        { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit', as: 'admin.posts.edit' }
      ]

      _ = compileMappings(input, dummyState)

      expect(typeof _.admin?.posts?.edit?.url).toEqual 'function'
