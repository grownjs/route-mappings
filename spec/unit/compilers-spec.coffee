{ compileRoutes, compileMappings } = require('../../lib/compilers')

dummyState =
  # required for path normalization
  PARAMS_PATTERN: /:(.+?)/g

describe 'compilers.js', ->
  beforeEach ->
    tree = [
      { handler: 'root', path: '/' }
      { handler: 'login', path: '/login' }
      { handler: 'logout', path: '/logout' }
      { path: '/admin', tree: [
        { handler: 'admin', path: '/' }
        { path: '/', tree: [
          { path: '/posts', tree: [
            { handler: ['posts', 'new'], path: '/new' }
            { handler: ['posts', 'show'], path: '/:id' }
            { handler: ['posts', 'edit'], path: '/:id/edit' },
            { path: '/:post_id', tree: [
              { handler: 'posts', path: '/comments', tree: [
                { handler: ['comments', 'index'], path: '/' }
                { handler: ['comments', 'show'], path: '/:id' }
              ] }
            ] }
          ] }
        ] }
      ] }
    ]

    @state = {}
    @state[k] = v for k, v of dummyState
    @state.TREE = tree

  describe 'compileRoutes()', ->
    it 'should return a list of flattened routes', ->
      expect(compileRoutes(@state, [])).toEqual [
        { handler: 'root', path: '/' }
        { handler: 'login', path: '/login' }
        { handler: 'logout', path: '/logout' }
        { handler: 'admin', path: '/admin' }
        { handler: ['posts', 'new'], path: '/admin/posts/new' }
        { handler: ['posts', 'show'], path: '/admin/posts/:id' }
        { handler: ['posts', 'edit'], path: '/admin/posts/:id/edit' }
        { handler: ['posts', 'comments', 'index'], path: '/admin/posts/:post_id/comments' }
        { handler: ['posts', 'comments', 'show'], path: '/admin/posts/:post_id/comments/:id' }
      ]

  describe 'compileMappings()', ->
    it 'should return a tree of named routes', ->
      expect(compileMappings(@state, [])).toEqual {
        root: { handler: 'root', path: '/' }
        login: { handler: 'login', path: '/login' }
        logout: { handler: 'logout', path: '/logout' }
        admin: { handler: 'admin', path: '/admin' }
        posts: {
          new: { handler: ['posts', 'new'], path: '/admin/posts/new' }
          show: { handler: ['posts', 'show'], path: '/admin/posts/:id' }
          edit: { handler: ['posts', 'edit'], path: '/admin/posts/:id/edit' }
          comments: {
            index: { handler: ['posts', 'comments', 'index'], path: '/admin/posts/:post_id/comments' }
            show: { handler: ['posts', 'comments', 'show'], path: '/admin/posts/:post_id/comments/:id' }
          }
        }
      }
