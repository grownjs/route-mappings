routeMappings = require('../lib')

describe 'resources()', ->
  it 'should mount single routes (/Pages => index)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) -> routeMappings().get('/')).mappings

    expect($.Pages.path).toEqual '/pages'
    expect($.Pages.handler).toEqual ['Pages', 'index']

  it 'should mount nested routes (/Pages => /)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) ->
        routeMappings().namespace('/', (routeMappings) -> routeMappings().get('/'))
      ).mappings

    expect($.Pages.path).toEqual '/pages'
    expect($.Pages.handler).toEqual ['Pages', 'index']

  it 'should mount nested routes (/Pages => /Settings)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) ->
        routeMappings().namespace('/', (routeMappings) -> routeMappings().get('/Settings'))
      ).mappings

    expect($.Pages.Settings.path).toEqual '/pages/settings'
    expect($.Pages.Settings.handler).toEqual ['Pages', 'Settings']

  it 'should mount nested routes (/Pages/Settings => /)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) ->
        routeMappings().namespace('/Settings', (routeMappings) -> routeMappings().get('/'))
      ).mappings

    expect($.Pages.Settings.path).toEqual '/pages/settings'
    expect($.Pages.Settings.handler).toEqual ['Pages', 'Settings']

  it 'should mount nested resources (/Pages => /Comments)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) -> routeMappings().resources('/Comments')).mappings

    expect($.Pages.Comments.path).toEqual '/pages/:page_id/comments'
    expect($.Pages.Comments.handler).toEqual ['Pages', 'Comments', 'index']

    # nested resources always carry its :parent_id while forming the final path
    expect($.Pages.Comments.edit.path).toEqual '/pages/:page_id/comments/:id/edit'

  it 'should mount nested namespaces within resources (/Pages => /Stats => /Comments)', ->
    $ = routeMappings()
      .resources('/Pages', (routeMappings) ->
        routeMappings().namespace('/Stats', (routeMappings) -> routeMappings().resources('/Comments'))
      ).mappings

    expect($.Pages.Stats.Comments.path).toEqual '/pages/stats/comments'
    expect($.Pages.Stats.Comments.handler).toEqual ['Pages', 'Stats', 'Comments', 'index']

    # nested resources that aren't immediately related will not carry any :parent_id
    expect($.Pages.Stats.Comments.edit.path).toEqual '/pages/stats/comments/:id/edit'
