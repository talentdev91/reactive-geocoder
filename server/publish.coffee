
RGEO.search_results.allow
  update: (userId,doc,fieldNames,modifier)->
    if doc.type=='route:new' and modifier.$set?.type == "route:ref"
      #replaces a route search with a reference
      return true
class RGEO.DependencyRegistry 
  _reg:{}
  get:(name)->
    return @_reg[name]
  set:(name,func)->
    @_reg[name]=func
RGEO.dependency_registry=new RGEO.DependencyRegistry()


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
        res.collection=ET.get_collection_by_name RGEO.geocoding_results
        RGEO.geocoding_results.insert res
  return RGEO.geocoding_results.find({search_id:search_id})
Meteor.publish 'geocoding_requests',  ->
  RGEO.search_requests.find()
Meteor.publish 'geocoding_results', (search_id, options={ dependencies:['route']})->
  if search_id instanceof Array
    had_dependency=false;
    if options?.dependencies
      for depency_name in options.dependencies
        had_dependency=true
        search_id=RGEO.dependency_registry.get(depency_name)?(search_id)
    ret=
      geocoding_results:
        _id:
          $in:search_id 
  else
    ret=
      geocoding_results:
        search_ids: 
          $all:[search_id]
  search_cur=RGEO.search_results.find ret.geocoding_results    
  search_cur.map (x)->
    #console.log JSON.stringify x,null,2
    sel=ET.outer_hull_selectors(x)
    for col_id of sel
      if ret[col_id]?
        if ret[col_id]?._id?.$in? and sel[col_id]?._id?.$in
          ret[col_id]._id.$in.push sel[col_id]._id.$in...
        else
          ret[col_id]=
            $or:[ret[col_id], sel[col_id]]
      else
        ret[col_id]=sel[col_id]
  #console.error JSON.stringify(ret,null,2)
  pub_array=[]
  for col_id,selector of ret
    #console.log  "Publishing Collection with ID: ",col_id, "Selector", selector
    pub_array.push ET.get_collection_by_name(col_id).find(selector)
  return pub_array




    


