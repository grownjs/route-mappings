RouteMapper = require('../../lib')

describe 'RouteMapper()', ->
  it '...', ->
    routeMapper = RouteMapper()
      .get('/', { to: 'Home#index' })
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
        .get('/', { to: 'Home#index' })
        .get('/login', { to: 'Sessions#new' })
        .post('/login', { to: 'Sessions#create' })
        .delete('/logout', { to: 'Sessions#destroy' })

        .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
        .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
        .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })

        .resources([
          '/Users'
          '/Installations'
        ])
    )

    _ = routeMapper.mappings

    expect(_.root).toEqual { to: 'Home#index', path: '/', verb: 'get' }
    expect(_.login).toEqual { to: 'Session#create', as: 'login', path: '/login', verb: 'post' }
    expect(_.logout).toEqual { to: 'Session#destroy', as: 'logout', path: '/logout', verb: 'delete' }
    expect(_.reset).toEqual { to: 'Sessions#resetCreate', as: 'reset', path: '/InstallationManager/resetPassword', verb: 'post', handler: ['InstallationManager'] }

    expect(_.Users.path).toEqual '/Users'
    expect(_.Branches.new.path).toEqual '/Branches/new'
    expect(_.Branches.edit.path).toEqual '/Branches/:id/edit'

    expect(_.InstallationManager.Installations.destroy.path).toEqual '/InstallationManager/Installations/:id'
    expect(_.InstallationManager.Installations.edit.handler).toEqual ['InstallationManager', 'Installations', 'edit']
