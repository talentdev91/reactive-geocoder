
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
  console.error "Search Request:", search_id,options
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
  
  dependents= {}
  pub= this
  top_level_col= 'geosearch_results'
  live_query_handle= search_cur.observeChanges
    added: (id, fields)->
      other_cols= ET.outer_hull_selectors(_.extend {_id:id}, fields)

      for col, sel of other_cols
        for dep_id in sel._id.$in
          unless dependents[col]?[dep_id]?
            dependents[col]?={}
            dependents[col]?[dep_id]?=[id]
            if col==top_level_col
              pub.added(col,dep_id,fields)
            else
              pub.added(col, dep_id, ET.get_collection_by_name(col).findOne(dep_id))
            console.error("added" ,col, dep_id)
          else
            dependents[col][dep_id].push id
    removed:(id)->
      for col,o of dependents
        for dep_id, result_ids of o
          if id in result_ids
            if result_ids.length==1
              console.error("removed" , col, dep_id)
              pub.removed(col,dep_id)
            delete o[dep_id]
          else
            result_ids=result_ids.filter (x)->x!=id
        if _.keys(o).length==0
          delete dependents[col]
    changed:(id, fields)->
      #//TODO: test this!
      other_cols= ET.outer_hull_selectors(_.extend {_id:id}, fields)
      for col, o of dependents
        for dep_id, dep_on_ids of o
          if (id in  dep_on_ids) and not ( other_cols[col]?._id.$in.indexOf(dep_id) >-1 )
            if o[dep_id].length ==1
              delete o[dep_id]
              pub.removed col, dep_id
              console.error("changed->removed" ,col, dep_id)
            else
              o[dep_id]=dep_on_ids.filter (x)->x!=id
        if _.keys(o).length==0
          delete dependents[col]
      for col, sel of other_cols
        for dep_id in sel._id.$in
          unless dependents[col]?[dep_id]?
            dependents[col]?={}
            dependents[col]?[dep_id]?=[id]
            console.error("changed->added" ,col, dep_id)
            if col==top_level_col
              pub.added(col,dep_id,fields)
            else
              pub.added(col, dep_id, ET.get_collection_by_name(col).findOne(dep_id))
          else
            unless id in dependents[col][dep_id]
              dependents[col][dep_id].push id
      pub.changed(id,fields)
  @onStop ->
    live_query_handle.stop()
    console.error "search subscription Stopped"

  return



    


