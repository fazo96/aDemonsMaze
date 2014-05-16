var Game, Player, split;

Game = {
  display: null,
  w: 80,
  h: 25,
  engine: null,
  scheduler: null,
  player: null,
  init: function() {
    console.log("Experimenting with rot.js ...");
    this.display = new ROT.Display();
    document.body.appendChild(this.display.getContainer());
    this.scheduler = new ROT.Scheduler.Simple();
    this.engine = new ROT.Engine(this.scheduler);
    this.newLevel();
    return console.log("Done init");
  },
  newLevel: function() {
    var freeCells, loc;
    freeCells = this.generateMap();
    loc = this.getEmptyLoc();
    this.scheduler.remove(this.player);
    this.player = new Player(loc.x, loc.y);
    this.scheduler.add(this.player, true);
    loc = this.getEmptyLoc();
    this.map[loc.x + "," + loc.y].type = "stairs";
    this.map[loc.x + "," + loc.y].val = ">";
    this.engine.start();
    return this.draw();
  },
  generateMap: function() {
    var freeCells, room, _i, _len, _ref, _results;
    this.map = {};
    this.digger = new ROT.Map.Digger();
    freeCells = [];
    this.digger.create((function(_this) {
      return function(x, y, solid) {
        var key;
        key = x + "," + y;
        if (!solid) {
          freeCells.push(key);
        }
        return _this.map[key] = {
          val: solid ? " " : ".",
          seen: false,
          type: solid ? "wall" : "floor",
          block: solid ? true : false,
          fg: solid ? "#000" : "#fff",
          bg: solid ? "#444" : "#000",
          fg_light: solid ? "#000" : "#fff",
          bg_light: solid ? "#660" : "#aa0"
        };
      };
    })(this));
    _ref = this.digger.getRooms();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      room = _ref[_i];
      _results.push(room.getDoors((function(_this) {
        return function(x, y) {
          _this.map[x + "," + y].val = "+";
          _this.map[x + "," + y].type = "door";
          _this.map[x + "," + y].fg = "#3a261a";
          _this.map[x + "," + y].block = true;
          return _this.map[x + "," + y].fg_light = "#584338";
        };
      })(this)));
    }
    return _results;
  },
  drawMap: function(onlySeen) {
    var a, key, _results;
    _results = [];
    for (key in this.map) {
      a = split(key);
      if (this.map[key].seen === true || !onlySeen) {
        _results.push(this.display.draw(a.x, a.y, this.map[key].val, this.map[key].fg, this.map[key].bg));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  },
  draw: function() {
    this.display.clear();
    this.drawMap(false);
    this.player.drawVisible();
    return this.display.draw(this.player.x, this.player.y, '@', "#fff", "#aa0");
  },
  getEmptyLoc: function() {
    var room, rs, x, y;
    if (!this.digger) {
      return;
    }
    rs = this.digger.getRooms();
    room = rs[Math.floor(ROT.RNG.getUniform() * this.digger.getRooms().length - 1)];
    x = room.getLeft();
    +Math.floor(ROT.RNG.getUniform() * (room.getRight() - room.getLeft()));
    y = room.getTop();
    +Math.floor(ROT.RNG.getUniform() * (room.getBottom() - room.getTop()));
    return {
      x: x,
      y: y
    };
  }
};

split = function(v) {
  var parts, x, y;
  parts = v.split(",");
  x = parseInt(parts[0]);
  y = parseInt(parts[1]);
  return {
    x: x,
    y: y
  };
};

Player = function(x, y) {
  this.x = x;
  this.y = y;
  this.shiftDown = false;
  this.move(this.x, this.y);
  this.keyMap = {};
  this.keyMap[38] = 0;
  this.keyMap[33] = 1;
  this.keyMap[39] = 2;
  this.keyMap[34] = 3;
  this.keyMap[40] = 4;
  this.keyMap[35] = 5;
  this.keyMap[37] = 6;
  this.keyMap[36] = 7;
  this._onKeyUp = this.onKeyUp.bind(this);
  this._onKeyDown = this.onKeyDown.bind(this);
  return window.addEventListener("keyup", this._onKeyUp);
};

Player.prototype.act = function() {
  Game.engine.lock();
  return window.addEventListener("keydown", this._onKeyDown);
};

Player.prototype.onKeyUp = function(e) {
  if (e.keyCode === 16) {
    this.shiftDown = false;
    return console.log("Shift UP");
  }
};

Player.prototype.onKeyDown = function(e) {
  var dir, finished, newKey, newX, newY, _ref;
  console.log(e.keyCode);
  finished = false;
  if (e.keyCode === 16) {
    this.shiftDown = true;
    console.log("Shift Down");
  } else {

  }
  if (e.keyCode === 60 && this.shiftDown && Game.map[this.x + "," + this.y].type === "stairs") {
    if (Game.map[this.x + "," + this.y].val === ">") {
      Game.newLevel();
      finished = true;
    }
  } else if ((36 <= (_ref = e.keyCode) && _ref <= 40)) {
    dir = ROT.DIRS[8][this.keyMap[e.keyCode]];
    newX = this.x + dir[0];
    newY = this.y + dir[1];
    newKey = newX + "," + newY;
    if (Game.map[newKey].block === false) {
      this.move(newX, newY);
      finished = true;
    } else if (Game.map[newKey].type === "door") {
      Game.map[newKey].val = "\'";
      Game.map[newKey].block = false;
      finished = true;
    }
  }
  Game.draw();
  if (finished) {
    window.removeEventListener("keydown", this._onKeyDown);
    return Game.engine.unlock();
  }
};

Player.prototype.move = function(newX, newY) {
  this.x = newX;
  return this.y = newY;
};

Player.prototype.drawVisible = function() {
  var fov, map;
  map = Game.map;
  fov = new ROT.FOV.PreciseShadowcasting(function(x, y) {
    if (!map[x + "," + y]) {
      return false;
    }
    return map[x + "," + y].block !== true;
  });
  return fov.compute(this.x, this.y, 6, function(x, y, r, v) {
    if (!map[x + "," + y]) {
      return;
    }
    map[x + "," + y].seen = true;
    return Game.display.draw(x, y, map[x + "," + y].val, map[x + "," + y].fg_light, map[x + "," + y].bg_light);
  });
};
