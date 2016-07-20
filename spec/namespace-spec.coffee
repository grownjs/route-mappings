routeMappings = require('../lib')

describe 'namespace()', ->
  it 'should map single routes (/ => root)', ->
    $ = routeMappings()
      .namespace('/', (routeMappings) -> routeMappings().get('/')).mappings

    expect($.root.path).toEqual '/'
    expect($.root.handler).toEqual []

  it 'should map nested routes (/ => /Admin)', ->
    $ = routeMappings()
      .namespace('/', (routeMappings) -> routeMappings().get('/Admin')).mappings

    expect($.Admin.path).toEqual '/admin'
    expect($.Admin.handler).toEqual ['Admin']

  it 'should map nested routes (/Admin => /)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) -> routeMappings().get('/')).mappings

    expect($.Admin.path).toEqual '/admin'
    expect($.Admin.handler).toEqual ['Admin']

  it 'should mad nested routes (/Admin => /Settings)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) -> routeMappings().get('/Settings')).mappings

    expect($.Admin.Settings.path).toEqual '/admin/settings'
    expect($.Admin.Settings.handler).toEqual ['Admin', 'Settings']

  it 'should mount nested resources (/Admin => /Users)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) -> routeMappings().resources('/Users')).mappings

    expect($.Admin.Users.path).toEqual '/admin/users'
    expect($.Admin.Users.handler).toEqual ['Admin', 'Users', 'index']

  it 'should mount nested namespaces (/Section => /Subsection)', ->
    $ = routeMappings()
      .namespace('/Section', (routeMappings) ->
        routeMappings().namespace('/Subsection', (routeMappings) -> routeMappings().get('/'))
      ).mappings

    expect($.Section.Subsection.path).toEqual '/section/subsection'
    expect($.Section.Subsection.handler).toEqual ['Section', 'Subsection']

  it 'should mount nested resources within namespaces (/Admin => /Pages => /Comments)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) ->
        routeMappings().resources('/Pages', (routeMappings) -> routeMappings().resources('/Comments'))
      ).mappings

    expect($.Admin.Pages.Comments.edit.path).toEqual '/admin/pages/:page_id/comments/:id/edit'
    expect($.Admin.Pages.Comments.edit.handler).toEqual ['Admin', 'Pages', 'Comments', 'edit']

  it 'should mount aliased handlers under namespaces through `as` option (/x/y => anythingElse)', ->
    $ = routeMappings().namespace('/x', { as: 'anythingElse' }, (routeMappings) ->
      routeMappings().get('/y')).mappings

    # namespaces are not handlers
    expect($.anythingElse.path).toBeUndefined()
    expect($.anythingElse.handler).toBeUndefined()

    expect($.anythingElse.y.path).toEqual '/x/y'
    expect($.anythingElse.y.handler).toEqual ['anythingElse', 'y']

  it 'should support aliased handlers under namespaces too (/x/y => anythingElse.OSOM)', ->
    $ = routeMappings().namespace('/x', { as: 'anythingElse' }, (routeMappings) ->
      routeMappings().get('/y', { as: 'OSOM' })).mappings

    # namespaces are not handlers
    expect($.anythingElse.path).toBeUndefined()
    expect($.anythingElse.handler).toBeUndefined()

    expect($.anythingElse.OSOM.path).toEqual '/x/y'
    expect($.anythingElse.OSOM.handler).toEqual ['anythingElse', 'OSOM']

  it 'should mount aliased resources at root, namespaces are nested (/X/Y/Z => Foo => Bar => Baz => Foo/Buzz)', ->
    $ = routeMappings()
      .namespace('/X', { as: 'Foo' }, (routeMappings) ->
        routeMappings()
          .get('/')
          .resources('/Y', { as: 'Bar' }, (routeMappings) ->
            routeMappings().resources('/Z', { as: 'Baz' }))
          .namespace('/A', { as: 'Buzz' }, (routeMappings) -> routeMappings().get('/'))
      ).mappings

    # these resources are placed at root
    expect($.Foo.path).toEqual '/x'
    expect($.Foo.handler).toEqual ['Foo']

    expect($.Bar.path).toEqual '/x/y'
    expect($.Bar.handler).toEqual ['Bar', 'index']

    expect($.Baz.path).toEqual '/x/y/:y_id/z'
    expect($.Baz.handler).toEqual ['Baz', 'index']

    # this namespace is nested properly
    expect($.Foo.Buzz.path).toEqual '/x/a'
    expect($.Foo.Buzz.handler).toEqual ['Foo', 'Buzz']
