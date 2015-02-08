
class rgeo_select2_to_session
  constructor: (@search_reults_collection=RGEO.search_results)->
    @_type_plugins={}
    @_plugins=[]
  register_type_plugin: (types ,handler)->
    unless types instanceof  Array
      types=[types]
    for type in types
      @_type_plugins[type]?=[]
      @_type_plugins[type].push handler
  register_plugin:(handler)->
    @_plugins.push handler
  update_from_ids: (id_list, other_args...)->
    curs=@search_reults_collection.find({_id:{$in:id_list}})
    docs=curs.fetch().sort (a,b)->
        id_list.indexOf(a._id)-id_list.indexOf(b._id)
    plugin_assignments=docs.reduce (previous,current)->
        if current.type?
          previous[current.type]?=[]
          previous[current.type].push current
        else
          previous._no_type?=[]
          previous._no_type.push current
        previous
      ,
        {}
    for type,val of plugin_assignments
      if @_type_plugins[type]? 
        @_type_plugins[type].forEach (f)->
          f val, other_args...
      else if @_type_plugins._fallback
        @_type_plugins[_fallback].forEach (f)->
            f val, other_args...
      @_type_plugins._any?.forEach (f)->
        f val, other_args...
    for plugin in @_plugins
      plugin docs, other_args...



    
RGEO.select2_to_session= new rgeo_select2_to_session()

do(reg = RGEO.select2_to_session)->
  mkid = (id,prop)-> "rgeo_box_#{id}_#{prop}"
  Meteor.startup ()->
  for key of Session.keys
    cmp= "rgeo_box_#{id}"
    if key[0...cmp.length] == cmp
      Session.set(key,null)
  reg.register_plugin (search_results, s2_id)->
    categorized=search_results.reduce (p, cur)->
        [type,subtypes...]=cur.type.split(':')
        switch type
          when "address"
            p.addresses.push cur
          when "waypoint"
            p.addresses.push cur
          when "contact"
            p.contacts.push cur
            p.c_n_c.push cur
          when "customer"
            p.customers.push cur
            p.c_n_c.push cur
        return p
      , 
        addresses:[]
        c_n_c:[]
        contacts:[]
        customers:[]
    do (addresses=categorized.addresses)->
        if addresses[0]? 
          Session.set (mkid s2_id,'from'), addresses[0]._id
          if addresses.length>1
            Session.set (mkid s2_id,'dest'),addresses[addresses.length-1]._id
            if addresses.length>2 
              via=addresses[1..-2].reduce (p,c)-> 
                  if p
                    p+= ",#{c._id}"
                  else
                    p=c._id

                ,
                  ""
              Session.set (mkid s2_id,'via'), via
            else
              Session.set (mkid s2_id,'via'),undefined
          else
            Session.set (mkid s2_id,'via'),undefined
            Session.set (mkid s2_id,'dest'),undefined
        else
          Session.set (mkid s2_id,'via'),undefined
          Session.set (mkid s2_id,'dest'),undefined
          Session.set (mkid s2_id,'from'),undefined
        get = (key)->  Session.get(mkid s2_id,key)
        Session.set (mkid s2_id,"vias"), _.pluck(addresses, '_id').join(",")
    do(c_n_c=categorized.c_n_c) ->   
        Session.set (mkid s2_id, 'sender'),c_n_c[0]?._id
        Session.set (mkid s2_id, 'receiver'), c_n_c[1]?._id
        Session.set (mkid s2_id, 'contacts_and_customers'), _.pluck(c_n_c,'_id')?.join(',')
  get_id=(x)->x._id 
  reg.register_type_plugin "customer", (customers,select2_id)->
      Session.set mkid(select2_id, "customers"), customers.map(get_id).join ","
  reg.register_type_plugin ["address", "address:ref"], (addresses,select2_id)->
      Session.set mkid(select2_id, "addresses"), addresses.map(get_id).join ","
  reg.register_type_plugin ["vehicle" , "vehicle:ref"],(vehicles,select2_id)->
      Session.set mkid(select2_id, "vehicles"), vehicles.map(get_id).join ","
  reg.register_type_plugin "contact", (contacts,select2_id)->
      Session.set mkid(select2_id, "contacts"), contacts.map(get_id).join ","
  reg.register_type_plugin "route", (routes,select2_id)->
      Session.set mkid(select2_id, "route"), routes.map(get_id).join ","
  reg.register_type_plugin "waypoint", (waypoints,select2_id)->
      Session.set mkid(select2_id, "waypoints"), waypoints.map(get_id).join ","
  


