RGEO.subscriptions=
  close_all_except:(box_id,search_ids)->
    unless RGEO.subscriptions[box_id]?
      throw new Error("No boxid=#{box_id} has been registered with RGEO.subscriptions.")
    if search_ids?
      unless search_ids instanceof Array
        search_ids=[search_ids]
    else
      search_ids=[]
    ret=[]
    closed=0
    for val, idx in RGEO.subscriptions[box_id]
      unless val in search_ids
        val.sub.stop()
        val.computation.stop()
        ret.push val.id
        console.log "closing" ,val, "search_ids:" ,search_ids
        delete RGEO.subscriptions[box_id][idx]
        closed++
      RGEO.subscriptions[box_id] = RGEO.subscriptions[box_id].filter (x)->x?
    console.log "Closed #{closed} subscriptions"
    return ret
  close_all:(box_id) -> RGEO.subscriptions.close_all_except(box_id)
RGEO.selection_subscription={}
RGEO.last_subscription= (select2_id)->
  unless select2_id of RGEO.subscriptions
    return null
  else
    if RGEO.subscriptions[select2_id].length >0
      return RGEO.subscriptions[select2_id][RGEO.subscriptions[select2_id].length-1]
  null