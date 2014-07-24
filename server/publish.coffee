RGEO.node_geocoder=require('node-geocoder')
RGEO.geocoder_settings= _.extend RGEO.geocoder_settings?{}, 
  provider:'google'
  http_adapter: 'http'
  extra: {}

Meteor.publish 'RGEO-search', (search_request)->
  RGEO.geocoder?= RGEO.node_geocoder RGEO.geocoder_settings.provider,RGEO.geocoder_settings.http_adapter,RGEO.geocoder_settings.extra
  search_id= RGEP.search_request.findOne 
    search_text: search_request
  if search_id? 
    search_id=search_id._id
  unless res
    search_id=RGEO.search_request.insert
      search_text: search_request
  RGEO.geocoder.geocode search_request, (err, res_list)->
    if not err
      for res in res_list
        res.search_id=search_id
        RGEO.geocoding_results.insert res
  return RGEO.geocoding_results.find({search_id:search_id})