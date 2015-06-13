class DAUCache extends events.EventEmitter
  constructor: ->
    @queue = {}

  add: (username, timestamp) ->
    ymd = timestamp.year + timestamp.month + timestamp.day
    if not @queue[ymd]
      @queue[ymd] = [username]
      @emit 'start', (timestamp)
      return
    if username not in @queue[ymd]
      @queue[ymd].push username

  process: (timestamp) ->
    ymd = timestamp.year + timestamp.month + timestamp.day
    if @queue[ymd][0]
      console.log @queue[ymd]
      username = @queue[ymd][0]
      dauModel.findOne {'ymd': ymd}, (err, dau) =>
        throw err if err
        if dau
          if username in dau.username
            @queue[ymd].splice(0, 1)
            @process timestamp
          else
            dau.username.push username
        else
          dau = new dauModel
          dau.ymd = ymd
          dau.username = [username]
        dau.save (err) =>
          throw err if err
          @queue[ymd].splice(0, 1)
          @process timestamp