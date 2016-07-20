{ ucfirst, pick, omit, toArray, normalizeRoute, normalizeHandler } = require('../../lib/util')

dummyState =
  # required for path normalization
  PARAMS_PATTERN: /[:*](\w+)/g

describe 'util.js', ->
  describe 'ucfirst()', ->
    it 'should convert the first character into uppercase', ->
      # invalid strings
      expect(-> ucfirst()).toThrow()

      expect(ucfirst('foo')).toEqual 'Foo'

  describe 'pick()', ->
    it 'should pick only given keys from an object', ->
      # invalid types
      expect(-> pick()).toThrow()
      expect(-> pick(-1)).toThrow()
      expect(-> pick({}, NaN)).toThrow()

      expect(pick({ x: 'y', a: 'b' }, ['x'])).toEqual { x: 'y' }

  describe 'omit()', ->
    it 'should omit only given keys from an object', ->
      # invalid types
      expect(-> omit()).toThrow()
      expect(-> omit(-1)).toThrow()
      expect(-> omit({}, NaN)).toThrow()

      expect(omit({ x: 'y', a: 'b' }, ['x'])).toEqual { a: 'b' }

  describe 'toArray()', ->
    it 'should normalize a given value as array', ->
      expect(toArray()).toEqual []
      expect(toArray({})).toEqual [{}]
      expect(toArray(-1)).toEqual [-1]
      expect(toArray(false)).toEqual [false]
      expect(toArray(undefined)).toEqual []

  describe 'normalizeRoute()', ->
    it 'should normalize a given path with regexp', ->
      # bad usage
      expect(-> normalizeRoute()).toThrow()
      expect(-> normalizeRoute(/x/, NaN)).toThrow()

      # correct one
      expect(normalizeRoute(dummyState.PARAMS_PATTERN, '/x/:y')).toEqual 'x'

  describe 'normalizeHandler()', ->
    it 'should normalize given arguments as a valid handler', ->
      # invalid routes
      expect(-> normalizeHandler()).toThrow()
      expect(-> normalizeHandler('', dummyState)).toThrow()
      expect(-> normalizeHandler('/x/', dummyState)).toThrow()
      expect(-> normalizeHandler('/x//y', dummyState)).toThrow()

      # valid ones
      expect(normalizeHandler('/', dummyState)).toEqual { handler: [] }
      expect(normalizeHandler('/x', dummyState)).toEqual { handler: ['x'] }
      expect(normalizeHandler('/', dummyState, 'y')).toEqual { handler: ['y'], _resourceName: 'y' }
