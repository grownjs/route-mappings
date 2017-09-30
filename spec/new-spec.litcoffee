
    routeMappings = require('../lib')

    describe 'routeMappings()', ->
      it 'is a function', ->
        expect(typeof routeMappings).toEqual 'function'

      describe 'DSL', ->
        it 'responds to #namespace', ->
          expect(->
            routeMappings()
              .namespace '/Test'
          ).not.toThrow()

        it 'responds to #resources', ->
          expect(->
            routeMappings()
              .resources '/Test'
          ).not.toThrow()

        it 'responds to #resource', ->
          expect(->
            routeMappings()
              .resource '/Test'
          ).not.toThrow()

        it 'responds to #get #put #post #patch #delete', ->
          expect(->
            routeMappings()
              .get '/Test'
              .put '/Test'
              .post '/Test'
              .patch '/Test'
              .delete '/Test'
          ).not.toThrow()

        it 'returns as tree', ->
          expect(-> routeMappings().tree).not.toThrow()

        it 'returns as routes', ->
          expect(-> routeMappings().routes).not.toThrow()

        it 'returns as mappings', ->
          expect(-> routeMappings().mappings).not.toThrow()

        it 'can declare mixed routes', ->
          $ = routeMappings()
            .get '/'
            .namespace '/', (routeMappings) ->
              routeMappings()
                .get '/login'
                .post '/login'
                .delete '/logout'
            .namespace '/Admin', (routeMappings) ->
              routeMappings()
                .resource '/CMS'
                .resource '/Cats'
                .resources '/Posts', (routeMappings) ->
                  routeMappings()
                    .resources '/Comments', as: 'Admin.Comments'
                    .namespace '/Assets', (routeMappings) ->
                      routeMappings()
                        .resources '/Images', as: 'Admin.Images'

          m = $.mappings

          expect(-> m('x.y')).toThrow()
          expect(m('login.url')).toEqual '/login'
          expect(m('login.path')).toEqual '/login'
          expect(m('login.handler')).toEqual ['login']

          expect(-> routeMappings().get('/', ->)).toThrow()

          # all resources are singular
          expect(m.Admin.Posts.resource).toEqual 'Post'
          expect(m.Admin.Cats.show.resource).toEqual 'Cat'
          expect(m.Admin.Images.destroy.resource).toEqual 'Post.Image'
          expect(m.Admin.Images.destroy.path).toEqual '/admin/posts/:post_id/assets/images/:id'

        it 'precompile routes as matchers', ->
          $ = routeMappings()
            .get('/')
            .get('/a')
            .get('/b')
            .get('/:one')
            .get('/*two')
            .get('/a/:b')
            .get('/a/:b/:c')
            .get('/a/*extra')

          m = $.map()

          expect(m().length).toEqual 8

        it 'will match on depth and priority', ->
          $ = routeMappings()
            .get('/*a')
            .get('/*a?')
            .get('/x/*y')
            .get('/*x/*y/*z')
            .get('/:a')
            .get('/a')

          m = $.map()

          b = m('/a', 1)
          c = m('/a')[0]

          expect(b).toEqual c

          expect(m('/', 1).path).toEqual '/*a?'
          expect(m('/b', 1).path).toEqual '/:a'
          expect(m('/a/b', 1).path).toEqual '/*a'
          expect(m('/x/y', 1).path).toEqual '/x/*y'

          expect(m('/a/b/c', 1).path).toEqual '/*x/*y/*z'
          expect(m('/x/y/z', 1).path).toEqual '/x/*y'

        it 'will store parent relationships', ->
          $ = routeMappings()
            .get '/'
            .namespace '/admin', ->
              routeMappings()
                .get '/:page'
                .namespace '/db', ->
                  routeMappings()
                    .resources '/users'

          expect($.mappings.admin.db.users.edit.keypath).toEqual [
            'admin.db',
            'admin.db.users',
          ]

        it 'can set custom placeholders', ->
          $ = routeMappings(placeholder: 'foo')
            .resources('/Example', { only: ['edit'] })
            .mappings

          expect($.Example.edit.path).toEqual '/example/:foo/edit'
