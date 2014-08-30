# This is A Demon's Maze main game file.
# Please look for a LICENSE.txt file in this folder for licensing information.

# Utility function. Needed!
Array::delete = (o) ->
  @splice @indexOf(o), 1

Game =
  w: 50
  h: 50
  screen_w: 80
  screen_h: 25
  camera_w: 80
  camera_h: 23
  debug: no
  maps: []
  monsters: []

  # Called only once per session: also starts the game
  init: ->
    console.log "A Demon's Maze - WIP"
    if ROT.isSupported() is no # Can't play.
      document.getElementById("gameContainer").innerHTML = """
      <h3>Oh! Your browser does not support HTML5 Canvas!</h3>
      <p>Try Firefox or Chrome!</p>
      """
      return
    # Init
    @display = new ROT.Display { width: @screen_w, height: @screen_h }
    document.getElementById("gameContainer").appendChild @display.getContainer()
    @newGame()
    console.log "Done init"

  # Resets the game
  newGame: ->
    @scheduler = new ROT.Scheduler.Action()
    @maps = []; @monsters = []; @player = undefined
    @camera = new Camera 0,0,@camera_w,@camera_h
    @newLevel 1
    @scheduler.next().act()

  ###
  Cretes a new level if it's not generated yet
  l: which level
  moveTo: move the player to the level
  ###
  newLevel: (l,moveTo) ->
    moveTo = moveTo or yes
    oldLevel = if @player then @player.z else 1
    # Map
    @player.z = l if @player and moveTo is yes
    if @maps[l] is undefined
      console.log "Generating Level: "+l
      # Generate map
      @generateMap l
      loc = @getEmptyLoc no
      if oldLevel isnt l
        @map(loc.x,loc.y,l).type = "stairs"
        @map(loc.x,loc.y,l).val = if oldLevel > l then "<" else ">"
        console.log "Placed "+@map(loc.x,loc.y,l).val+" tile"
      if @player is undefined or @player is null
        @player = new Player loc.x, loc.y, l
        @scheduler.add @player, yes, 0
      # Stairs
      loc2 = @getEmptyLoc yes
      #while loc2.x is loc.x and loc2.y is loc.y
        #loc2 = @getEmptyLoc yes
      @map(loc2.x,loc2.y,l).type = "stairs"
      @map(loc2.x,loc2.y,l).val = if oldLevel > l then ">" else "<"
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
      times = Math.floor l * 1.5 + ROT.RNG.getUniform() * 6 - 3
      if times > 15 then times = 15
      console.log "Generating " + times + " monsters on floor "+l
      if times > 0
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

  # Generate the map at the given level. Overwrites existing level
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

  # Get coordinates
  map : (x,y,z) -> z ?= @player.z; @maps[z][x+","+y]

  drawMap : (onlySeen) ->
    onlySeen = onlySeen or no; l = @player.z
    for key of @maps[l]
      if @maps[l][key].seen is yes or onlySeen is no
        @camera.draw key.split(",")[0], key.split(",")[1],
          @maps[l][key].val, @maps[l][key].fg, @maps[l][key].bg

  # Draws the UI
  drawUI: () ->
    # Separator
    s = ""; s += "_" for i in [1..@camera_w]
    @display.drawText 0, @camera_h, s
    # Player HP
    if @player.hp > 0
      @display.drawText 0, @camera_h+1, "HP "
      for i in [1..10]
        @display.draw 2+i,@camera_h+1, "=", "#a00", "#000"
      for i in [1..Math.floor @player.hp / 10]
        @display.draw 2+i,@camera_h+1, "=", "#f00", "#000"
    else @display.drawText 0,@camera_h+1, "Game Over! Press Enter"
    # Other
    @display.drawText @screen_w-9, @camera_h+1, "Floor: "+@player.z
    @display.drawText 15,@camera_h+1,"Ouch!" unless @player.hp is @player.oldHp
    @player.oldHp = @player.hp

  # Draws the game graphics. Call this every time a change is made
  draw : ->
    if not @map_done
      # Map has to be finished
      return
    @display.clear()
    # Draw player FOV and player
    @player.drawMemory()
    @player.drawVisible()
    @camera.draw @player.x, @player.y, '@', "#fff", "#aa0"
    @drawUI()
    # Draw Monsters (Debug)
    #for monster in @monsters[@player.z]
      #@camera.draw monster.x, monster.y, 'M', "#fff", "#000"

  # Is x,y in room?
  inRoom : (room, x, y) ->
    if room then room.x1 <= x <= room.x2 and room.y1 <= y <= room.y2 else no

  isBlocked : (x,y,l,ignorePlayer) ->
    l = l or @player.z; ignorePlayer = ignorePlayer or no
    if not @map(x,y,l) then return yes
    if @map(x,y,l).block is yes then return yes
    if ignorePlayer is no
      if @player.x is x and @player.y is y and @player.z is l then return yes
    return no unless @monsters and @monsters[l]
    for monster in @monsters[l]
      return yes if monster.x is x and monster.y is y
    no

  # Get a location in a room where there's nothing else, at level @player.z
  # away: if you want it away from the player's current position
  getEmptyLoc: (away)->
    away = away or yes
    return unless @digger; rs = @digger.getRooms()
    loop
      ok = no
      while ok is no
        r = rs[Math.floor(ROT.RNG.getUniform() * @digger.getRooms().length - 1)]
        if not @player or away is off or @inRoom(r,@player.x,@player.y) is no
          if r then ok = yes
      x = r.getLeft()
      + Math.floor ROT.RNG.getUniform() * (r.getRight() - r.getLeft())
      y = r.getTop()
      + Math.floor ROT.RNG.getUniform() * (r.getBottom() - r.getTop())
      return {x,y} unless @player and @player.x is x and @player.y is y

