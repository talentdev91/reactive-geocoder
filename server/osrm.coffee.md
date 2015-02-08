A Client implementation for the route server

       
    RGEO.OSRM=
      _cache:
        _store:{}
        get:(x)->
          if x instanceof Array
            x=JSON.stringify(x)
          return @_store[x]
        set:(arg, hint)->
          if arg instanceof Array
            [lon,lat,hint_param]=arg
          else if typeof arg == 'string'
            try
              [lon,lat,hint_param]=JSON.parse(arg)
            catch
              console.error("could not parse #{arg} into list")
              return 
          hint?=hint_param
          if hint? and lat? and lon?
            @_store[JSON.stringify([lat, lon])]=hint
            return true
          else 
            return 

    class RGEO.OSRM.OSRMClient
      db_cache_collection=new Meteor.Collection('viaroute_cache')
      _cache:RGEO.OSRM._cache
      _config:
        hostname:'api.wavetheapp.com'
        protocol: 'http'
        port:5000
      _uri:null
      constructor:(url_or_config)->
        if url_or_config?
          switch typeof url_or_config
            when 'object' 
              _.extend @_config,url_or_config
            when 'string' 
              _.extend @_config, URI.parse(url_or_config)
        #console.log "RGEO.OSRM.OSRMClient:  config is #{@_config}"

The viaroute argument accepts the following arguments:
  * waypoints: [[lat,lon,hint:optional], ...]  the lat lon of the waypoints
  * a callback *optional*

the callback, if supplied receives (error, response) which are the same as in
Meteors `HTTP.get` callback, _with the addition_  that response.data is always
populated with the response JSON 

if a callback is not provided this function may throw as in `HTTP.get`
      
      _repair_via_indices: (data)->
        console.log("repairing via_indices")
        data.via_indices= data.via_indices.map (i, addr_idx ) ->
          if addr_idx == 0
            return 0
          else
            return i-1
        console.log "via_indices.length, via_points.length", data.via_indices.length,  data.via_points.length
        unless data.via_indices.length == data.via_points.length
          console.log("correcting via_indices length")
          last=data.via_points[0]
          for via_point, idx in data.via_points[1...]
            if _.isEqual via_point, last
              data.via_indices.splice(idx-1, 0, data.via_indices[idx-1] )
            last=via_point



      viaroute_new:(arg,callback)->
        cached=db_cache_collection.findOne
          args:arg
        if cached? and not cached.error
          callback?(cached.error,cached.result)
          return cached.result
        else
          ret=viaroute_orig
      distance_table:(args,callback)->
        url=URI(@_config).segment(['table'])
        for arg in args
          parm=
            loc:arg.join(',')
          url.addSearch parm
        cb=(error,result)->
          unless error
            unless result.data?
              result.data=JSON.parse(result.content)
            #console.log "calling callback #{callback} with result:", result
            callback?(error,result)
            return result
          else
            console.log "error executing nearest:", error
            return
        return HTTP.get url.toString(), (callback? and cb or undefined)
      nearest: (arg,callback)->
        url=URI(@_config).segment(['nearest'])
        parm=
          loc:arg.join(',')
        url.addSearch parm
        cb=(error,result)->
          unless error
            unless result.data?
              result.data=JSON.parse(result.content)
            #console.log "calling callback #{callback} with result:", result
            callback?(error,result)
            return result
          else
            console.log "error executing nearest:", error
            return
        #console.log "retrieving:", url.toString() , "callback: callback"
        return HTTP.get url.toString(), (callback? and cb or undefined)
      viaroute:(arg, callback)->
        console.log "route arg len:", arg.length
        url= URI(@_config).segment(['viaroute'])
        #console.log " orl= #{url.toString() }viaroute args = #{arg}"
        url=url.toString()
        url = "#{url}?" 
        parms=[]
        for pt in arg
          
          parm=
            loc:pt.join(',')
          unless pt.length ==2
            console.error "ignoring waypoint=#{pt} because it has not both lat, and lon"
            return
          unless parm.hint?
            parm.hint=@_cache.get([parm.lat,parm.lon])
          unless parm_hint?
            delete parm.hint
          parms.push parm
        parms.push
          instructions:true
        parms = parms.map (p)->
          ret = []
          for key,val of p
            ret.push "#{key}=#{val}"
          return ret.join ("&")
        
        url+= parms.join("&")
          #now this returns whatever is returned when callback is provided
          # and the result when no callback argument is given
        #console.log "getting route: #{ url.toString()}"
        cb=(error,result)=>
          unless error
            unless result.data?
              result.data=JSON.parse(result.content)  
            @_repair_via_indices(result.data)
            callback?(error,result)
            console.log('returning result')
            return result
          else
            return 
     
        console.log "getting #{url.toString()}"
        ret= HTTP.get url, (callback? and cb or undefined)
        unless callback
          @_repair_via_indices ret.data
        return ret

    RGEO.OSRM.client = new RGEO.OSRM.OSRMClient()
        






