# RouteMapper = require('../../lib')

# describe 'RouteMapper()', ->
#   it '...', ->
#     routeMapper = RouteMapper()
#       .get('/', { to: 'Home#index' })
#       .get('/login', { to: 'Session#new', as: 'login' })
#       .post('/login', { to: 'Session#create', as: 'login' })
#       .delete('/logout', { to: 'Session#destroy', as: 'logout' })

#       .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
#       .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
#       .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })

#       .resources([
#         '/Users'
#         '/Branches'
#       ])

#     .namespace('/InstallationManager', ->
#       return RouteMapper()
#         .get('/', { to: 'Home#index' })
#         .get('/login', { to: 'Sessions#new' })
#         .post('/login', { to: 'Sessions#create' })
#         .delete('/logout', { to: 'Sessions#destroy' })

#         .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
#         .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })
#         .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })

#         .resources([
#           '/Users'
#           '/Installations'
#         ])
#     )

#     routeMapper.routes.forEach (route) ->
#      console.log route.verb.toUpperCase() + ' ' + route.path

#     for k, v of routeMapper.mappings
#      console.log '->', k, v.path
