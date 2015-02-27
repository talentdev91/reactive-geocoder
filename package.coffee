Package.describe
  name: 'reactive-geocoder'
  summary: 'Geocoding with node-geocoder, reactive with caching'

Npm.depends
  'node-geocoder': '2.6.0'

Package.on_use (api)->
  both_f=[
    'both/init.coffee'
    "both/collections.coffee"
    "both/collections_access.coffee"

  ]
  server_f=[
    "server/init_geocoder.coffee"
    "server/osrm.coffee.md"
    "server/hooks.coffee"
    "server/publish.coffee"
     "server/routes.coffee.md"
  ]
  client_f=[
    "client/init.coffee"
    "client/searchbox.coffee"
    "client/select2_to_session.coffee"
  ]
  client_jade=[
    "client/searchbox.jade"
  ]

  api.export 'RGEO', ['client','server']
  console.error("registered servervi")

  api.use ['coffeescript', 'less','underscore', 'mquandalle:jade@0.4.1', 'alethes:lodash'], ['client','server']
  api.use ['session','templating', 'simple-schema-search'], 'client'
  ##api.use ['jquery-select2'], ['client','server']
  api.use ['natestrauser:select2@3.5.1','zimme:select2-bootstrap3-css@1.4.1'],  'client'
  api.use ['matb33:collection-hooks','entity-base' , 'entity-renderer' ]
  api.use [ 'http'],'server'

  api.add_files client_jade, 'client'
  api.add_files both_f, ['client','server']
  api.add_files server_f, 'server'
  api.add_files client_f, 'client'
   