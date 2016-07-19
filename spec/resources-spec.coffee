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

  it 'should mount nested resources using a custom name through `as` option (/X => anythingElse)', ->
    $ = routeMappings().resources('/X', { as: 'anythingElse' }).mappings#

    expect($.anythingElse.path).toEqual '/x'
    expect($.anythingElse.handler).toEqual ['anythingElse', 'index']

  it 'should mount aliased handlers under resources through `as` option (/x/y => anythingElse)', ->
    $ = routeMappings().resources('/X', { as: 'anythingElse' }, (routeMappings) ->
      routeMappings().get('/y')).mappings

    expect($.anythingElse.path).toEqual '/x'
    expect($.anythingElse.handler).toEqual ['anythingElse', 'index']

    expect($.anythingElse.y.path).toEqual '/x/y'
    expect($.anythingElse.y.handler).toEqual ['anythingElse', 'y']

  it 'should support aliased handlers under resources too (/x/y => anythingElse.OSOM)', ->
    $ = routeMappings().resources('/X', { as: 'anythingElse' }, (routeMappings) ->
      routeMappings().get('/y', { as: 'OSOM' })).mappings

    expect($.anythingElse.path).toEqual '/x'
    expect($.anythingElse.handler).toEqual ['anythingElse', 'index']

    expect($.anythingElse.OSOM.path).toEqual '/x/y'
    expect($.anythingElse.OSOM.handler).toEqual ['anythingElse', 'OSOM']

  it 'should support aliased resources under resources too (/x/y => anythingElse.OSOM)', ->
    $ = routeMappings().resources('/X', { as: 'anythingElse' }, (routeMappings) ->
      routeMappings().resources('/Y', { as: 'OSOM' })).mappings

    expect($.anythingElse.path).toEqual '/x'
    expect($.anythingElse.handler).toEqual ['anythingElse', 'index']

    expect($.OSOM.path).toEqual '/x/:x_id/y'
    expect($.OSOM.handler).toEqual ['OSOM', 'index']
