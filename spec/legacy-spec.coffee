RouteMapper = require('../lib')

describe 'RouteMapper()', ->
  beforeEach ->
    @routeMapper = RouteMapper({ use: ['app'] })
      .get('/', { to: 'Home#index', as: 'root' })
      # on `mappings` this is overriden by the later `login` route
      .get('/login', { to: 'Session#new', x: 'y' })
      .post('/login', { to: 'Session#create' })
      .delete('/logout', { to: 'Session#destroy', use: ['quit'] })

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
          .resources('/Editions', { a: 'b', use: ['other'], as: 'Editions' })
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
          .resources('/Installations', { as: 'Installations' },
            RouteMapper({ use: ['track'] })
              .put('/:a/:b', { as: 'ab' })
              .resources('/Dependencies', { as: 'Dependencies' }))
      )

    @urlFor = @routeMapper.mappings

  it 'should mount / as `root`', ->
    expect(@urlFor.root.handler).toEqual ['root']
    expect(@urlFor.root.path).toEqual '/'
    expect(@urlFor.root.verb).toEqual 'get'
    expect(@urlFor.root.use).toEqual ['app']

    expect(@urlFor.root._resourceName).toEqual 'Home'
    expect(@urlFor.root._actionName).toEqual 'index'
    expect(@urlFor.root._isAction).toBeUndefined()

  it 'should mount /login as `login`', ->
    expect(@urlFor.login.handler).toEqual ['login']
    expect(@urlFor.login.path).toEqual '/login'
    expect(@urlFor.login.verb).toEqual 'post'
    expect(@urlFor.login.use).toEqual ['app']
    expect(@urlFor.login.x).toEqual 'y'

    expect(@urlFor.login._resourceName).toEqual 'Session'
    expect(@urlFor.login._actionName).toEqual 'create'
    expect(@urlFor.login._isAction).toBeUndefined()

  it 'should mount /logout as `logout`', ->
    expect(@urlFor.logout.handler).toEqual ['logout']
    expect(@urlFor.logout.path).toEqual '/logout'
    expect(@urlFor.logout.verb).toEqual 'delete'
    expect(@urlFor.logout.use).toEqual ['app', 'quit']

    expect(@urlFor.logout._resourceName).toEqual 'Session'
    expect(@urlFor.logout._actionName).toEqual 'destroy'
    expect(@urlFor.logout._isAction).toBeUndefined()
    expect(@urlFor.logout.x).toBeUndefined()

  it 'should mount /resetPassword as `reset`', ->
    expect(@urlFor.reset.handler).toEqual ['reset']
    expect(@urlFor.reset.path).toEqual '/reset-password'
    expect(@urlFor.reset.use).toEqual ['app']

    expect(@urlFor.reset._resourceName).toEqual 'Sessions'
    expect(@urlFor.reset._actionName).toEqual 'resetCreate'
    expect(@urlFor.reset._isAction).toBeUndefined()

  it 'should mount /resetPassword as `InstallationManager.reset`', ->
    expect(@urlFor.InstallationManager.reset.handler).toEqual ['InstallationManager', 'reset']
    expect(@urlFor.InstallationManager.reset.path).toEqual '/installation-manager/reset-password'
    expect(@urlFor.InstallationManager.reset.use).toEqual ['app', 'extra']

    expect(@urlFor.InstallationManager.reset._resourceName).toEqual 'Sessions'
    expect(@urlFor.InstallationManager.reset._actionName).toEqual 'resetCreate'
    expect(@urlFor.InstallationManager.reset._isAction).toBeUndefined()

  it 'should mount routes and resources properly', ->
    expect(@urlFor.Documents.path).toEqual '/documents'
    expect(@urlFor.Documents.Section.path).toEqual '/documents/section'
    expect(@urlFor.Editions.path).toEqual '/documents/:document_id/editions'
    expect(@urlFor.InstallationManager.Installations.ab.path).toEqual '/installation-manager/installations/:a/:b'

  it 'should pass data through all mounted routes properly', ->
    # passed factories always inherits
    expect(@urlFor.Users.use).toEqual ['app', 'abc', 'xyz']
    expect(@urlFor.Branches.use).toEqual ['app', 'abc', 'xyz']
    expect(@urlFor.InstallationManager.Users.use).toEqual ['app', 'extra', 'auth']

    # while standalone factories does not
    expect(@urlFor.Documents.use).toEqual ['app']
    expect(@urlFor.Documents.Section.use).toEqual ['sub']
    expect(@urlFor.Editions.use).toEqual ['other']
    expect(@urlFor.Dependencies.use).toEqual ['track']

  it 'should mount /Users and /Branches on its own namespaces', ->
    expect(@urlFor.Users.path).toEqual '/users'
    expect(@urlFor.Branches.new.path).toEqual '/branches/new'
    expect(@urlFor.Branches.show.path).toEqual '/branches/:id'
    expect(@urlFor.Branches.edit.path).toEqual '/branches/:id/edit'

  it 'should mount /Installations within /InstallationManager (namespace > resources)', ->
    expect(@urlFor.Installations.destroy.path).toEqual '/installation-manager/installations/:id'
    expect(@urlFor.Installations.edit.url(123)).toEqual '/installation-manager/installations/123/edit'
    expect(@urlFor.Installations.edit.handler).toEqual ['Installations', 'edit']

    expect(@urlFor.Installations.edit._resourceName).toEqual 'Installations'
    expect(@urlFor.Installations.edit._actionName).toEqual 'edit'

  it 'should mount /Dependencies within /Installations (resources > resources)', ->
    expect(@urlFor.Dependencies.edit.path).toEqual '/installation-manager/installations/:installation_id/dependencies/:id/edit'
    expect(@urlFor.Dependencies.edit.url(1, 2)).toEqual '/installation-manager/installations/1/dependencies/2/edit'

  it 'should provide [Editions] as handler, without nesting (resources > resources)', ->
    expect(@urlFor.Editions.edit.path).toEqual '/documents/:document_id/editions/:id/edit'
    expect(@urlFor.Editions.edit.handler).toEqual ['Editions', 'edit']

  it 'should return all properties from the given object as configuration (simple method)', ->
    expect(@urlFor.login.x).toEqual 'y'

  it 'should return all properties from the given object as configuration (resource method)', ->
    expect(@urlFor.Editions.a).toEqual 'b'

  it 'should provide all route info within .routes', ->
    @routeMapper.routes.forEach (route) ->
      console.log "#{route.verb.toUpperCase()}     ".substr(0, 8) + route.path + '  ' + route.handler.join('.') + ' <' + route.as + '>'
