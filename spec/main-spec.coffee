routeMappings = require('../lib')

describe 'routeMappings()', ->
  beforeEach ->
    @routeMappings = routeMappings()
      .get('/')
      .get('/Home')
      .namespace('/Other', (routeMappings) ->
        return routeMappings()
          .get('/Route')
          .resources('/Resource', { only: 'index' })
          .namespace('/SubNamespace', (routeMappings) ->
            return routeMappings()
              .get('/Test')
          )
      )
      .resources('/Top', { only: 'index' }, (routeMappings) ->
        return routeMappings()
          .get('/Sub')
          .resources('/Nested', { only: 'index' })
          .namespace('/DeepNested', (routeMappings) ->
            return routeMappings()
              .get('/Subsub')
              .resources('/Deepest', { except: 'index' })
          )
      )

    @urlFor = @routeMappings.mappings

  it 'should mount / as `index`', ->
    expect(@urlFor.index).not.toBeUndefined()
    expect(@urlFor.index.path).toEqual '/'
    expect(@urlFor.index.verb).toEqual 'get'
    expect(@urlFor.index.handler).toEqual ['index']
    expect(@urlFor.index.as).toEqual 'index'
    expect(@urlFor.index.url()).toEqual '/'
