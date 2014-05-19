Array::delete = (o) ->
  @splice @indexOf(o), 1

Game =
  w: 50
  h: 50
  screen_w: 80
  screen_h: 25
  debug: no
  maps: []
  monsters: []

  init: ->
    console.log "A Demon's Maze - WIP"
    if ROT.isSupported() is no
      document.getElementById("gameContainer").innerHTML = """
      <h3>Oh! Your browser does not support HTML5 Canvas!</h3>
      <p>Try Firefox or Chrome!</p>
      """
      return
    # Init
    @display = new ROT.Display { width: @screen_w, height: @screen_h }
    document.getElementById("gameContainer").appendChild @display.getContainer()
    @scheduler = new ROT.Scheduler.Action()
    @level = 0
    @camera = new Camera 0,0,@screen_w,@screen_h
    @newLevel 0
    @scheduler.next().act()
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
      loc = @getEmptyLoc no
      if oldLevel isnt l
        @map(loc.x,loc.y).type = "stairs"
        @map(loc.x,loc.y).val = if oldLevel > l then "<" else ">"
        console.log "Placed "+@map(loc.x,loc.y).val+" tile"
      if @player is undefined or @player is null
        @player = new Player loc.x, loc.y
        @scheduler.add @player, yes, 0
      # Stairs
      loc2 = @getEmptyLoc yes
      #while loc2.x is loc.x and loc2.y is loc.y
        #loc2 = @getEmptyLoc yes
      @map(loc2.x,loc2.y).type = "stairs"
      @map(loc2.x,loc2.y).val = if oldLevel > l then ">" else "<"
    else console.log "Loading Level: "+l
    if @player.pos[l] isnt undefined
      @player.x = @player.pos[l].x
      @player.y = @player.pos[l].y
    else
      @player.x = loc.x; @player.y = loc.y
    Game.camera.setCenter @player.x,@player.y
    # Generate Monsters
    if not @monsters[l]
      @monsters[l] = []
      times = Math.floor(ROT.RNG.getUniform() * 7)
      console.log "Generating " + (times+1) + " monsters on floor "+l
      for i in [1..times]
        loc = @getEmptyLoc yes
        @monsters[l].push new Monster(loc.x, loc.y, l)
    if moveTo # Change level
      console.log "Player moving to level "+l
      # Stop old monsters' AI for now
      if @monsters[oldLevel]
        @scheduler.remove monster for monster in @monsters[oldLevel]
      # Enter new monsters' AI
      @scheduler.add monster, yes, 50 for monster in @monsters[l]
    @draw()

  generateMap: (l) ->
    @map_done = no; @rooms_done = no; times = 0
    @maps[l] = {}
    @digger = new ROT.Map.Digger @w, @h
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
        @camera.draw key.split(",")[0], key.split(",")[1],
          @maps[@level][key].val, @maps[@level][key].fg, @maps[@level][key].bg

  draw : ->
    if not @map_done
      # Map has to be finished
      return
    @display.clear()
    # Draw player FOV and player
    @player.drawMemory()
    @player.drawVisible()
    @camera.draw @player.x, @player.y, '@', "#fff", "#aa0"
    # Draw Monsters (Debug)
    #for monster in @monsters[@level]
      #@camera.draw monster.x, monster.y, 'M', "#fff", "#000"

  inRoom : (room, x, y) ->
    if room then room.x1 <= x <= room.x2 and room.y1 <= y <= room.y2 else no

  isBlocked : (x,y,l,ignorePlayer) ->
    l = l or @level; ignorePlayer = ignorePlayer or no
    if not @map(x,y) then return yes
    if @map(x,y).block is yes then return yes
    if ignorePlayer is no
      if @player.x is x and @player.y is y and @level is l then return yes
    return no unless @monsters and @monsters[l]
    for monster in @monsters[l]
      return yes if monster.x is x and monster.y is y
    no

  getEmptyLoc: (awayFromPlayer)->
    awayFromPlayer = awayFromPlayer or no
    return unless @digger
    r = undefined; ok = yes
    while r is undefined or ok is no
      rs = @digger.getRooms()
      r = rs[Math.floor(ROT.RNG.getUniform() * @digger.getRooms().length - 1)]
      if awayFromPlayer is off or not r or @inRoom(r,@player.x,@player.y) is yes
        ok = yes
    x = r.getLeft()
    + Math.floor ROT.RNG.getUniform() * (r.getRight() - r.getLeft())
    y = r.getTop()
    + Math.floor ROT.RNG.getUniform() * (r.getBottom() - r.getTop())
    return {x,y}

