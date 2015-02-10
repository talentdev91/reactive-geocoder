
#Meteor.startup ->
RGEO.OSRM.router= new RGEO.OSRM.OSRMClient Meteor.settings.OSRM_Server
console.log "OSRM server settings" , Meteor.settings.OSRM_Server

RGEO.search_requests.before.insert (userId, doc)->
  
  #console.error 'searching with doc:', JSON.stringify doc
  if doc.ids
    unless _.isArray doc.ids
      doc.links= [doc.links]
    for link in doc.links
      try
        RGEO.search_results.insert _.extend {},link,
          search_ids:[doc.id]
          provider:"LOCALID"
      catch e
        console.error("Error while trying to resolve link" , JSON.stringify(link,null,2))
   
  if doc.term?

    db_results=SSS.search doc, (result_doc)->
      [type,subtype]=result_doc.type.split(':')
      switch
        when type of collections.collection_to_type_mapper
          result_doc.type= [collections.collection_to_type_mapper[type], subtype].filter((x)->x).join(":")
      result_doc.search_ids= [doc._id]
      result_doc.provider= 'LOCAL'
      RGEO.search_results.insert result_doc
      console.log "result doc" , result_doc
      return result_doc
    console.log JSON.stringify db_results, null, 2
    if doc.term.length >=3 and  ((not doc.search_types?) or 'address' in doc.search_types)
      RGEO.node_geocoder.geocode doc.term, Meteor.bindEnvironment (err, results)->
        if err
          console.error "Error while searching for '#{doc.term}' with provider '#{RGEO.geocoder_settings.provider}'"
        else
          for res in results
            res._id=RGEO.search_results.insert _.extend {search_ids:[doc._id],type:'address:new', provider: 'google' },
              draft:_.extend(_.omit(res,['longitude', 'latitude']),
                  type:"address"
                  loc:[res.latitude,res.longitude])
          #TODO: Remove this
          return true 
          if doc.current_selection? and doc.current_selection.length
            #console.log 'current selection is', doc.current_selection
            cur=RGEO.search_results.find
              _id:
                $in:doc.current_selection
            route_points=cur.map (current_selection_doc)->
              [type, subtypes...]=current_selection_doc.type.split ":"
              if type in  ['address', 'waypoint']
                res = (ET.maybe_resolve current_selection_doc)
                unless res?
                  console.error "Could not resolve address", JSON.stringify(current_selection_doc,null,2)
                return res.obj.loc 
              return null 
            route_points=route_points.filter (x)->x?
            for res in results
              arg=[route_points..., [res.latitude,res.longitude]]
              #console.error('viaroute', arg)
              route=RGEO.OSRM.router.viaroute( arg)
              if route?.data
                RGEO.search_results.update {_id:res._id} , 
                  $set:
                    route: route.data
            




  #for collection in 

