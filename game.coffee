Game =
  display: null
  engine: null
  w: 80
  h: 25
  scheduler: null
  player: null
  maps: []

  init: ->
    console.log "Experimenting with rot.js ..."
    # Init
    @display = new ROT.Display()
    document.body.appendChild @display.getContainer()
    @scheduler = new ROT.Scheduler.Simple()
    @engine = new ROT.Engine @scheduler
    @newLevel 0
    @engine.start()
    console.log "Done init"

  newLevel: (l,putUpStairs) ->
    up = putUpStairs or no
    # Map
    @level = l
    console.log "Level: "+@level
    if @maps[@level] is undefined
      # Generate map
      @generateMap @level
      loc = @getEmptyLoc()
      if up
        @map(loc.x,loc.y).type = "stairs"
        @map(loc.x,loc.y).val = "<"
      if @player is undefined or @player is null
        @player = new Player loc.x, loc.y
        @scheduler.add @player, yes
      # Stairs
      loc2 = @getEmptyLoc()
      while loc2.x is loc.x and loc2.y is loc.y
        loc2 = @getEmptyLoc()
      @map(loc2.x,loc2.y).type = "stairs"
      @map(loc2.x,loc2.y).val = ">"
    if @player.pos[@level] isnt undefined
      @player.x = @player.pos[@level].x
      @player.y = @player.pos[@level].y
    else
      @player.x = loc.x; @player.y = loc.y
    @draw()

  generateMap: (l) ->
    @map_done = no; @rooms_done = no; times = 0
    @maps[l] = {}
    @digger = new ROT.Map.Digger()
    finished = @digger.create (x,y,solid) =>
      key = x+","+y
      @maps[l][key] =
        val: if solid then " " else "."
        seen: no
        type: if solid then "wall" else "floor"
        block: if solid then yes else no
        fg: if solid then "#000" else "#777"
        bg: if solid then "#444" else "#000"
        fg_light: if solid then "#000" else "#fff"
        bg_light: if solid then "#660" else "#aa0"
      times++
      if times is @w*@h
        @map_done = yes
        console.log "[Map:"+l+"] Generated structure"

    console.log "[Map:"+l+"] Finalizing map..."
    for i,room of @digger.getRooms()
      continue unless room.getDoors
      room.getDoors (x,y) =>
        k = x+","+y
        @maps[l][k].val = "+"
        @maps[l][k].type = "door"
        @maps[l][k].fg = "#3a261a"
        @maps[l][k].block = yes
        @maps[l][k].fg_light = "#584338"
      @rooms_done = yes if i is @digger.getRooms().length - 1
    console.log "[Map:"+l+"] Finished"


  map : (x,y) ->
    @maps[@level][x+","+y]

  drawMap : (onlySeen) ->
    if not onlySeen then onlySeen = no
    for key of @maps[@level]
      if @maps[@level][key].seen is yes or onlySeen is no
        @display.draw key.split(",")[0], key.split(",")[1],
          @maps[@level][key].val, @maps[@level][key].fg, @maps[@level][key].bg

  draw : ->
    if not @map_done
      # Map has to be finished
      return
    @display.clear()
    # Draw player FOV and player
    @player.drawMemory()
    @player.drawVisible()
    @display.draw @player.x, @player.y, '@', "#fff", "#aa0"

  getEmptyLoc: ->
    return unless @digger
    room = undefined
    while room is undefined
      rs = @digger.getRooms()
      room = rs[Math.floor(ROT.RNG.getUniform() * @digger.getRooms().length - 1)]
    x = room.getLeft()
    + Math.floor ROT.RNG.getUniform() * (room.getRight() - room.getLeft())
    y = room.getTop()
    + Math.floor ROT.RNG.getUniform() * (room.getBottom() - room.getTop())
    return {x,y}

Player = (x,y) ->
  @x = x
  @y = y
  @shiftDown = no; @closeDoor = no
  @move @x, @y
  @pos = {}
  @keyMap = {}
  @keyMap[38] = 0
  @keyMap[33] = 1
  @keyMap[39] = 2
  @keyMap[34] = 3
  @keyMap[40] = 4
  @keyMap[35] = 5
  @keyMap[37] = 6
  @keyMap[36] = 7
  # Workaround for problem with removing listeners when functions are bound
  @_onKeyUp = @onKeyUp.bind this
  @_onKeyDown = @onKeyDown.bind this
  window.addEventListener "keyup", @_onKeyUp

Player::act = ->
  Game.engine.lock()
  window.addEventListener "keydown", @_onKeyDown

Player::onKeyUp = (e) ->
  if e.keyCode is 16
    @shiftDown = no

Player::onKeyDown = (e) ->
  finished = no;
  # start actions --->
  if e.keyCode is 16 #Shift
    @shiftDown = yes
  else if e.keyCode is 67 # c
    @closeDoor = yes
  if e.keyCode is 60 and Game.map(@x,@y).type is "stairs"
    if Game.map(@x,@y).val is ">" and @shiftDown
      # Go downstairs
      @pos[Game.level] = { x: @x, y: @y }
      Game.newLevel --Game.level, yes
      finished = yes
    else if Game.map(@x,@y).val is "<" and not @shiftDown
      # Go upstairs
      @pos[Game.level] = { x: @x, y: @y }
      Game.newLevel ++Game.level
      finished = yes
  else if 36 <= e.keyCode <= 40
    # Direction Key
    dir = ROT.DIRS[8][@keyMap[e.keyCode]]
    newX = @x + dir[0]; newY = @y + dir[1]
    # Door: open or close
    if Game.map(newX,newY).type is "door"
      if @closeDoor is yes and Game.map(newX,newY).block is no
        Game.map(newX,newY).val = "+"
        Game.map(newX,newY).block = yes
        Game.draw(); finished = yes
      else if @closeDoor is no and Game.map(newX,newY).val is "+"
        Game.map(newX,newY).val = "\'"
        Game.map(newX,newY).block = no
        Game.draw(); finished = yes
    # Open Space
    if Game.map(newX,newY).block is no and finished is no
      @move newX, newY
      Game.draw()
      finished = yes
  if e.keyCode isnt 67 then @closeDoor = no
  # <--- end actions
  if finished
    window.removeEventListener "keydown", @_onKeyDown
    Game.engine.unlock()

Player::move = (newX, newY)->
  @x = newX; @y = newY

Player::drawMemory = ->
  for x in [0..Game.w-1]
    for y in [0..Game.h-1]
      if Game.map(x,y).seen is true
        Game.display.draw x, y, Game.map(x,y).val,
                                Game.map(x,y).fg,
                                Game.map(x,y).bg

Player::drawVisible = ->
  fov = new ROT.FOV.PreciseShadowcasting (x,y) ->
    return false unless Game.map(x,y)
    Game.map(x,y).block isnt true
  fov.compute @x, @y, 6, (x, y, r, v) ->
    return unless Game.map(x,y)
    Game.map(x,y).seen = yes
    Game.display.draw x, y, Game.map(x,y).val,
                            Game.map(x,y).fg_light,
                            Game.map(x,y).bg_light