# Camera object: follows the player.
# Draw calls for the game world must be made to the camera
# Instance at Game.camera
Camera = (x,y,w,h) ->
  @x = x; @y = y; @w = w; @h = h
  @slideOffset = 10

Camera::getCenter = ->
  { x: @x + @w/2, y: @y + @h/2 }

# Convert world coords to screen
Camera::fromWorld = (x,y) ->
  { x: x-@x; y: y-@y }

# Move the camera by x, y
Camera::slide = (x,y) ->
  @x += Math.floor x unless not x
  @y += Math.floor y unless not y

# Moves the camera so x,y is at the center
Camera::setCenter = (x,y) ->
  return unless x and y
  @x = Math.floor x - @w/2; @y = Math.floor y - @h/2

# True if x,y is visible
Camera::visible = (x,y) ->
  x > @x and x < @x+@w and y > @y and y < @y+@h

# Draw ch at x,y using fg color for foreground and bg color for background
Camera::draw = (x,y,ch,fg,bg) ->
  Game.display.draw x-@x,y-@y,ch,fg,bg

class Entity
  constructor: (@x,@y,@z,@maxhp) ->
    @hp = @maxhp
    @mem = {}
  memory : (x,y,z) ->
  act: -> console.log "unconfigured entity ai"

# Player object
# Instance at Game.player
class Player extends Entity
  constructor : (x,y,z) ->
    super x,y,z,100
    @oldHp = @hp; @reqEnter = no
    @shiftDown = no; @closeDoor = no
    @move @x, @y
    @pos = {}; @keyMap = {}; @sounds = []
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

  # Callback for the turn scheduler
  act : ->
    if @hp <= 0
      #Game.display.drawText 15,@camera_h+1,"Game Over!"
      Game.draw() unless @reqEnter is yes
      @reqEnter = yes
    window.addEventListener "keydown", @_onKeyDown

  # Callback for keyboard key released event
  onKeyUp : (e) ->
    if e.keyCode is 16
      @shiftDown = no

  # Callback for keyboard key pressed event
  onKeyDown : (e) ->
    finished = no
    #console.log "Keycode: "+e.keyCode
    # start possible actions --->
    if @reqEnter is yes
      if e.keyCode is 13
        if @hp <= 0
          Game.newGame()
        finished = yes
      else finished = no
      return
    if e.keyCode is 16 # Shift
      @shiftDown = yes
    else if e.keyCode is 67 # c
      @closeDoor = yes
    if e.keyCode is 101 or e.keyCode is 190 # dot symbol or Numpad 5: wait
      finished = yes # Do nothing, pass turn
      Game.scheduler.setDuration 5
    if (e.keyCode is 60 or e.keyCode is 83) and Game.map(@x,@y).type is "stairs"
      if Game.map(@x,@y).val is ">" and (@shiftDown or e.keyCode is 83)
        # Go downstairs
        @pos[@z] = { x: @x, y: @y }
        Game.newLevel @z - 1
        finished = yes
      else if Game.map(@x,@y).val is "<" and (not @shiftDown or e.keyCode is 83)
        # Go upstairs
        @pos[@z] = { x: @x, y: @y }
        Game.newLevel @z + 1
        finished = yes
      if finished is yes then Game.scheduler.setDuration 5
    else if 36 <= e.keyCode <= 40 or 97 <= e.keyCode <= 105
      # Direction Key
      dir = ROT.DIRS[8][@keyMap[e.keyCode]]
      if dir
        newX = @x + dir[0]; newY = @y + dir[1]
        blocked = Game.isBlocked(newX,newY,@z,no)
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
    if finished is yes # This turn is over
      window.removeEventListener "keydown", @_onKeyDown
      Game.scheduler.next().act()

  # Move player to newX, newY in the game world
  move : (newX, newY)->
    #return unless newX and newY and newX isnt @x and newY isnt @y
    onScreen = Game.camera.fromWorld newX, newY
    if onScreen.x > Game.camera.w-Game.camera.slideOffset
      Game.camera.slide 1,0
    else if onScreen.x < Game.camera.slideOffset then Game.camera.slide -1,0
    if onScreen.y < Game.camera.slideOffset then Game.camera.slide 0,-1
    else if onScreen.y > Game.camera.h-Game.camera.slideOffset
      Game.camera.slide 0,1
    @x = newX; @y = newY

  # Draw the known tiles of the map
  drawMemory : ->
    for x in [Game.camera.x .. Game.camera.x+Game.camera.w-1]
      for y in [Game.camera.y .. Game.camera.y+Game.camera.h-1]
        if Game.map(x,y) and Game.map(x,y).seen is true
          Game.camera.draw x, y, Game.map(x,y).val,
                                  Game.map(x,y).fg,
                                  Game.map(x,y).bg

  # Draw lighting and visible tiles, monsters and doors
  drawVisible : ->
    if not @fov
      @fov = new ROT.FOV.PreciseShadowcasting (x,y) ->
        Game.isBlocked(x,y,@z,yes) is no

    # Draw heard sounds
    for s in @sounds
      Game.camera.draw s.x, s.y, s.val, s.light
    @sounds = []

    @fov.compute @x, @y, 6, (x, y, r, v) =>
      return unless Game.map(x,y)
      Game.map(x,y).seen = yes
      Game.camera.draw x, y, Game.map(x,y).val,
                              Game.map(x,y).fg_light,
                              Game.map(x,y).bg_light
      # Check for Monsters
      for monster in Game.monsters[@z]
        if monster.x is x and monster.y is y
          Game.camera.draw x, y, monster.val,
            monster.fg_light,
            Game.map(x,y).bg_light

