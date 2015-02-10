RGEO.search_requests.allow 
  insert: ->
    console.log 'allow request'
    return true

RGEO.search_results.allow
  insert: ->
    console.log 'allow request to insert result'
    return true
  update:->true


