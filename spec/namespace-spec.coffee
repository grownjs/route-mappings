routeMappings = require('../lib')

describe 'namespace()', ->
  it 'should map single routes (/ => index)', ->
    $ = routeMappings()
      .namespace('/', (routeMappings) -> routeMappings().get('/')).mappings

    expect($.index.as).toEqual 'index'
    expect($.index.path).toEqual '/'
    expect($.index.handler).toEqual []

  it 'should map nested routes (/ => /Admin)', ->
    $ = routeMappings()
      .namespace('/', (routeMappings) -> routeMappings().get('/Admin')).mappings

    expect($.Admin.as).toEqual 'Admin'
    expect($.Admin.path).toEqual '/admin'
    expect($.Admin.handler).toEqual ['Admin']

  it 'should map nested routes (/Admin => /)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) -> routeMappings().get('/')).mappings

    expect($.Admin.as).toEqual 'Admin'
    expect($.Admin.path).toEqual '/admin'
    expect($.Admin.handler).toEqual ['Admin']

  it 'should mad nested routes (/Admin => /Settings)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) -> routeMappings().get('/Settings')).mappings

    expect($.Admin.Settings.as).toEqual 'Admin.Settings'
    expect($.Admin.Settings.path).toEqual '/admin/settings'
    expect($.Admin.Settings.handler).toEqual ['Admin', 'Settings']

  it 'should mount nested resources (/Admin => /Users)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) -> routeMappings().resources('/Users')).mappings

    expect($.Admin.Users.as).toEqual 'Admin.Users'
    expect($.Admin.Users.path).toEqual '/admin/users'
    expect($.Admin.Users.handler).toEqual ['Admin', 'Users', 'index']

  it 'should mount nested namespaces (/Section => /Subsection)', ->
    $ = routeMappings()
      .namespace('/Section', (routeMappings) ->
        routeMappings().namespace('/Subsection', (routeMappings) -> routeMappings().get('/'))
      ).mappings

    expect($.Section.Subsection.as).toEqual 'Section.Subsection'
    expect($.Section.Subsection.path).toEqual '/section/subsection'
    expect($.Section.Subsection.handler).toEqual ['Section', 'Subsection']

  it 'should mount nested resources within namespaces (/Admin => /Pages => /Comments)', ->
    $ = routeMappings()
      .namespace('/Admin', (routeMappings) ->
        routeMappings().resources('/Pages', (routeMappings) -> routeMappings().resources('/Comments'))
      ).mappings

    expect($.Admin.Pages.Comments.edit.as).toEqual 'Admin.Pages.Comments.edit'
    expect($.Admin.Pages.Comments.edit.path).toEqual '/admin/pages/:page_id/comments/:id/edit'
    expect($.Admin.Pages.Comments.edit.handler).toEqual ['Admin', 'Pages', 'Comments', 'edit']