# Monster object
# There is a bidimensional array of monsters at Game.monsters
class Monster extends Entity
  constructor : (x,y,z,val,fg,fg_light) ->
    super x,y,z,30
    @p_x = no; @p_y = no; @val = val or "M"
    @fg = fg or "#fff"; @fg_light = fg_light or "#fff"

  # Callback for the game turn scheduler
  act : ->
    # Do nothing if the player is on a different floor
    return unless @z is Game.player.z
    if not @fov # Create FOV instance if it doesn't exist
      @fov = new ROT.FOV.PreciseShadowcasting (x,y) =>
        # Callback: tells if vision passes through tile
        if @x is x and @y is y
          return yes
        Game.isBlocked(x,y,@z,no) is no
    # Compute visible tiles
    @fov.compute @x, @y, 8, (x, y, r, v) =>
      return unless Game.map(x,y)
      if Game.player.x is x and Game.player.y is y
        # Update last known player position: can see the player
        @p_x = Game.player.x; @p_y = Game.player.y
    if @p_x is no and @p_y is no
      # Standard behaviour: no known player position
      dir = ROT.DIRS[8][Math.floor(ROT.RNG.getUniform() * 7)]
      @move(@x+dir[0],@y+dir[1])
      Game.scheduler.setDuration 50
    else # Known player position: try to approach
      # Create Pathfind object
      path = new ROT.Path.Dijkstra @p_x, @p_y, (x,y) =>
        # TODO: Every door considered open until seen closed
        if @x is x and @y is y
          return yes
        block = Game.isBlocked(x, y,@z,no)
        !block or Game.map(x,y).val is '+'
      tx = @x; ty = @y # workaround, it works and it's efficient! I hope...
      path.compute tx, ty, (x,y) =>
        # Compute path, then move
        if Math.abs(tx-x) < 2 and Math.abs(ty-y) < 2 then @move x, y
      Game.scheduler.setDuration 35
    Game.scheduler.next().act()

  # Act at x,y: move, or attack, or smash door (depends on what's at x,y)
  move : (x,y) ->
    return unless Game.map(x,y)
    if Game.isBlocked(x,y,@z,yes) is yes
      # Can't pass, the tile is blocked
      if Game.map(x,y).type is "door" and @p_x isnt no and @p_y isnt no
        # TODO: smash down the door. Not implemented yet
        Game.map(x,y).val = "x"
        # Door Smash!
        calc = ROT.RNG.getPercentage(); lev = 75 - 2 * Game.player.z
        #console.log calc+" > "+lev+" ?"
        if calc > lev
          Game.map(x,y).val = " "; Game.map(x,y).block = no
          Game.map(x,y).type = "floor"
    else if Math.abs(@x-x) < 2 and Math.abs(@y-y) < 2
      # Tile is not blocked and it's near enough to move there
      if x is Game.player.x and y is Game.player.y
        # Hit the player!
        Game.player.hp -= 5 + Math.floor(ROT.RNG.getUniform() * 20)
      else
        # Move there
        @x = x; @y = y
        if @x is @p_x and @y is @p_y
          # This is player's last known position but he's not here.
          # Give up on searching the player
          @p_x = no; @p_y = no
    Game.draw()

# Start the game
Game.init()
