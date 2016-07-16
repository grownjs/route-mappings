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
    expect(@urlFor.index?.path).toEqual '/'
    expect(@urlFor.index?.verb).toEqual 'get'
    expect(@urlFor.index?.handler).toEqual ['index']
    expect(@urlFor.index?.as).toEqual 'index'
    expect(@urlFor.index?.url?()).toEqual '/'

  it 'should mount /Home as `Home` => /home', ->
    expect(@urlFor.Home).not.toBeUndefined()
    expect(@urlFor.Home?.path).toEqual '/home'
    expect(@urlFor.Home?.verb).toEqual 'get'
    expect(@urlFor.Home?.handler).toEqual ['Home']
    expect(@urlFor.Home?.as).toEqual 'Home'
    expect(@urlFor.Home?.url?()).toEqual '/home'

  it 'should mount /Other/Route as `Other.Route` => /other/route', ->
    expect(@urlFor.Other?.Route?.handler).toEqual ['Other', 'Route']
    expect(@urlFor.Other?.Route?.path).toEqual '/other/route'

  it 'should mount /Other/Resource as `Other.Resource` => /other/resource', ->
    expect(@urlFor.Other?.Resource?.handler).toEqual ['Other', 'Resource', 'index']
    expect(@urlFor.Other?.Resource?.path).toEqual '/other/resource'

  it 'should mount /Other/SubNamespace as `Other.SubNamespace` => /other/sub-namespace', ->
    expect(@urlFor.Other?.SubNamespace?.Test?.handler).toEqual ['Other', 'SubNamespace', 'Test']
    expect(@urlFor.Other?.SubNamespace?.Test?.path).toEqual '/other/sub-namespace/test'

  it 'should mount /Top as `Top` => /top', ->
    expect(@urlFor.Top?.handler).toEqual ['Top', 'index']
    expect(@urlFor.Top?.path).toEqual '/top'

  it 'should mount /Top/Sub as `Top.Sub` => /top/sub', ->
    expect(@urlFor.Top?.Sub?.handler).toEqual ['Top', 'Sub']
    expect(@urlFor.Top?.Sub?.path).toEqual '/top/sub'

  it 'should mount /Top/Nested as `Top.Nested` => /top/:top_id/nested', ->
    expect(@urlFor.Top?.Nested?.handler).toEqual ['Top', 'Nested', 'index']
    expect(@urlFor.Top?.Nested?.path).toEqual '/top/:top_id/nested'

  it 'should mount /Top/DeepNested/Subsub as `Top.DeepNested.Subsub` => /top/deep-nested/subsub', ->
    expect(@urlFor.Top?.DeepNested?.Subsub?.handler).toEqual ['Top', 'DeepNested', 'Subsub']
    expect(@urlFor.Top?.DeepNested?.Subsub?.path).toEqual '/top/deep-nested/subsub'

  it 'should mount /Top/DeepNested/Deepest as `Top.DeepNested.Deepest` => /top/deep-nested/deepest', ->
    expect(@urlFor.Top?.DeepNested?.Deepest?.edit?.handler).toEqual ['Top', 'DeepNested', 'Deepest', 'edit']
    expect(@urlFor.Top?.DeepNested?.Deepest?.edit?.path).toEqual '/top/deep-nested/deepest/:id/edit'
