
RGEO.search_requests= new Meteor.Collection('geocoding_requests')
RGEO.search_results= new Meteor.Collection('geocoding_results')


ET.registries.link_graphs.default.register_link_field('geocoding_results','.')
ET.register_collection RGEO.search_results
ET.register_collection RGEO.search_requests


RGEO.result_transformer = (doc)->
  # obsolete as rendering is now done with templates
  #see https://www.usps.com/send/official-abbreviations.htm for normalising the street names
  #ex 14 Banatului
  #strada nicolae balcescu
  rendered=null
  chunks=[]
  chunks.push doc.streetNumber if doc.streetNumber
  chunks.push doc.streetName if doc.streetName
  if chunks.length
    rendered= chunks.join ' '
    chunks=[]
  chunks.push doc.city if doc.city
  chunks.push doc.stateCode if doc.stateCode
  chunks.push doc.state if not doc.stateCode and doc.state
  chunks.push doc.zipcode if doc.zipcode
  if chunks.length
    if rendered
      rendered=[rendered, chunks.join ' '].join(',')
    else
      rendered= chunks.join ' '
    chunks=[]
  chunks.push doc.countryCode if doc.countryCode
  chunks.push doc.country if not doc.countryCode and doc.country
  if chunks.length
    if rendered
      rendered=[rendered, chunks.join ' '].join(',')
    else
      rendered= chunks.join ' '
    chunks=[]
  doc.text=rendered
  doc.id=doc._id
  return doc
