var Game, Player, split;

Game = {
  display: null,
  map: {},
  engine: null,
  scheduler: null,
  player: null,
  init: function() {
    var freeCells, loc;
    console.log("Experimenting with rot.js ...");
    this.display = new ROT.Display();
    document.body.appendChild(this.display.getContainer());
    freeCells = this.generateMap();
    this.scheduler = new ROT.Scheduler.Simple();
    this.engine = new ROT.Engine(this.scheduler);
    loc = this.getEmptyLocation(freeCells);
    this.player = new Player(loc.x, loc.y);
    this.scheduler.add(this.player, true);
    this.engine.start();
    return this.draw();
  },
  generateMap: function() {
    var digger, freeCells;
    digger = new ROT.Map.Digger();
    freeCells = [];
    digger.create((function(_this) {
      return function(x, y, solid) {
        var key;
        key = x + "," + y;
        if (!solid) {
          freeCells.push(key);
        }
        return _this.map[key] = {
          val: solid ? " " : ".",
          seen: false,
          solid: solid,
          fg: solid ? "#000" : "#fff",
          bg: solid ? "#444" : "#000"
        };
      };
    })(this));
    return freeCells;
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
    this.drawMap(true);
    this.player.drawVisible();
    return this.display.draw(this.player.x, this.player.y, '@', "#fff", "#aa0");
  },
  getEmptyLocation: function(freeCells) {
    var index, key;
    index = Math.floor(ROT.RNG.getUniform() * freeCells.length);
    key = freeCells.splice(index, 1)[0];
    return split(key);
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
  return this.move(this.x, this.y);
};

Player.prototype.act = function() {
  Game.engine.lock();
  return window.addEventListener("keydown", this);
};

Player.prototype.handleEvent = function(e) {
  var dir, keyMap, newKey, newX, newY, _ref;
  keyMap = {};
  keyMap[38] = 0;
  keyMap[33] = 1;
  keyMap[39] = 2;
  keyMap[34] = 3;
  keyMap[40] = 4;
  keyMap[35] = 5;
  keyMap[37] = 6;
  keyMap[36] = 7;
  if (!((36 <= (_ref = e.keyCode) && _ref <= 40))) {
    return;
  }
  dir = ROT.DIRS[8][keyMap[e.keyCode]];
  newX = this.x + dir[0];
  newY = this.y + dir[1];
  newKey = newX + "," + newY;
  if (!!Game.map[newKey].solid) {
    return;
  }
  this.move(newX, newY);
  window.removeEventListener("keydown", this);
  Game.draw();
  return Game.engine.unlock();
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
    return !map[x + "," + y].solid;
  });
  return fov.compute(this.x, this.y, 10, function(x, y, r, v) {
    var color;
    if (!map[x + "," + y]) {
      return;
    }
    map[x + "," + y].seen = true;
    color = map[x + "," + y].solid ? "#660" : "#aa0";
    return Game.display.draw(x, y, map[x + "," + y].val, "#fff", color);
  });
};
