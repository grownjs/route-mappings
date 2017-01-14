routeMappings = require('../lib')

describe 'routeMappings()', ->
  it 'should map single routes (/ => root)', ->
    $ = routeMappings().get('/').mappings

    expect($.root.path).toEqual '/'
    expect($.root.handler).toEqual []

  it 'should map aliases through `as` (/x => anythingElse)', ->
    $ = routeMappings().get('/x', { as: 'anythingElse' }).mappings

    expect($.anythingElse.path).toEqual '/x'
    expect($.anythingElse.handler).toEqual ['anythingElse']

  it 'should support mixed nesting', ->
    $ = routeMappings()
      .namespace '/Admin', (mappings) ->
        mappings()
          .resources '/CMS', (mappings) ->
            mappings()
              .resources '/Pages', (mappings) ->
                mappings()
                  .namespace '/Sections', (mappings) ->
                    mappings()
                      .resources '/Posts', (mappings) ->
                        mappings()
                          .post '/:id/x',
                            as: 'x'

    expect($.mappings.Admin.CMS.edit.path).toEqual '/admin/cms/:id/edit'
    expect($.mappings.Admin.CMS.Pages.edit.path).toEqual '/admin/cms/:cms_id/pages/:id/edit'
    expect($.mappings.Admin.CMS.Pages.Sections.Posts.x.path).toEqual '/admin/cms/:cms_id/pages/sections/posts/:id/x'
    expect($.mappings.Admin.CMS.Pages.Sections.Posts.edit.path).toEqual '/admin/cms/:cms_id/pages/sections/posts/:id/edit'

  it 'should normalize slugs and handler names', ->
    $ = routeMappings().get('/foo-bar').mappings

    expect($.fooBar).not.toBeUndefined()
    expect($.fooBar.handler).toEqual ['fooBar']
