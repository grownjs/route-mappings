RouteMapper = require('../lib')

omit = (obj, keys, target = {}) ->
  target[k] = v for k, v of obj when keys.indexOf(k) is -1
  target

describe 'RouteMapper()', ->
  beforeEach ->
    @routeMapper = RouteMapper()
      .get('/', 'Home#index')
      .get('/login', { to: 'Session#new', as: 'login' })
      .post('/login', { to: 'Session#create', as: 'login' })
      .delete('/logout', { to: 'Session#destroy', as: 'logout' })

      .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
      .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
      .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })

      .resources([
        '/Users'
        '/Branches'
      ])

      .namespace('/InstallationManager', ->
        return RouteMapper()
          .get('/', 'Home#index')
          .get('/login', { to: 'Sessions#new' })
          .post('/login', { to: 'Sessions#create' })
          .delete('/logout', { to: 'Sessions#destroy' })

          .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
          .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
          .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })

          .resources('/Users')
          .resources('/Installations',
            RouteMapper()
              .resources('/Dependencies'))
      )

    @urlFor = @routeMapper.mappings

  it 'should mount / as root', ->
    expect(omit(@urlFor.root, ['url'])).toEqual { handler: ['Home#index'], path: '/', verb: 'get', as: 'root' }

  it 'should mount /login as login', ->
    expect(omit(@urlFor.login, ['url'])).toEqual { handler: [], to: 'Session#create', as: 'login', path: '/login', verb: 'post', as: 'login' }

  it 'should mount /logout as logout', ->
    expect(omit(@urlFor.logout, ['url'])).toEqual { handler: [], to: 'Session#destroy', as: 'logout', path: '/logout', verb: 'delete', as: 'logout' }

  it 'should mount /resetPassword as reset', ->
    expect(omit(@urlFor.reset, ['url'])).toEqual {
      to: 'Sessions#resetCreate'
      as: 'reset'
      path: '/resetPassword'
      verb: 'post'
      handler: []
    }

  it 'should mount /resetPassword as InstallationManager.reset', ->
    expect(omit(@urlFor.InstallationManager.reset, ['url'])).toEqual {
      to: 'Sessions#resetCreate'
      as: 'InstallationManager.reset'
      path: '/InstallationManager/resetPassword'
      verb: 'post'
      handler: ['InstallationManager']
    }

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

  # it 'should provide all route info within .routes', ->
  #   @routeMapper.routes.forEach (route) ->
  #     toHandler = if route.to
  #       route.to.split('#')
  #     else
  #       []

  #     handler = route.handler or []
  #     handler.push(toHandler...) if toHandler
  #     handler.push(route.action) if route.action

  #     console.log "#{route.verb.toUpperCase()}     ".substr(0, 8) + route.path + '  ' + handler.join('.') + ' <' + route.as + '>'
