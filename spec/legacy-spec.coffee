RouteMapper = require('../lib')

describe 'RouteMapper()', ->
  beforeEach ->
    @routeMapper = RouteMapper({ use: ['app'] })
      .get('/', { to: 'Home#index', as: 'root' })
      .get('/login', { to: 'Session#new', x: 'y', as: 'showLogin' })
      .post('/login', { to: 'Session#create', p: 'q', as: 'doLogin' })
      .delete('/logout', { to: 'Session#destroy', use: ['quit'], as: 'doLogout' })

      .get('/resetPassword', { to: 'Sessions#resetShow', as: 'showReset' })
      .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'doReset' })
      .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'newReset' })

      .resources([
        '/Users'
        '/Branches'
      ], { use: ['abc', 'xyz'] })

      .resources('/Documents', () ->
        RouteMapper()
          .get('/other', 'Documents#other')
          .get('/Section', { to: 'Documents#section', use: ['sub'] })
          .resources('/Editions', { a: 'b', use: ['other'], as: 'Editions' })
      )

      # use inherited routeMapper
      .namespace('/InstallationManager', () ->
        RouteMapper({ use: ['extra'] })
          .get('/', 'Home#index')

          .get('/login', { to: 'Sessions#new' })
          .post('/login', { to: 'Sessions#create' })
          .delete('/logout', { to: 'Sessions#destroy' })

          .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
          .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
          .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })

          .resources('/Users', { use: ['auth'] })
          .resources('/Installations', { as: 'Installations' }, () ->
            RouteMapper({ use: ['track'] })
              .put('/:a/:b', { as: 'ab' })
              .resources('/Dependencies', { as: 'Dependencies' }))
      )

    @urlFor = @routeMapper.mappings

  it 'should mount / as `root`', ->
    expect(@urlFor.root.handler).toEqual ['Home', 'index']
    expect(@urlFor.root.path).toEqual '/'
    expect(@urlFor.root.verb).toEqual 'GET'
    expect(@urlFor.root.use).toEqual ['app']

  it 'should mount /login as `doLogin`', ->
    expect(@urlFor.doLogin.handler).toEqual ['Session', 'create']
    expect(@urlFor.doLogin.path).toEqual '/login'
    expect(@urlFor.doLogin.verb).toEqual 'POST'
    expect(@urlFor.doLogin.use).toEqual ['app']
    expect(@urlFor.doLogin.p).toEqual 'q'

    expect(@urlFor.showLogin.handler).toEqual ['Session', 'new']
    expect(@urlFor.showLogin.path).toEqual '/login'
    expect(@urlFor.showLogin.verb).toEqual 'GET'
    expect(@urlFor.showLogin.use).toEqual ['app']
    expect(@urlFor.showLogin.x).toEqual 'y'

  it 'should mount /logout as `doLogout`', ->
    expect(@urlFor.doLogout.handler).toEqual ['Session', 'destroy']
    expect(@urlFor.doLogout.path).toEqual '/logout'
    expect(@urlFor.doLogout.verb).toEqual 'DELETE'
    expect(@urlFor.doLogout.use).toEqual ['app', 'quit']
    expect(@urlFor.doLogout.x).toBeUndefined()
    expect(@urlFor.doLogout.p).toBeUndefined()

  it 'should mount /resetPassword as `doReset`', ->
    expect(@urlFor.doReset.handler).toEqual ['Sessions', 'resetUpdate']
    expect(@urlFor.doReset.path).toEqual '/reset-password'
    expect(@urlFor.doReset.use).toEqual ['app']

  it 'should mount /InstallationManager/resetPassword as `InstallationManager.reset`', ->
    expect(@urlFor.InstallationManager.reset.handler).toEqual ['InstallationManager', 'Sessions', 'resetCreate']
    expect(@urlFor.InstallationManager.reset.path).toEqual '/installation-manager/reset-password'
    expect(@urlFor.InstallationManager.reset.use).toEqual ['extra']

  it 'should mount routes and resources properly', ->
    expect(@urlFor.Documents.path).toEqual '/documents'
    expect(@urlFor.Documents.Section.path).toEqual '/documents/:document_id/section'
    expect(@urlFor.Documents.Editions.path).toEqual '/documents/:document_id/editions'
    expect(@urlFor.InstallationManager.Installations.ab.path).toEqual '/installation-manager/installations/:installation_id/:a/:b'

  it 'should pass data through all mounted routes properly', ->
    # passed factories always inherits
    expect(@urlFor.Users.use).toEqual ['app', 'abc', 'xyz']
    expect(@urlFor.Branches.use).toEqual ['app', 'abc', 'xyz']

    # while standalone factories does not
    expect(@urlFor.Documents.use).toEqual ['app']
    expect(@urlFor.Documents.Section.use).toEqual ['sub']
    expect(@urlFor.Documents.Editions.use).toEqual ['other']
    expect(@urlFor.InstallationManager.Users.use).toEqual ['extra', 'auth']
    expect(@urlFor.InstallationManager.Installations.Dependencies.use).toEqual ['track']

  it 'should mount /Users and /Branches on its own namespaces', ->
    expect(@urlFor.Users.path).toEqual '/users'
    expect(@urlFor.Branches.new.path).toEqual '/branches/new'
    expect(@urlFor.Branches.show.path).toEqual '/branches/:id'
    expect(@urlFor.Branches.edit.path).toEqual '/branches/:id/edit'

  it 'should mount /Installations within /InstallationManager (namespace > resources)', ->
    expect(@urlFor.InstallationManager.Installations.destroy.path).toEqual '/installation-manager/installations/:id'
    expect(@urlFor.InstallationManager.Installations.edit.url(123)).toEqual '/installation-manager/installations/123/edit'
    expect(@urlFor.InstallationManager.Installations.edit.handler).toEqual ['InstallationManager', 'Installations', 'edit']

  # FIXME: nested resources should be mounted on the root
  it 'should mount /Dependencies within /Installations (resources > resources)', ->
    expect(@urlFor.InstallationManager.Installations.Dependencies.edit.path).toEqual '/installation-manager/installations/:installation_id/dependencies/:id/edit'
    expect(@urlFor.InstallationManager.Installations.Dependencies.edit.url(1, 2)).toEqual '/installation-manager/installations/1/dependencies/2/edit'

  it 'should provide [Editions] as handler, without nesting (resources > resources)', ->
    expect(@urlFor.Documents.Editions.edit.path).toEqual '/documents/:document_id/editions/:id/edit'
    expect(@urlFor.Documents.Editions.edit.handler).toEqual ['Documents', 'Editions', 'edit']

  it 'should return all properties from the given object as configuration (simple method)', ->
    expect(@urlFor.doLogin.p).toEqual 'q'

  it 'should return all properties from the given object as configuration (resource method)', ->
    expect(@urlFor.Documents.Editions.a).toEqual 'b'
