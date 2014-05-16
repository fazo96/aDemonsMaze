Game =
  display: null
  map: {}
  w: 80
  h: 25
  engine: null
  scheduler: null
  player: null

  init: ->
    console.log "Experimenting with rot.js ..."
    # Init
    @display = new ROT.Display()
    document.body.appendChild @display.getContainer()
    @scheduler = new ROT.Scheduler.Simple()
    @engine = new ROT.Engine @scheduler
    @newLevel()
    console.log "Done init"

  newLevel: ->
    # Map
    @map = {}
    freeCells = @generateMap()
    # Player
    loc = @getEmptyLocation freeCells
    @player = new Player loc.x, loc.y
    @scheduler.add @player, yes
    # Stairs
    loc = @getEmptyLocation freeCells
    @map[loc.x+","+loc.y].type = "stairs"
    @map[loc.x+","+loc.y].val = ">"
    # Start
    @engine.start()
    @draw()

  generateMap: ->
    digger = new ROT.Map.Digger()
    freeCells = []
    digger.create (x,y,solid) =>
      key = x+","+y
      if not solid
        freeCells.push key
      @map[key] =
        val: if solid then " " else "."
        seen: no
        type: if solid then "wall" else "floor"
        solid: solid
        fg: if solid then "#000" else "#fff"
        bg: if solid then "#444" else "#000"
        fg_light: if solid then "#000" else "#fff"
        bg_light: if solid then "#660" else "#aa0"
    for room in digger.getRooms()
      room.getDoors (x,y) =>
        @map[x+","+y].val = "+"
        @map[x+","+y].type = "door"
        @map[x+","+y].fg = "#3a261a"
        @map[x+","+y].solid = yes
        @map[x+","+y].fg_light = "#584338"
    ###
    console.log "a"
    loc = getEmptyLocation freeCells
    @map[loc.x+","+loc.y].type = "stairs"
    @map[loc.x+","+loc.y].val = ">"
    ###
    freeCells

  drawMap : (onlySeen) ->
    for key of @map
      a = split key
      if @map[key].seen is yes or not onlySeen
        @display.draw a.x, a.y, @map[key].val, @map[key].fg, @map[key].bg

  draw : ->
    # Draw player FOV and player
    @display.clear()
    @drawMap yes
    @player.drawVisible()
    @display.draw @player.x, @player.y, '@', "#fff", "#aa0"

  getEmptyLocation: (freeCells)->
    #index = 3
    index = Math.floor ROT.RNG.getUniform() * freeCells.length
    key = split freeCells.splice(index,1)[0]
    #break unless player.x is key.x and player.y is key.y
    return key
  getEmptyLoc: ->
    loop
      x = Math.floor ROT.RNG.getUniform() * Game.w
      y = Math.floor ROT.RNG.getUniform() * Game.h
      return {x,y} if map[x+","+y].type is "floor"

split = (v) ->
  parts = v.split ","
  x = parseInt parts[0]; y = parseInt parts[1]
  {x,y}

Player = (x,y) ->
  @x = x
  @y = y
  @lastKeycode = -1
  @move @x, @y

Player::act = ->
  Game.engine.lock()
  window.addEventListener "keydown", this

Player::handleEvent = (e) ->
  keyMap = {}
  keyMap[38] = 0
  keyMap[33] = 1
  keyMap[39] = 2
  keyMap[34] = 3
  keyMap[40] = 4
  keyMap[35] = 5
  keyMap[37] = 6
  keyMap[36] = 7
  console.log e.keyCode
  if e.keyCode is 60 and @lastKeycode is 16 and Game.map[@x+","+@y].type is "stairs"
    Game.newLevel()
  if 36 <= e.keyCode <= 40
    dir = ROT.DIRS[8][keyMap[e.keyCode]]
    newX = @x + dir[0]; newY = @y + dir[1]
    newKey = newX + "," + newY

    # Move into non-solid space
    if not Game.map[newKey].solid
      @move newX, newY
    # Open Door
    else if Game.map[newKey].type is "door"
      Game.map[newKey].val = "\'"
      Game.map[newKey].solid = no
  @lastKeycode = e.keyCode
  console.log "Last keycode: "+@lastKeycode
  Game.draw()
  window.removeEventListener "keydown", this
  Game.engine.unlock()

Player::move = (newX, newY)->
  @x = newX; @y = newY

Player::drawVisible = ->
  map = Game.map
  fov = new ROT.FOV.PreciseShadowcasting (x,y) ->
    return false unless map[x+","+y]
    not map[x+","+y].solid
  fov.compute @x, @y, 6, (x, y, r, v) ->
    return unless map[x+","+y]
    map[x+","+y].seen = yes
    Game.display.draw x, y, map[x+","+y].val, map[x+","+y].fg_light, map[x+","+y].bg_light
