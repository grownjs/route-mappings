RouteMapper = require('../lib')

describe 'RouteMapper()', ->
  it 'should work as defined', ->
    routeMapper = RouteMapper()
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

    _ = routeMapper.mappings

    omit = (obj, keys, target = {}) ->
      target[k] = v for k, v of obj when keys.indexOf(k) is -1
      target

    expect(omit(_.root, ['url'])).toEqual { handler: 'Home#index', path: '/', verb: 'get', as: 'root' }
    expect(omit(_.login, ['url'])).toEqual { to: 'Session#create', as: 'login', path: '/login', verb: 'post', as: 'login' }
    expect(omit(_.logout, ['url'])).toEqual { to: 'Session#destroy', as: 'logout', path: '/logout', verb: 'delete', as: 'logout' }

    expect(omit(_.reset, ['url'])).toEqual {
      to: 'Sessions#resetCreate'
      as: 'reset'
      path: '/resetPassword'
      verb: 'post'
    }

    expect(omit(_.InstallationManager.reset, ['url'])).toEqual {
      to: 'Sessions#resetCreate'
      as: 'InstallationManager.reset'
      path: '/InstallationManager/resetPassword'
      verb: 'post'
      handler: ['InstallationManager']
    }

    expect(_.Users.path).toEqual '/Users'
    expect(_.Branches.new.path).toEqual '/Branches/new'
    expect(_.Branches.edit.path).toEqual '/Branches/:id/edit'

    expect(_.InstallationManager.Installations.destroy.path).toEqual '/InstallationManager/Installations/:id'
    expect(_.InstallationManager.Installations.edit.url(123)).toEqual '/InstallationManager/Installations/123/edit'
    expect(_.InstallationManager.Installations.edit.handler).toEqual ['InstallationManager', 'Installations', 'edit']

    expect(_.InstallationManager.Installations.Dependencies.edit.path).toEqual '/InstallationManager/Installations/:installation_id/Dependencies/:id/edit'
    expect(_.InstallationManager.Installations.Dependencies.edit.url(1, 2)).toEqual '/InstallationManager/Installations/1/Dependencies/2/edit'

    # routeMapper.routes.forEach (route) ->
    #   toHandler = if route.to
    #     route.to.split('#')
    #   else
    #     []

    #   handler = route.handler or []
    #   handler.push(toHandler...) if toHandler

    #   console.log "#{route.verb.toUpperCase()}     ".substr(0, 8) + route.path + '  ' + handler.join('.') + ' <' + route.as + '>'
