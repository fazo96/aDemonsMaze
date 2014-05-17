var Game, Player;

Game = {
  display: null,
  engine: null,
  w: 80,
  h: 25,
  scheduler: null,
  player: null,
  maps: [],
  init: function() {
    console.log("Experimenting with rot.js ...");
    this.display = new ROT.Display();
    document.body.appendChild(this.display.getContainer());
    this.scheduler = new ROT.Scheduler.Simple();
    this.engine = new ROT.Engine(this.scheduler);
    this.newLevel(0);
    this.engine.start();
    return console.log("Done init");
  },
  newLevel: function(l, putUpStairs) {
    var loc, loc2, up;
    up = putUpStairs || false;
    this.level = l;
    console.log("Level: " + this.level);
    if (this.maps[this.level] === void 0) {
      this.generateMap(this.level);
      loc = this.getEmptyLoc();
      if (up) {
        this.map(loc.x, loc.y).type = "stairs";
        this.map(loc.x, loc.y).val = "<";
      }
      if (this.player === void 0 || this.player === null) {
        this.player = new Player(loc.x, loc.y);
        this.scheduler.add(this.player, true);
      }
      loc2 = this.getEmptyLoc();
      while (loc2.x === loc.x && loc2.y === loc.y) {
        loc2 = this.getEmptyLoc();
      }
      this.map(loc2.x, loc2.y).type = "stairs";
      this.map(loc2.x, loc2.y).val = ">";
    }
    if (this.player.pos[this.level] !== void 0) {
      this.player.x = this.player.pos[this.level].x;
      this.player.y = this.player.pos[this.level].y;
    } else {
      this.player.x = loc.x;
      this.player.y = loc.y;
    }
    return this.draw();
  },
  generateMap: function(l) {
    var finished, i, room, times, _ref;
    this.map_done = false;
    this.rooms_done = false;
    times = 0;
    this.maps[l] = {};
    this.digger = new ROT.Map.Digger();
    finished = this.digger.create((function(_this) {
      return function(x, y, solid) {
        var key;
        key = x + "," + y;
        _this.maps[l][key] = {
          val: solid ? " " : ".",
          seen: false,
          type: solid ? "wall" : "floor",
          block: solid ? true : false,
          fg: solid ? "#000" : "#777",
          bg: solid ? "#444" : "#000",
          fg_light: solid ? "#000" : "#fff",
          bg_light: solid ? "#660" : "#aa0"
        };
        times++;
        if (times === _this.w * _this.h) {
          _this.map_done = true;
          return console.log("[Map:" + l + "] Generated structure");
        }
      };
    })(this));
    console.log("[Map:" + l + "] Finalizing map...");
    _ref = this.digger.getRooms();
    for (i in _ref) {
      room = _ref[i];
      if (!room.getDoors) {
        continue;
      }
      room.getDoors((function(_this) {
        return function(x, y) {
          var k;
          k = x + "," + y;
          _this.maps[l][k].val = "+";
          _this.maps[l][k].type = "door";
          _this.maps[l][k].fg = "#3a261a";
          _this.maps[l][k].block = true;
          return _this.maps[l][k].fg_light = "#584338";
        };
      })(this));
      if (i === this.digger.getRooms().length - 1) {
        this.rooms_done = true;
      }
    }
    return console.log("[Map:" + l + "] Finished");
  },
  map: function(x, y) {
    return this.maps[this.level][x + "," + y];
  },
  drawMap: function(onlySeen) {
    var key, _results;
    if (!onlySeen) {
      onlySeen = false;
    }
    _results = [];
    for (key in this.maps[this.level]) {
      if (this.maps[this.level][key].seen === true || onlySeen === false) {
        _results.push(this.display.draw(key.split(",")[0], key.split(",")[1], this.maps[this.level][key].val, this.maps[this.level][key].fg, this.maps[this.level][key].bg));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  },
  draw: function() {
    if (!this.map_done) {
      return;
    }
    this.display.clear();
    this.player.drawMemory();
    this.player.drawVisible();
    return this.display.draw(this.player.x, this.player.y, '@', "#fff", "#aa0");
  },
  getEmptyLoc: function() {
    var room, rs, x, y;
    if (!this.digger) {
      return;
    }
    room = void 0;
    while (room === void 0) {
      rs = this.digger.getRooms();
      room = rs[Math.floor(ROT.RNG.getUniform() * this.digger.getRooms().length - 1)];
    }
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

Player = function(x, y) {
  this.x = x;
  this.y = y;
  this.shiftDown = false;
  this.closeDoor = false;
  this.move(this.x, this.y);
  this.pos = {};
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
    return this.shiftDown = false;
  }
};

Player.prototype.onKeyDown = function(e) {
  var dir, finished, newX, newY, _ref;
  finished = false;
  if (e.keyCode === 16) {
    this.shiftDown = true;
  } else if (e.keyCode === 67) {
    this.closeDoor = true;
  }
  if (e.keyCode === 60 && Game.map(this.x, this.y).type === "stairs") {
    if (Game.map(this.x, this.y).val === ">" && this.shiftDown) {
      this.pos[Game.level] = {
        x: this.x,
        y: this.y
      };
      Game.newLevel(--Game.level, true);
      finished = true;
    } else if (Game.map(this.x, this.y).val === "<" && !this.shiftDown) {
      this.pos[Game.level] = {
        x: this.x,
        y: this.y
      };
      Game.newLevel(++Game.level);
      finished = true;
    }
  } else if ((36 <= (_ref = e.keyCode) && _ref <= 40)) {
    dir = ROT.DIRS[8][this.keyMap[e.keyCode]];
    newX = this.x + dir[0];
    newY = this.y + dir[1];
    if (Game.map(newX, newY).type === "door") {
      if (this.closeDoor === true && Game.map(newX, newY).block === false) {
        Game.map(newX, newY).val = "+";
        Game.map(newX, newY).block = true;
        Game.draw();
        finished = true;
      } else if (this.closeDoor === false && Game.map(newX, newY).val === "+") {
        Game.map(newX, newY).val = "\'";
        Game.map(newX, newY).block = false;
        Game.draw();
        finished = true;
      }
    }
    if (Game.map(newX, newY).block === false && finished === false) {
      this.move(newX, newY);
      Game.draw();
      finished = true;
    }
  }
  if (e.keyCode !== 67) {
    this.closeDoor = false;
  }
  if (finished) {
    window.removeEventListener("keydown", this._onKeyDown);
    return Game.engine.unlock();
  }
};

Player.prototype.move = function(newX, newY) {
  this.x = newX;
  return this.y = newY;
};

Player.prototype.drawMemory = function() {
  var x, y, _i, _ref, _results;
  _results = [];
  for (x = _i = 0, _ref = Game.w - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; x = 0 <= _ref ? ++_i : --_i) {
    _results.push((function() {
      var _j, _ref1, _results1;
      _results1 = [];
      for (y = _j = 0, _ref1 = Game.h - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; y = 0 <= _ref1 ? ++_j : --_j) {
        if (Game.map(x, y).seen === true) {
          _results1.push(Game.display.draw(x, y, Game.map(x, y).val, Game.map(x, y).fg, Game.map(x, y).bg));
        } else {
          _results1.push(void 0);
        }
      }
      return _results1;
    })());
  }
  return _results;
};

Player.prototype.drawVisible = function() {
  var fov;
  fov = new ROT.FOV.PreciseShadowcasting(function(x, y) {
    if (!Game.map(x, y)) {
      return false;
    }
    return Game.map(x, y).block !== true;
  });
  return fov.compute(this.x, this.y, 6, function(x, y, r, v) {
    if (!Game.map(x, y)) {
      return;
    }
    Game.map(x, y).seen = true;
    return Game.display.draw(x, y, Game.map(x, y).val, Game.map(x, y).fg_light, Game.map(x, y).bg_light);
  });
};