Camera = (x,y,w,h) ->
  @x = x; @y = y; @w = w; @h = h
  @slideOffset = 10

Camera::getCenter = ->
  { x: @x + @w/2, y: @y + @h/2 }

Camera::fromWorld = (x,y) ->
  { x: x-@x; y: y-@y }

Camera::slide = (x,y) ->
  @x += Math.floor x unless not x
  @y += Math.floor y unless not y

Camera::setCenter = (x,y) ->
  return unless x and y
  @x = Math.floor x - @w/2; @y = Math.floor y - @h/2

Camera::visible = (x,y) ->
  x > @x and x < @x+@w and y > @y and y < @y+@h

Camera::draw = (x,y,ch,fg,bg) ->
  Game.display.draw x-@x,y-@y,ch,fg,bg #unless @visible x,y is no

Player = (x,y) ->
  @x = x
  @y = y
  @shiftDown = no; @closeDoor = no
  @move @x, @y
  @pos = {}
  @keyMap = {}
  @keyMap[38] = @keyMap[104] = 0 # up
  @keyMap[33] = @keyMap[105] = 1
  @keyMap[39] = @keyMap[102] = 2 # right
  @keyMap[34] = @keyMap[99] = 3
  @keyMap[40] = @keyMap[98] = 4 # down
  @keyMap[35] = @keyMap[97] = 5
  @keyMap[37] = @keyMap[100] = 6 # left
  @keyMap[36] = @keyMap[103] = 7
  # Workaround for problem with removing listeners when functions are bound
  @_onKeyUp = @onKeyUp.bind this
  @_onKeyDown = @onKeyDown.bind this
  window.addEventListener "keyup", @_onKeyUp

Player::act = ->
  window.addEventListener "keydown", @_onKeyDown

Player::onKeyUp = (e) ->
  if e.keyCode is 16
    @shiftDown = no

Player::onKeyDown = (e) ->
  finished = no
  console.log "Keycode: "+e.keyCode
  # start actions --->
  if e.keyCode is 16 # Shift
    @shiftDown = yes
  else if e.keyCode is 67 # c
    @closeDoor = yes
  if e.keyCode is 101 or e.keyCode is 190 # dor symbol or Numpad 5: wait
    finished = yes # Do nothing, pass turn
    Game.scheduler.setDuration 5
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
    if finished is yes then Game.scheduler.setDuration 5
  else if 36 <= e.keyCode <= 40 or 97 <= e.keyCode <= 105 and @closeDoor is no
    # Direction Key
    dir = ROT.DIRS[8][@keyMap[e.keyCode]]
    if dir
      newX = @x + dir[0]; newY = @y + dir[1]
      blocked = Game.isBlocked(newX,newY,Game.level,no)
      # Door: open or close
      if Game.map(newX,newY).type is "door"
        if @closeDoor is yes and blocked is no
          Game.map(newX,newY).val = "+"
          Game.map(newX,newY).block = yes
          Game.draw(); finished = yes
        else if @closeDoor is no and Game.map(newX,newY).val is "+"
          Game.map(newX,newY).val = "\'"
          Game.map(newX,newY).block = no
          Game.draw(); finished = yes
      if blocked is no and finished is no
        # Move Into Open Space
        @move newX, newY
        Game.draw()
        finished = yes
      if finished is yes then Game.scheduler.setDuration 10

  if e.keyCode isnt 67 then @closeDoor = no
  # <--- end actions
  if finished is yes
    window.removeEventListener "keydown", @_onKeyDown
    Game.scheduler.next().act()

