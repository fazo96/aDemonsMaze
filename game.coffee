Game =
  display: null,
  map: {},
  engine: null,
  scheduler: null,
  player: null,

  init: ->
    console.log "Experimenting with rot.js ..."
    @display = new ROT.Display()
    document.body.appendChild @display.getContainer()
    freeCells = @generateMap()
    @scheduler = new ROT.Scheduler.Simple()
    @engine = new ROT.Engine @scheduler
    loc = @getEmptyLocation freeCells
    @player = new Player loc.x, loc.y
    @scheduler.add @player, yes
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
        solid: solid
        fg: if solid then "#000" else "#fff"
        bg: if solid then "#444" else "#000"
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
    index = Math.floor ROT.RNG.getUniform() * freeCells.length
    key = freeCells.splice(index,1)[0]
    split key


split = (v) ->
  parts = v.split ","
  x = parseInt parts[0]; y = parseInt parts[1]
  {x,y}

Player = (x,y) ->
  @x = x
  @y = y
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

  return unless 36 <= e.keyCode <= 40

  dir = ROT.DIRS[8][keyMap[e.keyCode]]
  newX = @x + dir[0]; newY = @y + dir[1]
  newKey = newX + "," + newY

  return unless not Game.map[newKey].solid

  @move newX, newY
  window.removeEventListener "keydown", this
  Game.draw()
  Game.engine.unlock()

Player::move = (newX, newY)->
  @x = newX; @y = newY

Player::drawVisible = ->
  map = Game.map
  fov = new ROT.FOV.PreciseShadowcasting (x,y) ->
    return false unless map[x+","+y]
    not map[x+","+y].solid
  fov.compute @x, @y, 10, (x, y, r, v) ->
    return unless map[x+","+y]
    map[x+","+y].seen = yes
    color = if map[x+","+y].solid then "#660" else "#aa0"
    Game.display.draw x, y, map[x+","+y].val, "#fff", color
