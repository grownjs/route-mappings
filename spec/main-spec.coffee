routeMappings = require('../lib')

describe 'routeMappings()', ->
  it 'should map single routes (/ => index)', ->
    $ = routeMappings().get('/').mappings

    expect($.index.as).toEqual 'index'
    expect($.index.path).toEqual '/'
    expect($.index.handler).toEqual []
