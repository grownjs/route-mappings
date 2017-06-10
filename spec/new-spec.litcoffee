
    routeMappings = require('../lib')

    describe 'routeMappings()', ->
      it 'is a function', ->
        expect(typeof routeMappings).toEqual 'function'

      describe 'DSL', ->
        it 'responds to #namespace', ->
          expect(->
            routeMappings()
              .namespace('/Test')
          ).not.toThrow()

        it 'responds to #resources', ->
          expect(->
            routeMappings()
              .resources('/Test')
          ).not.toThrow()

        it 'responds to #resource', ->
          expect(->
            routeMappings()
              .resource('/Test')
          ).not.toThrow()

        it 'responds to #get #put #post #patch #delete', ->
          expect(->
            routeMappings()
              .get('/Test')
              .put('/Test')
              .post('/Test')
              .patch('/Test')
              .delete('/Test')
          ).not.toThrow()

        it 'returns as tree', ->
          expect(-> routeMappings().tree).not.toThrow()

        it 'returns as routes', ->
          expect(-> routeMappings().routes).not.toThrow()

        it 'returns as mappings', ->
          expect(-> routeMappings().mappings).not.toThrow()

        it 'can declare mixed routes', ->
          $ = routeMappings()
            .get('/')
            .get('/login')
            .delete('/logout')
            .namespace '/Admin', (routeMappings) ->
              routeMappings()
                .resource('/CMS')
                .resources('/Posts')

          console.log $.routes
