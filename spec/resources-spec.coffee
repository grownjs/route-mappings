routeMappings = require('../lib')

describe 'resources()', ->
  it 'should mount single routes (/Pages => index)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) -> routeMappings().get('/')).mappings

    expect($.Pages.as).toEqual 'Pages'
    expect($.Pages.path).toEqual '/pages'
    expect($.Pages.handler).toEqual ['Pages', 'index']
    expect($.Pages._isAction).toEqual true
    expect($.Pages._actionName).toEqual 'index'
    expect($.Pages._resourceName).toEqual 'Pages'

  it 'should mount nested routes (/Pages => /)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) ->
        routeMappings().namespace('/', (routeMappings) -> routeMappings().get('/'))
      ).mappings

    expect($.Pages.as).toEqual 'Pages'
    expect($.Pages.path).toEqual '/pages'
    expect($.Pages.handler).toEqual ['Pages', 'index']
    expect($.Pages._isAction).toEqual true
    expect($.Pages._actionName).toEqual 'index'
    expect($.Pages._resourceName).toEqual 'Pages'

  it 'should mount nested routes (/Pages => /Settings)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) ->
        routeMappings().namespace('/', (routeMappings) -> routeMappings().get('/Settings'))
      ).mappings

    expect($.Pages.Settings.as).toEqual 'Pages.Settings'
    expect($.Pages.Settings.path).toEqual '/pages/settings'
    expect($.Pages.Settings.handler).toEqual ['Pages', 'Settings']

  it 'should mount nested routes (/Pages/Settings => /)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) ->
        routeMappings().namespace('/Settings', (routeMappings) -> routeMappings().get('/'))
      ).mappings

    expect($.Pages.Settings.as).toEqual 'Pages.Settings'
    expect($.Pages.Settings.path).toEqual '/pages/settings'
    expect($.Pages.Settings.handler).toEqual ['Pages', 'Settings']

  it 'should mount nested resources (/Pages => /Comments)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) -> routeMappings().resources('/Comments')).mappings

    expect($.Pages.Comments.as).toEqual 'Pages.Comments'
    expect($.Pages.Comments.path).toEqual '/pages/:page_id/comments'
    expect($.Pages.Comments.handler).toEqual ['Pages', 'Comments', 'index']
