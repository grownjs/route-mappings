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
