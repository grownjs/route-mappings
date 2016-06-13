RouteMapper = require('../lib')

omit = (obj, keys, target = {}) ->
  target[k] = v for k, v of obj when keys.indexOf(k) is -1
  target

describe 'RouteMapper()', ->
  beforeEach ->
    @routeMapper = RouteMapper({ use: ['app'] })
      .get('/', 'Home#index')
      .get('/login', { to: 'Session#new', as: 'login', x: 'y' })
      .post('/login', { to: 'Session#create', as: 'login' })
      .delete('/logout', { to: 'Session#destroy', as: 'logout', use: ['quit'] })

      .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
      .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
      .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })

      .resources([
        '/Users'
        '/Branches'
      ], { use: ['abc', 'xyz'] })

      .resources('/Documents', ->
        return RouteMapper()
          .get('/', 'Documents#other')
          .get('/Section', { to: 'Documents#section', use: ['sub'] })
          .resources('/Editions', { a: 'b', use: ['other'] })
      )

      # use inherited routeMapper
      .namespace('/InstallationManager', (routeMapper) ->
        return routeMapper({ use: ['extra'] })
          .get('/', 'Home#index')
          .get('/login', { to: 'Sessions#new' })
          .post('/login', { to: 'Sessions#create' })
          .delete('/logout', { to: 'Sessions#destroy' })

          .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
          .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
          .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })

          .resources('/Users', { use: ['auth'] })
          .resources('/Installations',
            RouteMapper({ use: ['track'] })
              .resources('/Dependencies'))
      )

    @urlFor = @routeMapper.mappings

  it 'should mount / as root', ->
    expect(omit(@urlFor.root, ['url'])).toEqual { handler: ['Home#index'], path: '/', verb: 'get', as: 'root', use: ['app'] }

  it 'should mount /login as login', ->
    expect(omit(@urlFor.login, ['url'])).toEqual { handler: [], to: 'Session#create', as: 'login', path: '/login', verb: 'post', as: 'login', x: 'y', use: ['app'] }

  it 'should mount /logout as logout', ->
    expect(omit(@urlFor.logout, ['url'])).toEqual { handler: [], to: 'Session#destroy', as: 'logout', path: '/logout', verb: 'delete', as: 'logout', use: ['app', 'quit'] }

  it 'should mount /resetPassword as reset', ->
    expect(omit(@urlFor.reset, ['url'])).toEqual {
      to: 'Sessions#resetCreate'
      as: 'reset'
      path: '/resetPassword'
      verb: 'post'
      handler: []
      use: ['app']
    }

  it 'should mount /resetPassword as InstallationManager.reset', ->
    expect(omit(@urlFor.InstallationManager.reset, ['url'])).toEqual {
      to: 'Sessions#resetCreate'
      as: 'InstallationManager.reset'
      path: '/InstallationManager/resetPassword'
      verb: 'post'
      handler: ['InstallationManager']
      use: ['app', 'extra']
    }

  it 'should mount routes and resources properly', ->
    expect(@urlFor.Documents.path).toEqual '/Documents'
    expect(@urlFor.Documents.Section.path).toEqual '/Documents/Section'
    expect(@urlFor.Documents.Editions.path).toEqual '/Documents/:document_id/Editions'

  it 'should pass data through all mounted routes properly', ->
    # passed factories always inherits
    expect(@urlFor.Users.use).toEqual ['app', 'abc', 'xyz']
    expect(@urlFor.Branches.use).toEqual ['app', 'abc', 'xyz']
    expect(@urlFor.InstallationManager.Users.use).toEqual ['app', 'extra', 'auth']

    # while standalone factories does not
    expect(@urlFor.Documents.use).toEqual ['app']
    expect(@urlFor.Documents.Section.use).toEqual ['sub']
    expect(@urlFor.Documents.Editions.use).toEqual ['other']
    expect(@urlFor.InstallationManager.Installations.Dependencies.use).toEqual ['track']

  it 'should mount /Users and /Branches on its own namespaces', ->
    expect(@urlFor.Users.path).toEqual '/Users'
    expect(@urlFor.Branches.new.path).toEqual '/Branches/new'
    expect(@urlFor.Branches.show.path).toEqual '/Branches/:id'
    expect(@urlFor.Branches.edit.path).toEqual '/Branches/:id/edit'

  it 'should mount /Installations within /InstallationManager (namespace > resources)', ->
    expect(@urlFor.InstallationManager.Installations.destroy.path).toEqual '/InstallationManager/Installations/:id'
    expect(@urlFor.InstallationManager.Installations.edit.url(123)).toEqual '/InstallationManager/Installations/123/edit'
    expect(@urlFor.InstallationManager.Installations.edit.handler).toEqual ['InstallationManager', 'Installations']
    expect(@urlFor.InstallationManager.Installations.edit.action).toEqual 'edit'

  it 'should mount /Dependencies within /Installations (resources > resources)', ->
    expect(@urlFor.InstallationManager.Installations.Dependencies.edit.path).toEqual '/InstallationManager/Installations/:installation_id/Dependencies/:id/edit'
    expect(@urlFor.InstallationManager.Installations.Dependencies.edit.url(1, 2)).toEqual '/InstallationManager/Installations/1/Dependencies/2/edit'

  it 'should provide [Editions] as handler, without nesting (resources > resources)', ->
    expect(@urlFor.Documents.Editions.edit.path).toEqual '/Documents/:document_id/Editions/:id/edit'
    expect(@urlFor.Documents.Editions.edit.handler).toEqual ['Editions']
    expect(@urlFor.Documents.Editions.edit.action).toEqual 'edit'

  it 'should return all properties from the given object as configuration (simple method)', ->
    expect(@urlFor.login.x).toEqual 'y'

  it 'should return all properties from the given object as configuration (resource method)', ->
    expect(@urlFor.Documents.Editions.a).toEqual 'b'

  # it 'should provide all route info within .routes', ->
  #   @routeMapper.routes.forEach (route) ->
  #     handler = route.handler or []
  #     handler.push(route.to) if route.to
  #     handler.push(route.action) if route.action

  #     console.log "#{route.verb.toUpperCase()}     ".substr(0, 8) + route.path + '  ' + handler.join('.').replace('#', '.') + ' <' + route.as + '>'
