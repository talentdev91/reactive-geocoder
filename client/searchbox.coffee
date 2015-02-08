root=this
mkid=(id, prop)->
    "rgeo_box_#{id}_#{prop}"
missing_route_addresses=(kw)->
  kw=kw?.hash
  i=2
  if Session.get mkid @id,'from'
    i--
  if Session.get mkid @id,'dest'
    i--

  if i>1
    if kw?.number_only
      "#{i}"
    else
      "#{i} addresses"
  else if i>0
    if kw?.number_only
      "one"
    else
      "one address"
  else
    null
missing_route_contacts=(kw)->
  kw=kw?.hash
  i=2
  if Session.get mkid @id,'sender'
    i--
  if Session.get mkid @id,'receiver'
    i--
  if i>1
    if kw?.number_only
      "#{i}"
    else
      "#{i} contacts"
  else if i>0
    if kw?.number_only
      "one"
    else
      "one contact"
  else
    null
missing_route_vehicle=(kw)->
  veh=Session.get mkid @id, 'vehicles'
  veh?=""
  veh=veh.split(',').filter (x)->x!=''
  kw=kw?.hash
  unless veh.length
    if kw?.number_only
      return 'one'
    else
      return 'one truck'
  return null   

do (box=Template.geo_search_box,route_action_box=Template.rgeo_route_action_box) ->
  
  global_timed_query= {}
  box.helpers
    has_input_group_addon_or_btn:->
      ret= _.any [
        Blaze._globalHelpers.hasRegion('addon-before')
        Blaze._globalHelpers.hasRegion('addon-after')
        Blaze._globalHelpers.hasRegion('btn-before')
        Blaze._globalHelpers.hasRegion('btn-after')
        
        
      ]
      debugger
      return ret
    #  debugger 
    id: -> 
      this.id?='geo_search_box'
    container_id:->
      @container_id="#{box.id.apply(@)}_container"

    default_options: 
      show_add_field:true
      placeholder: "Enter Search"
      minimumInputLength: 1
      maximumSelectionSize: 25
      initSelection: (element,callback)->
        view= Blaze.getView(element[0])
        while view and not view.templateInstance
          view=view.parentView
        initial_values= view?.templateInstance().options?.value
        debugger
        callback element.select2('val').map (id)->
          ret= initial_values?.filter (x)-> x.link_id==id or x._id==id
          if ret?[0]
            return _.extend {id: ret[0].link_id or ret[0]._id }, ret[0]
          else
            return {id: id}
        return
      formatSelection: (object,container)->
        template_arg=
           obj: RGEO.search_results.findOne(object.id) or object
           one_line_editor:true
        template_arg.obj.collection= 'geocoding_results'
        #UI.insert UI.renderWithData(Template.render_entity, template_arg), container[0]
        Blaze.renderWithData Template.render_entity, template_arg, container[0]
        return
 
      createSearchChoice: (term)->
        return  {
              id:'add'
              disabled:true
              type:'op_add'
            }   
      multiple:true
      quietMillis: 3000 
      formatResult: (object,container,query)->
        template_arg=
          obj: RGEO.search_results.findOne(object.id) or object
          term:query.term
          editable:false
        #UI.insert UI.renderWithData(Template.render_entity,template_arg), container[0]
        Blaze.renderWithData Template.render_entity, template_arg,container[0]
        return
      query: (query)->
        tmpl_instance= Blaze.getView(this.element[0])
        while tmpl_instance and not tmpl_instance.templateInstance?
          tmpl_instance=tmpl_instance.parentView
        tmpl_instance=tmpl_instance?.templateInstance()

        debugger
        my_id=@element.attr 'id'
        console.log 'QUERY CALLED context=' ,query
        i=1
        if query.context?
          console.log "received a requery call with query: ", query
          query.context.continuation_callback=query.callback
          query.context.subscription.computation.invalidate()
          return
        else
          q= 
            term: query.term
            current_selection: @element.select2('val')
          if tmpl_instance?.options?.search_types?

            q.search_types= tmpl_instance.options.search_types
           
          query.context=
            first_run:true
            continuation_callback:null
            
            
            selection_opts:
              limit:10
              skip:0
              transform:(doc)->
                {id:doc._id}
            query:query
          ##dampens the query
          delay= -> 
            query.context.search_id= RGEO.search_requests.insert q
            query.context.timer= null
            query.context.selection=
              search_ids:
                $all:[query.context.search_id]
          
          
          
          
            RGEO.subscriptions[my_id]?=[]
            #RGEO.subscriptions[my_id].stop()
            
            subscription=
              sub:Meteor.subscribe 'geocoding_results', query.context.search_id
              id:query.context.search_id
              term:query.term
              computation: null
              cursor:null
            subscription.computation= Deps.autorun (computation)->
                do(ctx=query.context) ->
                  #subscription.cursor=cur=RGEO.search_results.find(ctx.selection, ctx.selection_opts)
                  
                  subscription.cursor=cur=RGEO.search_results.find(ctx.selection, ctx.selection_opts)
                  res=cur.fetch()
                  if res.length
                    if ctx.first_run or ctx.continuation_callback
                      cb_object=
                        results:cur.fetch()
                        context:ctx
                        more:true
                      ctx.selection_opts.skip+=res.length
                      if ctx.continuation_callback
                        console.log "QUERY.CONTINUATION_CALLBACK CALLED with #{query.term}, search_id=#{ctx.search_id} obj=" ,cb_object
                        
                        cb=ctx.continuation_callback
                        ctx.continuation_callback=null
                        cb cb_object
            
                      else if ctx.first_run
                        ctx.first_run=false
                        query.callback cb_object
                        console.log "QUERY.CALLBACK CALLED with #{query.term}, search_id=#{ctx.search_id} obj=" ,cb_object
                    else
                      console.log "Dependency update but no query from select2"
                  else
                    console.log "Continuation request but no data"
            
                    
                   
            my_subscriptions=RGEO.subscriptions[my_id]
            my_subscriptions.push subscription
            RGEO.subscriptions.close_all_except(my_id,my_subscriptions[my_subscriptions.length-1])
            query.context.subscription = subscription
            search_choice = query.element
            ###
            This last callback is needed in order to supply a search choice if one is provided.
            ###
          query.callback
            context: query.context
            results:[]
            more:true
          if global_timed_query.timer?
            clearTimeout(global_timed_query.timer)
          global_timed_query.timer= _.delay(delay,500)
    testentries: ->
      ["Entry1", "Entry2", "Entry3", "Entry4"]
    show_explain_box: (my_id) ->
      if @never_show_explain_box
        return false
      res=Session.get mkid my_id,"show_explain_box"
      if res
        return res
      else
        return false
  box.created = ->
    direct_tmpl_options= [
      'search_types'
      'createSearchChoice'
    ]

    @options = _.extend   {}, box.default_options, _.pick(@data, direct_tmpl_options), @data.options or {}
    console.log "maximum selection size: #{@options.maximumSelectionSize}"
    if @options.search_types? and  _.isString @options.search_types
       @options.search_types =  @options.search_types.split(',')

  box.rendered = ->
    console.error("called rendered on" ,@firstNode)
    debugger
    if @data.xeditable
      content=$(@find('.editable-content'))
      editable_opts=
        type:'select2'
        emptytext:content.html()
        select2:@options
        #display val from https://github.com/vitalets/x-editable/issues/431
        success: (empty_response,newValue)->
          unless arguments.length==2
            #bootstrap safeguard
            return
          debugger
          options= content.data('editable').options.select2  
          if _.isArray newValue
            options.set_callback( newValue.map (x)-> RGEO.search_results.findOne(x))
          else
            options.set_callback(RGEO.search_results.findOne(x))
          #for val in newValue
          #  options.formatSelection({id:val},content)
          #content.data.html('')
          # hack because x-editable does not allow us to change the field
          #Meteor.setTimeout ->
          #  content.data('editable').hide()
          return false
      if @options.title
        editable_opts.title= @options.title
      
      content.editable editable_opts

    else


      sel2_elm=@$(@firstNode).find('input')
      sel2_elm.select2(@options)    
      
      ###
        Section for getting the value as a list
        either from @data.value or from @options.value
      ###

      @options.value?=[]
      unless _.isArray(@options.value)
        @options.value= [@options.value]
      if @data.value
        if _.isArray @data.value
          @options.value.push @data.value...
        else 
          @options.value.push @data.value
      delete @options.value unless @options.value.length
      if @options.value?
        sel2_elm.select2 'val', @options.value.map (link_or_obj)->
          link_or_obj?.link_id or link_or_obj?._id
      if @options.change_callback?
        options=@options
        resolve = (id )->
          result=RGEO.search_results.findOne(id)
          if result?
            result=_.omit(result, ['collection', '_id'])
          else
            result= options?.value?.filter (x)->'link_id'== id 
            result= result?[0]
          unless result 
            err= "unknown id #{id} trying to resolve the select2 value"
            console.error err, arguments[0]
            throw Error(err)
          return result
        sel2_elm.on 'change', (e) ->
          if e.added
            e.added = resolve(e.added.id)
          if e.removed
            e.removed= resolve(e.removed)
          options.change_callback.call this,e 
      q=sel2_elm.parent().find('ul.select2-choices')
      q.sortable
        containment: 'parent' 
        start: -> 
          sel2_elm.select2 "onSortStart"
        update: ->
          sel2_elm.select2 "onSortEnd"
      sel2_elm.change (e,data=e)=>
        s2_id = e.target.id
        RGEO.select2_to_session.update_from_ids(data.val, s2_id)
        unsubscribe=null
        my_id=@data.id
        if RGEO.selection_subscription[my_id]
          unsubscribe=RGEO.selection_subscription[my_id]
          delete RGEO.selection_subscription[my_id]
        if data.val.length
          RGEO.selection_subscription[my_id]=Meteor.subscribe 'geocoding_results',data.val
        if unsubscribe?
          unsubscribe.stop()
      

        true
      sel2_elm.on 'select2-close', (e)=>
        e.removed_search_ids=RGEO.subscriptions.close_all(@data.id)
        true
      ## Event and initial state for the show_ex
      btn=@$(@firstNode).find('.show_explain_box_btn')
      key=mkid @data.id,'show_explain_box'
      btn.toggleClass 'active', Session.equals key, true
      btn.click (event)=>
        val = not Session.get key
        Session.set key,val
        btn.toggleClass 'active' , val
        true
  
  
  route_action_box.created = ->
    #initialize container
    route_action_box.container.apply(@data)
    @data.search_box= "das"
  route_action_box.helpers

    id: ->
      @id
    container:->
      unless @container
        jq=$("##{@id}_container")
        @container= jq if jq.length
      @container
    select2:->
      @select2?=route_action_box.container.apply(this)?.find('.select2:first')?.data('select2')

    changed: (field, search_box)->
      sess_id=mkid(search_box, "#{field}")
      return not Session.equals(sess_id, @[field])
    
    extract: (field, search_box, kw)->
      sess_id=mkid(search_box, "#{field}")
      @[field]=Session.get(sess_id)
      if @[field]
        field_list=@[field].split ","
        console.log("setting field #{field} to #{@[field]}")
        if kw.hash.one
          ret=RGEO.search_results.findOne({_id:{$in:field_list}})
        else
          ret = RGEO.search_results.find({_id:{$in:field_list}}).fetch()
          ret = ret.sort (a,b)->
            field_list.indexOf(b)-field_list.indexOf(a)
      else 
        ret=false
      return ret
    is_complete:->
      #something_missing= (missing_route_vehicle.apply this) or (missing_route_addresses.apply this) or (missing_route_contacts.apply this)
      something_missing= missing_route_addresses.apply this
      unless something_missing
        console.log "Route complete", missing_route_addresses.apply this
      #else
        #console.log "Route incomplete",missing_route_vehicle.apply this , missing_route_addresses.apply this , missing_route_contacts.apply this
      return not something_missing
    actions: ->
      unless route_action_box.is_complete.apply this
        return [
            description: "Check badges in titlebar for mising items.This route cannot be added input is missing."
            class: "add disabled"
            icon_classes: "fa fa-plus"
          ]
      else
        return [
            description: "Add this route to the database"
            class: "add"
            icon_classes: "fa fa-plus"
          ]
    debug: ->
      debugger
  route_action_box.events
    'click button.add': (evt)->
      search_box=$(evt.target).data('search-box-id')
      route=RGEO.search_results.findOne
          type:
            $regex: "route.*"
            $options: 'i'
      route=ET.maybe_resolve route
      if route.obj?
        for related,idx in (route.obj.links.map (x)->ET.maybe_resolve(x))
          if related.from_new.type=='address:new'
            mat_address= ET.materialize(related.from_new)
            # this jumps over the link in geocoder results
            # this action modifies get_link_target
            # ET.maybe_resolve route.obj.links[idx]

            #note that the extend is needed to preserve link fields which are not standard link fields
            _.extend( route.obj.links[idx], ET.create_link(mat_address))
                
          console.log 'address: ', related
        
        if route.from_new
          mat=ET.materialize route.from_new
        s2_el=$("##{search_box}")
        #val = s2_el.select2('val')
        #s2_el.select2('val',[val...,route.from_new?._id or route.ref_path[-1...][0]._id])

        #s2_el.select2('val', [route.from_new?._id or route.ref_path[-1...][0]._id], true)
        debugger
        #route=ET.maybe_resolve route.ref_path[0]
        s2_el.select2('val', [route.from_new?._id or route.ref_path[-1...][0]._id], true)
      return

