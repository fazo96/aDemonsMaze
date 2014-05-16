Game =
  display: null
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
    freeCells = @generateMap()
    # Player
    loc = @getEmptyLoc()
    @scheduler.remove @player
    @player = new Player loc.x, loc.y
    @scheduler.add @player, yes
    # Stairs
    loc = @getEmptyLoc()
    @map[loc.x+","+loc.y].type = "stairs"
    @map[loc.x+","+loc.y].val = ">"
    # Start
    @engine.start()
    @draw()

  generateMap: ->
    @map = {}
    @digger = new ROT.Map.Digger()
    freeCells = []
    @digger.create (x,y,solid) =>
      key = x+","+y
      if not solid
        freeCells.push key
      @map[key] =
        val: if solid then " " else "."
        seen: no
        type: if solid then "wall" else "floor"
        block: if solid then yes else no
        fg: if solid then "#000" else "#fff"
        bg: if solid then "#444" else "#000"
        fg_light: if solid then "#000" else "#fff"
        bg_light: if solid then "#660" else "#aa0"
    for room in @digger.getRooms()
      room.getDoors (x,y) =>
        @map[x+","+y].val = "+"
        @map[x+","+y].type = "door"
        @map[x+","+y].fg = "#3a261a"
        @map[x+","+y].block = yes
        @map[x+","+y].fg_light = "#584338"

  drawMap : (onlySeen) ->
    for key of @map
      a = split key
      if @map[key].seen is yes or not onlySeen
        @display.draw a.x, a.y, @map[key].val, @map[key].fg, @map[key].bg

  draw : ->
    # Draw player FOV and player
    @display.clear()
    @drawMap no
    @player.drawVisible()
    @display.draw @player.x, @player.y, '@', "#fff", "#aa0"

  getEmptyLoc: ->
    return unless @digger
    rs = @digger.getRooms()
    room = rs[Math.floor(ROT.RNG.getUniform() * @digger.getRooms().length - 1)]
    x = room.getLeft()
    + Math.floor ROT.RNG.getUniform() * (room.getRight() - room.getLeft())
    y = room.getTop()
    + Math.floor ROT.RNG.getUniform() * (room.getBottom() - room.getTop())
    return {x,y}

split = (v) ->
  parts = v.split ","
  x = parseInt parts[0]; y = parseInt parts[1]
  {x,y}

Player = (x,y) ->
  @x = x
  @y = y
  @shiftDown = no
  @move @x, @y
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
    console.log "Shift UP"

Player::onKeyDown = (e) ->
  console.log e.keyCode
  finished = no
  # start actions --->
  if e.keyCode is 16
    @shiftDown = yes
    console.log "Shift Down"
  else
  if e.keyCode is 60 and @shiftDown and Game.map[@x+","+@y].type is "stairs"
    if Game.map[@x+","+@y].val is ">"
      # Go downstairs
      Game.newLevel()
      finished = yes
  else if 36 <= e.keyCode <= 40
    # Direction Key
    dir = ROT.DIRS[8][@keyMap[e.keyCode]]
    newX = @x + dir[0]; newY = @y + dir[1]
    newKey = newX + "," + newY
    # Move into non-solid space
    if Game.map[newKey].block is no
      @move newX, newY
      finished = yes
    # Move into door: Open it
    else if Game.map[newKey].type is "door"
      Game.map[newKey].val = "\'"
      Game.map[newKey].block = no
      finished = yes
  # <--- end actions
  Game.draw()
  if finished
    window.removeEventListener "keydown", @_onKeyDown
    Game.engine.unlock()

Player::move = (newX, newY)->
  @x = newX; @y = newY

Player::drawVisible = ->
  map = Game.map
  fov = new ROT.FOV.PreciseShadowcasting (x,y) ->
    return false unless map[x+","+y]
    map[x+","+y].block isnt true
  fov.compute @x, @y, 6, (x, y, r, v) ->
    return unless map[x+","+y]
    map[x+","+y].seen = yes
    Game.display.draw x, y, map[x+","+y].val,
                            map[x+","+y].fg_light,
                            map[x+","+y].bg_light
