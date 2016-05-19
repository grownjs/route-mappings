{ compileRoutes, compileMappings, compileKeypaths } = require('../../lib/compilers')

dummyState =
  # required for path normalization
  PARAMS_PATTERN: /:(\w+)/g

tree = [
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

fixedTree = [
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

describe 'compilers.js', ->
  describe 'compileRoutes()', ->
    it 'should return a list of flattened routes', ->
      expect(compileRoutes(tree, dummyState, [])).toEqual fixedTree

  # TODO: it works, but fix this...

  # describe 'compileKeypaths()', ->
  #   it '...', ->
  #     console.log compileKeypaths(fixedTree, dummyState)
  #     console.log compileMappings(compileKeypaths(fixedTree, dummyState), dummyState)

  # describe 'compileMappings()', ->
  #   it 'should return a tree of named routes', ->
  #     console.log compileMappings(fixedTree, dummyState)
  #     expect(removeUrls(compileMappings(compileRoutes(@state.TREE, @state, []), @state, []))).toEqual {
  #       root: { handler: 'root', path: '/' }
  #       login: { handler: 'login', path: '/login' }
  #       logout: { handler: 'logout', path: '/logout' }
  #       admin: {
  #         handler: 'admin'
  #         path: '/admin'
  #         posts: {
  #           handler: ['admin', 'posts', 'index']
  #           path: '/admin/posts'
  #           new: { handler: ['admin', 'posts', 'new'], path: '/admin/posts/new' }
  #           show: { handler: ['admin', 'posts', 'show'], path: '/admin/posts/:id' }
  #           edit: { handler: ['admin', 'posts', 'edit'], path: '/admin/posts/:id/edit' }
  #           comments: {
  #             handler: ['admin', 'posts', 'comments', 'index']
  #             path: '/admin/posts/:post_id/comments'
  #             show: { handler: ['admin', 'posts', 'comments', 'show'], path: '/admin/posts/:post_id/comments/:id' }
  #           }
  #         }
  #       }
  #     }
