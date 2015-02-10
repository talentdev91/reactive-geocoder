This package provides the search dependency tracker for routes
and the hooks for creating routes from search results

    RGEO.dependency_registry.set 'route', (search_ids)->
      cur= RGEO.search_results.find
        _id:
          $in:search_ids
        type:
          $regex:'(address|waypoint)(:.*)?'
          $options:'i'
      order=[]
      unless search_ids.length>1
        console.log "search_ids.length is less than 2"
        #nothing to do as there can not be two via points here
        return search_ids
      cur=cur.fetch()
      deref_addresses = cur.map (search_result)->
        order.push search_ids.indexOf(search_result._id)
        ET.maybe_resolve search_result
      #console.log "orig result", deref_addresses
      #console.log "all", RGEO.search_results.find({_id: $in:search_ids}).fetch()
      #console.log "cursor", cur
      #console.log "order", order
      # this is nesessary tyo account for the sparse array
      map_order_values=[order...].sort()
      for i, idx in map_order_values
        order[order.indexOf(i)]=idx
      console.log "reduced order", order
      deref_addresses=deref_addresses.map (o,idx,orig)->
        return orig[order.indexOf(idx)]
      
      deref_addresses=deref_addresses.filter((x)->x?)
      unless deref_addresses.length>1
        console.log "less than 2 addresses found"
        console.log deref_addresses
        #Nothing to do again, no 2 addresses
        return search_ids
      cities=[]
      viaroute_args=deref_addresses.map (addr)->
        cities.push addr.obj.city
        return addr.obj.loc
      console.log "CITY ORDER",cities
      try
        result=RGEO.OSRM.router.viaroute viaroute_args
        #console.log result
        #links=route_selector.recalculate_distance_time (links,instructions,via_indices)
        last_instruction=0;
        links=deref_addresses.map (addr,addr_idx)->
          #console.log JSON.stringify addr, null, 2
          if addr.from_new?
            ret= ET.create_link addr.from_new
          else
            ret= ET.create_link addr.obj 
          #TODO: remove hack when bug is solved https://github.com/Project-OSRM/osrm-backend/issues/1020
          #moved bug report to https://github.com/Project-OSRM/osrm-backend/issues/1145
          ret.geometry_index= result.data.via_indices[addr_idx]
          if result.data.route_instructions
            unless ret.geometry_index == 0
              distance_from_prev=0
              time_from_prev=0
              while last_instruction < result.data.route_instructions.length and result.data.route_instructions[last_instruction][3] <= ret.geometry_index 
                instr=result.data.route_instructions[last_instruction]
                distance_from_prev += instr[2]
                time_from_prev += instr[4]
                last_instruction++
              [ret.distance_from_prev, ret.time_from_prev]=[distance_from_prev,time_from_prev]


          console.log "created link :#{JSON.stringify ret,null,2}"
          return ret
          
        route_id=RGEO.search_results.insert ET.create_new
            type: 'route'
            geometry_enc:result.data.route_geometry
            links:links
            data:result.data
        return [search_ids...,route_id]
      catch e
        console.error "route dependency check failed with error. Returning unmodified search_ids set", e
        return search_ids


        
