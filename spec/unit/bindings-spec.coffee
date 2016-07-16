{ bindHttpVerbHelper, bindAddRouteHelper, bindResourcesHelper, bindNamespaceHelper, bindMatcherHelper } = require('../../lib/bindings')

dummyState =
  # required for all tree nodes
  TREE: []
  # required for path normalization
  PARAMS_PATTERN: /[:*](\w+)/g
  # required for creating all resources
  SUPPORTED_ACTIONS:
    index: { verb: 'get', path: '/' }
  # required for resources
  RESOURCE_KEY: ':id'

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
      expect(@state.TREE[0].handler).toEqual ['index']

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
      expect(@state.ns[1]._isResource).toBeTruthy()
      expect(@state.ns[1]._resourceKey).toEqual ':x_id'
      expect(@state.ns[1].handler._isResource).toBeTruthy()

    it 'should call get() as SUPPORTED_ACTIONS say', ->
      @routeMapper.resources '/y'
      expect(@state.get[0]).toEqual '/'
      expect(@state.get[1]).toEqual { handler: ['index'], _isAction: true, _actionName: 'index', _resourceName: 'y' }

    # TODO: except, only, obj, fn

  describe 'bindNamespaceHelper()', ->
    it '...', ->
      state = {}
      addRoute = -> state = arguments
      routeMapper = {}

      bindNamespaceHelper(addRoute, routeMapper)
      routeMapper.namespace '/z', { tree: [-1] }

      expect(state[0]).toEqual '/z'
      expect(state[1].tree).toEqual [-1]

    # TODO: fn, fn.namespace

  describe 'bindMatcherHelper()', ->
    it 'should perform basic reverse routing with sorting', ->
      find = bindMatcherHelper dummyState, [
        {
          test: 'Root'
          route: { path: '/' }
        },
        {
          test: 'Param'
          route: { path: '/:id' }
        },
        {
          test: 'Star'
          route: { path: '/*all' }
        }
        {
          test: 'Static'
          route: { path: '/action' }
        }
      ]

      expect(find('')).toEqual []
      expect(find('/')[0].test).toEqual 'Root'
      expect(find('/x')[0].test).toEqual 'Star'
      expect(find('/x')[1].test).toEqual 'Param'
      expect(find('/x')[1].matcher.values).toEqual ['x']

      expect(find('/x/y')[0].test).toEqual 'Star'
      expect(find('/action')[0].test).toEqual 'Static'
      expect(find('/action')[1].test).toEqual 'Star'
      expect(find('/foo/bar')[0].matcher.values).toEqual ['foo/bar']
