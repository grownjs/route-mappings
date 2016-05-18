{ bindHttpVerbHelper, bindAddRouteHelper, bindResourcesHelper, bindNamespaceHelper } = require('../../lib/bindings')

dummyState =
  # required for all tree nodes
  TREE: []
  # required for path normalization
  PARAMS_PATTERN: /:(.+?)/g
  # required for creating all resources
  SUPPORTED_ACTIONS:
    index: { verb: 'get', path: '/' }

quickClone = (obj, target = {}) ->
  target[k] = v for k, v of obj
  target

describe 'bindings.js', ->
  describe 'bindHttpVerbHelper()', ->
    it 'should add .verb to given instance as function', ->
      state = {}
      addRoute = -> state
      routeMapper = {}
      httpVerb = 'get'

      bindHttpVerbHelper(addRoute, routeMapper, httpVerb)

      # update state
      routeMapper.get()

      expect(Object.keys(routeMapper)).toEqual [httpVerb]
      expect(typeof routeMapper[httpVerb]).toEqual 'function'

      expect(state.verb).toEqual 'get'

  describe 'bindAddRouteHelper()', ->
    beforeEach ->
      @state = quickClone(dummyState)
      @addRoute = bindAddRouteHelper(@state)

    it 'should treat / as index', ->
      @addRoute '/'
      expect(@state.TREE[0].handler).toEqual 'index'

  describe 'bindResourcesHelper()', ->
    beforeEach ->
      @state = quickClone(dummyState)

      @routeMapper = => @routeMapper

      # required to by-passing the arguments
      @routeMapper.get = => @state.get = arguments
      @routeMapper.namespace = => @state.ns = arguments

      bindResourcesHelper(@state, @routeMapper)

    it 'should validate the given resource', ->
      expect(=> @routeMapper.resources '/').toThrow()

    it 'should call namespace() for mounting', ->
      @routeMapper.resources '/x'
      expect(@state.ns[0]).toEqual '/x'
      expect(@state.ns[1]).toEqual @routeMapper

    it 'should call get() as SUPPORTED_ACTIONS say', ->
      @routeMapper.resources '/y'
      expect(@state.get[0]).toEqual '/'
      expect(@state.get[1]).toEqual { handler: ['y', 'index'] }

    # TODO: except, only, obj, fn

  describe 'bindNamespaceHelper()', ->
    it '...', ->
      state = {}
      addRoute = -> state = arguments
      routeMapper = {}

      bindNamespaceHelper(addRoute, routeMapper)
      routeMapper.namespace '/z', { tree: [-1] }

      expect(state[0]).toEqual '/z'
      expect(state[1]).toEqual [-1]

    # TODO: fn, fn.namespace