do(ex=Template.rgeo_explain_box)->
  mkid=(id, prop)->
    "rgeo_box_#{id}_#{prop}"
  ex.helpers
    missing_route_contacts:missing_route_contacts
    missing_route_vehicle:missing_route_vehicle
    missing_route_addresses:missing_route_addresses
    missing_route_vehicle:missing_route_vehicle
    route_complete: ->
      unless (ex.missing_route_contacts.apply @)  or  (ex.missing_route_addresses.apply @)
        true
      false
    
Template.add_entity.helpers
  istype: (arg)->
    if arg.length >= @obj.type.length and @obj.type[0..arg.length-1] == arg
      return true
    return false
Template.add_entity.rendered =->
  switch @data.obj.type 
    when 'op_add'
      $(@firstNode).find('.btn.add-customer').click (event)=>
        elm=$(@firstNode).parents('#select2-drop')
        console.log  elm
        my_id=elm.data('select2').opts.element.attr('id')
        #add term to db
        debugger
        new_customer = $(event.target).data('term')
        key=collections.customer_collection.insert 
          name:new_customer
        search_key=RGEO.search_results.insert
          type:'customer:ref'
          link_id: key
          search_ids:[RGEO.last_subscription(my_id).id]
        #add term to select2
        prev_val=elm.select2 'val'
        prev_val.push search_key
        elm.select2 'val', prev_val, true
      $(@firstNode).find('.btn.add-contact').click (event)=>
        elm=$(@firstNode).parents('#select2-drop')
        my_id=elm.data('select2').opts.element.attr('id')
        new_contact_name = $(event.target).data('term')
        key=collections.contact_collection.insert
          name:new_contact_name
        search_key=RGEO.search_results.insert
          type:'contact:ref'
          link_id: key
          search_ids:[RGEO.last_subscription(my_id).id]
        prev_val=elm.select2 'val'
        prev_val.push search_key
        elm.select2 'val', prev_val, true
ET.register_template('op_add',Template.add_entity)

Template.add_entity.helpers
  istype: Template.add_entity.istype







Template.render_customer_or_contact.helpers
  is_customer: -> @obj?.type=='customer'
  is_contact: -> @obj?.type=='contact'
