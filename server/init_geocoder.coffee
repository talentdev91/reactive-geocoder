RGEO.geocoder_settings= _.extend  
    provider:'google'
    http_adapter: 'http'
    extra: {}
  ,
    RGEO.geocoder_settings or {}
do (s=RGEO.geocoder_settings)->
  RGEO.node_geocoder=Npm.require('node-geocoder').getGeocoder s.provider, s.http_adapter, s.extra