Player::move = (newX, newY)->
  #return unless newX and newY and newX isnt @x and newY isnt @y
  onScreen = Game.camera.fromWorld newX, newY
  if onScreen.x > Game.camera.w-Game.camera.slideOffset
    Game.camera.slide 1,0
  else if onScreen.x < Game.camera.slideOffset then Game.camera.slide -1,0
  if onScreen.y < Game.camera.slideOffset then Game.camera.slide 0,-1
  else if onScreen.y > Game.camera.h-Game.camera.slideOffset
    Game.camera.slide 0,1
  @x = newX; @y = newY

Player::drawMemory = ->
  for x in [Game.camera.x .. Game.camera.x+Game.camera.w-1]
    for y in [Game.camera.y .. Game.camera.y+Game.camera.h-1]
      if Game.map(x,y) and Game.map(x,y).seen is true
        Game.camera.draw x, y, Game.map(x,y).val,
                                Game.map(x,y).fg,
                                Game.map(x,y).bg

Player::drawVisible = ->
  if not @fov
    @fov = new ROT.FOV.PreciseShadowcasting (x,y) ->
      Game.isBlocked(x,y,Game.level,yes) is no
  @fov.compute @x, @y, 6, (x, y, r, v) ->
    return unless Game.map(x,y)
    Game.map(x,y).seen = yes
    Game.camera.draw x, y, Game.map(x,y).val,
                            Game.map(x,y).fg_light,
                            Game.map(x,y).bg_light
    # Check for Monsters
    for monster in Game.monsters[Game.level]
      if monster.x is x and monster.y is y
        Game.camera.draw x, y, monster.val,
          monster.fg_light,
          Game.map(x,y).bg_light

Monster = (x,y,level,val,fg,fg_light) ->
  @x = x; @y = y; @z = level
  @p_x = no; @p_y = no; @val = val or "M"
  @fg = fg or "#fff"; @fg_light = fg_light or "#fff"

Monster::act = ->
  return unless @z is Game.level
  if not @fov
    @fov = new ROT.FOV.PreciseShadowcasting (x,y) =>
      if @x is x and @y is y
        return yes
      Game.isBlocked(x,y,@z,no) is no
  # Player seen behaviour
  @fov.compute @x, @y, 8, (x, y, r, v) =>
    return unless Game.map(x,y)
    if Game.player.x is x and Game.player.y is y
      # Last known player position
      @p_x = Game.player.x; @p_y = Game.player.y
  if @p_x is no and @p_y is no
    # Standard behaviour: player has escaped or has not been found
    dir = ROT.DIRS[8][Math.floor(ROT.RNG.getUniform() * 7)]
    @move(@x+dir[0],@y+dir[1])
    Game.scheduler.setDuration 20
  else # Move towards known player position
    path = new ROT.Path.Dijkstra @p_x, @p_y, (x,y) =>
      # TODO: Every door considered open until seen closed
      if @x is x and @y is y
        return yes
      Game.isBlocked(x, y,@z,no) is no
    tx = @x; ty = @y # workaround, it works and it's efficient! I hope...
    path.compute tx, ty, (x,y) =>
      if Math.abs(tx-x) < 2 and Math.abs(ty-y) < 2 then @move x, y
    Game.scheduler.setDuration 15
  Game.scheduler.next().act()

Monster::move = (x,y) ->
  return unless Game.map(x,y)
  if Game.isBlocked(x,y,@z,no) is yes
    # Can't pass!
    if Game.map(x,y).type is "door" and @p_x isnt no and @p_y isnt no
      #Door Smashing. Not implemented yet
      console.log "Door Smash!"
  else if Math.abs(@x-x) < 2 and Math.abs(@y-y) < 2
    @x = x; @y = y; Game.draw()
    # If I get to player's last known position and he's not there..
    if @x is @p_x and @y is @p_y
      @p_x = no; @p_y = no

# Start the gameeee
Game.init()
