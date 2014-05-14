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
    digger.create (x,y,value) =>
      key = x+","+y
      if not value
        freeCells.push key
        @map[key] = "."
    freeCells

  drawMap : ->
    for key of @map
      a = split key
      @display.draw a.x, a.y, @map[key]

  draw : ->
    # Draw player FOV and player
    @display.clear()
    @player.drawVisible()
    @display.draw @player.x, @player.y, '@'

  getEmptyLocation: (freeCells)->
    index = Math.floor ROT.RNG.getUniform() * freeCells.length
    key = freeCells.splice(index,1)[0]
    split(key)


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

  return unless newKey of Game.map

  @move newX, newY
  window.removeEventListener "keydown", this
  Game.draw()
  Game.engine.unlock()

Player::move = (newX, newY)->
  @x = newX; @y = newY

Player::drawVisible = ->
  map = Game.map
  fov = new ROT.FOV.PreciseShadowcasting (x,y) -> return x+","+y of map
  fov.compute @x, @y, 10, (x, y, r, v) ->
    color = if map[x+","+y] then "#aa0" else "#660"
    Game.display.draw x, y, map[x+","+y], "#fff", color
