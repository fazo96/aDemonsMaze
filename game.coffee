Array::delete = (o) ->
  @splice @indexOf(o), 1

Game =
  display: null
  engine: null
  w: 80
  h: 25
  screen_w: 80
  screen_h: 25
  scheduler: null
  player: null
  maps: []
  monsters: []

  init: ->
    console.log "Experimenting with rot.js ..."
    # Init
    @display = new ROT.Display()
    document.body.appendChild @display.getContainer()
    @scheduler = new ROT.Scheduler.Simple()
    @engine = new ROT.Engine @scheduler
    @level = 0
    @newLevel 0
    @engine.start()
    console.log "Done init"

  newLevel: (l,moveTo) ->
    moveTo = moveTo or yes
    oldLevel = @level
    # Map
    @level = l if moveTo is yes
    if @maps[l] is undefined
      console.log "Generating Level: "+l
      # Generate map
      @generateMap l
      loc = @getEmptyLoc()
      if oldLevel isnt l
        @map(loc.x,loc.y).type = "stairs"
        @map(loc.x,loc.y).val = if oldLevel > l then "<" else ">"
        console.log "Placed "+@map(loc.x,loc.y).val+" tile"
      if @player is undefined or @player is null
        @player = new Player loc.x, loc.y
        @scheduler.add @player, yes
      # Stairs
      loc2 = @getEmptyLoc()
      while loc2.x is loc.x and loc2.y is loc.y
        loc2 = @getEmptyLoc()
      @map(loc2.x,loc2.y).type = "stairs"
      @map(loc2.x,loc2.y).val = ">"
    else console.log "Loading Level: "+l
    if @player.pos[l] isnt undefined
      @player.x = @player.pos[l].x
      @player.y = @player.pos[l].y
    else
      @player.x = loc.x; @player.y = loc.y
    # Generate Monsters
    if not @monsters[l]
      @monsters[l] = []
      times = Math.floor(ROT.RNG.getUniform() * 5)
      console.log "Generating "+times+" monsters on floor "+l
      for i in [1..times]
        loc = @getEmptyLoc()
        @monsters[l].push new Monster(loc.x, loc.y, l)
    if moveTo # Change level
      console.log "Player moving to level "+l
      # Stop old monsters' AI for now
      if @monsters[oldLevel]
        @scheduler.remove monster for monster in @monsters[oldLevel]
      # Enter new monsters' AI
      @scheduler.add monster, yes for monster in @monsters[l]
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
    onlySeen = onlySeen or no
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
    # Draw Monsters
    #for monster in @monsters[@level]
      #@display.draw monster.x, monster.y, 'M', "#fff", "#000"

  getEmptyLoc: ->
    return unless @digger
    r = undefined
    while r is undefined
      rs = @digger.getRooms()
      r = rs[Math.floor(ROT.RNG.getUniform() * @digger.getRooms().length - 1)]
    x = r.getLeft()
    + Math.floor ROT.RNG.getUniform() * (r.getRight() - r.getLeft())
    y = r.getTop()
    + Math.floor ROT.RNG.getUniform() * (r.getBottom() - r.getTop())
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
  finished = no
  # start actions --->
  if e.keyCode is 16 # Shift
    @shiftDown = yes
  else if e.keyCode is 67 # c
    @closeDoor = yes
  if e.keyCode is 60 and Game.map(@x,@y).type is "stairs"
    if Game.map(@x,@y).val is ">" and @shiftDown
      # Go downstairs
      @pos[Game.level] = { x: @x, y: @y }
      Game.newLevel Game.level - 1
      finished = yes
    else if Game.map(@x,@y).val is "<" and not @shiftDown
      # Go upstairs
      @pos[Game.level] = { x: @x, y: @y }
      Game.newLevel Game.level + 1
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
  if not @fov
    @fov = new ROT.FOV.PreciseShadowcasting (x,y) ->
      return false unless Game.map(x,y)
      Game.map(x,y).block isnt true
  @fov.compute @x, @y, 6, (x, y, r, v) ->
    return unless Game.map(x,y)
    Game.map(x,y).seen = yes
    Game.display.draw x, y, Game.map(x,y).val,
                            Game.map(x,y).fg_light,
                            Game.map(x,y).bg_light
    # Check for Monsters
    for monster in Game.monsters[Game.level]
      if monster.x is x and monster.y is y
        Game.display.draw x, y, "M",
          Game.map(x,y).fg_light,
          Game.map(x,y).bg_light

Monster = (x,y,level) ->
  @x = x; @y = y; @z = level

Monster::act = ->
  return unless @z is Game.level
  dir = ROT.DIRS[8][Math.floor(ROT.RNG.getUniform() * 7)]
  @move(@x+dir[0],@y+dir[1])

Monster::move = (x,y) ->
  if Game.map(x,y) and Game.map(x,y).block isnt yes
    @x = x; @y = y
