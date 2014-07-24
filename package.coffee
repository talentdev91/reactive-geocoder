Package.describe
  name: 'reactive-geocoder'
  summary: 'Geocoding with node-geocoder, reactive with caching'

Npm.depends
  'node-geocoder': '2.6.0'

Package.on_use (api)->
  both_f=[
    "both/collections.coffee"
  ]
  server_f=[
    "server/publish.coffee"
  ]
  client_f=[
    "client/searchbox.coffee"
    "client/searchbox.jade"
  ]

  api.export('RGEO')
  api.use 'templating', 'client'
  api.use ['coffeescript', 'less','underscore'], 'server'
  api.use ['jquery-select2'], ['client','server']
  
  api.add_files both_f, ['client','server']
  api.add_files server_f, 'server'
  api.add_files client_f, 'client'
   