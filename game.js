var Camera, Game, Monster, Player;

Array.prototype["delete"] = function(o) {
  return this.splice(this.indexOf(o), 1);
};

Game = {
  w: 50,
  h: 50,
  screen_w: 80,
  screen_h: 25,
  debug: false,
  maps: [],
  monsters: [],
  init: function() {
    console.log("A Demon's Maze - WIP");
    if (ROT.isSupported() === false) {
      document.getElementById("gameContainer").innerHTML = "<h3>Oh! Your browser does not support HTML5 Canvas!</h3>\n<p>Try Firefox or Chrome!</p>";
      return;
    }
    this.display = new ROT.Display({
      width: this.screen_w,
      height: this.screen_h
    });
    document.getElementById("gameContainer").appendChild(this.display.getContainer());
    this.scheduler = new ROT.Scheduler.Action();
    this.level = 0;
    this.camera = new Camera(0, 0, this.screen_w, this.screen_h);
    this.newLevel(0);
    this.scheduler.next().act();
    return console.log("Done init");
  },
  newLevel: function(l, moveTo) {
    var i, loc, loc2, monster, oldLevel, times, _i, _j, _k, _len, _len1, _ref, _ref1;
    moveTo = moveTo || true;
    oldLevel = this.level;
    if (moveTo === true) {
      this.level = l;
    }
    if (this.maps[l] === void 0) {
      console.log("Generating Level: " + l);
      this.generateMap(l);
      loc = this.getEmptyLoc(false);
      if (oldLevel !== l) {
        this.map(loc.x, loc.y).type = "stairs";
        this.map(loc.x, loc.y).val = oldLevel > l ? "<" : ">";
        console.log("Placed " + this.map(loc.x, loc.y).val + " tile");
      }
      if (this.player === void 0 || this.player === null) {
        this.player = new Player(loc.x, loc.y);
        this.scheduler.add(this.player, true, 0);
      }
      loc2 = this.getEmptyLoc(true);
      this.map(loc2.x, loc2.y).type = "stairs";
      this.map(loc2.x, loc2.y).val = oldLevel > l ? ">" : "<";
    } else {
      console.log("Loading Level: " + l);
    }
    if (this.player.pos[l] !== void 0) {
      this.player.x = this.player.pos[l].x;
      this.player.y = this.player.pos[l].y;
    } else {
      this.player.x = loc.x;
      this.player.y = loc.y;
    }
    Game.camera.setCenter(this.player.x, this.player.y);
    if (!this.monsters[l]) {
      this.monsters[l] = [];
      times = Math.floor(ROT.RNG.getUniform() * 7);
      console.log("Generating " + (times + 1) + " monsters on floor " + l);
      for (i = _i = 1; 1 <= times ? _i <= times : _i >= times; i = 1 <= times ? ++_i : --_i) {
        loc = this.getEmptyLoc(true);
        this.monsters[l].push(new Monster(loc.x, loc.y, l));
      }
    }
    if (moveTo) {
      console.log("Player moving to level " + l);
      if (this.monsters[oldLevel]) {
        _ref = this.monsters[oldLevel];
        for (_j = 0, _len = _ref.length; _j < _len; _j++) {
          monster = _ref[_j];
          this.scheduler.remove(monster);
        }
      }
      _ref1 = this.monsters[l];
      for (_k = 0, _len1 = _ref1.length; _k < _len1; _k++) {
        monster = _ref1[_k];
        this.scheduler.add(monster, true, 50);
      }
    }
    return this.draw();
  },
  generateMap: function(l) {
    var finished, i, room, times, _ref;
    this.map_done = false;
    this.rooms_done = false;
    times = 0;
    this.maps[l] = {};
    this.digger = new ROT.Map.Digger(this.w, this.h);
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
    onlySeen = onlySeen || false;
    _results = [];
    for (key in this.maps[this.level]) {
      if (this.maps[this.level][key].seen === true || onlySeen === false) {
        _results.push(this.camera.draw(key.split(",")[0], key.split(",")[1], this.maps[this.level][key].val, this.maps[this.level][key].fg, this.maps[this.level][key].bg));
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
    return this.camera.draw(this.player.x, this.player.y, '@', "#fff", "#aa0");
  },
  inRoom: function(room, x, y) {
    if (room) {
      return (room.x1 <= x && x <= room.x2) && (room.y1 <= y && y <= room.y2);
    } else {
      return false;
    }
  },
  isBlocked: function(x, y, l, ignorePlayer) {
    var monster, _i, _len, _ref;
    l = l || this.level;
    ignorePlayer = ignorePlayer || false;
    if (!this.map(x, y)) {
      return true;
    }
    if (this.map(x, y).block === true) {
      return true;
    }
    if (ignorePlayer === false) {
      if (this.player.x === x && this.player.y === y && this.level === l) {
        return true;
      }
    }
    if (!(this.monsters && this.monsters[l])) {
      return false;
    }
    _ref = this.monsters[l];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      monster = _ref[_i];
      if (monster.x === x && monster.y === y) {
        return true;
      }
    }
    return false;
  },
  getEmptyLoc: function(awayFromPlayer) {
    var ok, r, rs, x, y;
    awayFromPlayer = awayFromPlayer || false;
    if (!this.digger) {
      return;
    }
    r = void 0;
    ok = true;
    while (r === void 0 || ok === false) {
      rs = this.digger.getRooms();
      r = rs[Math.floor(ROT.RNG.getUniform() * this.digger.getRooms().length - 1)];
      if (awayFromPlayer === false || !r || this.inRoom(r, this.player.x, this.player.y) === true) {
        ok = true;
      }
    }
    x = r.getLeft();
    +Math.floor(ROT.RNG.getUniform() * (r.getRight() - r.getLeft()));
    y = r.getTop();
    +Math.floor(ROT.RNG.getUniform() * (r.getBottom() - r.getTop()));
    return {
      x: x,
      y: y
    };
  }
};

Camera = function(x, y, w, h) {
  this.x = x;
  this.y = y;
  this.w = w;
  this.h = h;
  return this.slideOffset = 10;
};

Camera.prototype.getCenter = function() {
  return {
    x: this.x + this.w / 2,
    y: this.y + this.h / 2
  };
};

Camera.prototype.fromWorld = function(x, y) {
  return {
    x: x - this.x,
    y: y - this.y
  };
};

Camera.prototype.slide = function(x, y) {
  if (!!x) {
    this.x += Math.floor(x);
  }
  if (!!y) {
    return this.y += Math.floor(y);
  }
};

Camera.prototype.setCenter = function(x, y) {
  if (!(x && y)) {
    return;
  }
  this.x = Math.floor(x - this.w / 2);
  return this.y = Math.floor(y - this.h / 2);
};

Camera.prototype.visible = function(x, y) {
  return x > this.x && x < this.x + this.w && y > this.y && y < this.y + this.h;
};

Camera.prototype.draw = function(x, y, ch, fg, bg) {
  return Game.display.draw(x - this.x, y - this.y, ch, fg, bg);
};

Player = function(x, y) {
  this.x = x;
  this.y = y;
  this.shiftDown = false;
  this.closeDoor = false;
  this.move(this.x, this.y);
  this.pos = {};
  this.keyMap = {};
  this.keyMap[38] = this.keyMap[104] = 0;
  this.keyMap[33] = this.keyMap[105] = 1;
  this.keyMap[39] = this.keyMap[102] = 2;
  this.keyMap[34] = this.keyMap[99] = 3;
  this.keyMap[40] = this.keyMap[98] = 4;
  this.keyMap[35] = this.keyMap[97] = 5;
  this.keyMap[37] = this.keyMap[100] = 6;
  this.keyMap[36] = this.keyMap[103] = 7;
  this._onKeyUp = this.onKeyUp.bind(this);
  this._onKeyDown = this.onKeyDown.bind(this);
  return window.addEventListener("keyup", this._onKeyUp);
};

Player.prototype.act = function() {
  return window.addEventListener("keydown", this._onKeyDown);
};

Player.prototype.onKeyUp = function(e) {
  if (e.keyCode === 16) {
    return this.shiftDown = false;
  }
};

Player.prototype.onKeyDown = function(e) {
  var blocked, dir, finished, newX, newY, _ref, _ref1;
  finished = false;
  console.log("Keycode: " + e.keyCode);
  if (e.keyCode === 16) {
    this.shiftDown = true;
  } else if (e.keyCode === 67) {
    this.closeDoor = true;
  }
  if (e.keyCode === 101 || e.keyCode === 190) {
    finished = true;
    Game.scheduler.setDuration(5);
  }
  if (e.keyCode === 60 && Game.map(this.x, this.y).type === "stairs") {
    if (Game.map(this.x, this.y).val === ">" && this.shiftDown) {
      this.pos[Game.level] = {
        x: this.x,
        y: this.y
      };
      Game.newLevel(Game.level - 1);
      finished = true;
    } else if (Game.map(this.x, this.y).val === "<" && !this.shiftDown) {
      this.pos[Game.level] = {
        x: this.x,
        y: this.y
      };
      Game.newLevel(Game.level + 1);
      finished = true;
    }
    if (finished === true) {
      Game.scheduler.setDuration(5);
    }
  } else if ((36 <= (_ref = e.keyCode) && _ref <= 40) || (97 <= (_ref1 = e.keyCode) && _ref1 <= 105) && this.closeDoor === false) {
    dir = ROT.DIRS[8][this.keyMap[e.keyCode]];
    if (dir) {
      newX = this.x + dir[0];
      newY = this.y + dir[1];
      blocked = Game.isBlocked(newX, newY, Game.level, false);
      if (Game.map(newX, newY).type === "door") {
        if (this.closeDoor === true && blocked === false) {
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
      if (blocked === false && finished === false) {
        this.move(newX, newY);
        Game.draw();
        finished = true;
      }
      if (finished === true) {
        Game.scheduler.setDuration(10);
      }
    }
  }
  if (e.keyCode !== 67) {
    this.closeDoor = false;
  }
  if (finished === true) {
    window.removeEventListener("keydown", this._onKeyDown);
    return Game.scheduler.next().act();
  }
};

Player.prototype.move = function(newX, newY) {
  var onScreen;
  onScreen = Game.camera.fromWorld(newX, newY);
  if (onScreen.x > Game.camera.w - Game.camera.slideOffset) {
    Game.camera.slide(1, 0);
  } else if (onScreen.x < Game.camera.slideOffset) {
    Game.camera.slide(-1, 0);
  }
  if (onScreen.y < Game.camera.slideOffset) {
    Game.camera.slide(0, -1);
  } else if (onScreen.y > Game.camera.h - Game.camera.slideOffset) {
    Game.camera.slide(0, 1);
  }
  this.x = newX;
  return this.y = newY;
};

Player.prototype.drawMemory = function() {
  var x, y, _i, _ref, _ref1, _results;
  _results = [];
  for (x = _i = _ref = Game.camera.x, _ref1 = Game.camera.x + Game.camera.w - 1; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; x = _ref <= _ref1 ? ++_i : --_i) {
    _results.push((function() {
      var _j, _ref2, _ref3, _results1;
      _results1 = [];
      for (y = _j = _ref2 = Game.camera.y, _ref3 = Game.camera.y + Game.camera.h - 1; _ref2 <= _ref3 ? _j <= _ref3 : _j >= _ref3; y = _ref2 <= _ref3 ? ++_j : --_j) {
        if (Game.map(x, y) && Game.map(x, y).seen === true) {
          _results1.push(Game.camera.draw(x, y, Game.map(x, y).val, Game.map(x, y).fg, Game.map(x, y).bg));
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
  if (!this.fov) {
    this.fov = new ROT.FOV.PreciseShadowcasting(function(x, y) {
      return Game.isBlocked(x, y, Game.level, true) === false;
    });
  }
  return this.fov.compute(this.x, this.y, 6, function(x, y, r, v) {
    var monster, _i, _len, _ref, _results;
    if (!Game.map(x, y)) {
      return;
    }
    Game.map(x, y).seen = true;
    Game.camera.draw(x, y, Game.map(x, y).val, Game.map(x, y).fg_light, Game.map(x, y).bg_light);
    _ref = Game.monsters[Game.level];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      monster = _ref[_i];
      if (monster.x === x && monster.y === y) {
        _results.push(Game.camera.draw(x, y, monster.val, monster.fg_light, Game.map(x, y).bg_light));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  });
};

Monster = function(x, y, level, val, fg, fg_light) {
  this.x = x;
  this.y = y;
  this.z = level;
  this.p_x = false;
  this.p_y = false;
  this.val = val || "M";
  this.fg = fg || "#fff";
  return this.fg_light = fg_light || "#fff";
};

Monster.prototype.act = function() {
  var dir, path, tx, ty;
  if (this.z !== Game.level) {
    return;
  }
  if (!this.fov) {
    this.fov = new ROT.FOV.PreciseShadowcasting((function(_this) {
      return function(x, y) {
        if (_this.x === x && _this.y === y) {
          return true;
        }
        return Game.isBlocked(x, y, _this.z, false) === false;
      };
    })(this));
  }
  this.fov.compute(this.x, this.y, 8, (function(_this) {
    return function(x, y, r, v) {
      if (!Game.map(x, y)) {
        return;
      }
      if (Game.player.x === x && Game.player.y === y) {
        _this.p_x = Game.player.x;
        return _this.p_y = Game.player.y;
      }
    };
  })(this));
  if (this.p_x === false && this.p_y === false) {
    dir = ROT.DIRS[8][Math.floor(ROT.RNG.getUniform() * 7)];
    this.move(this.x + dir[0], this.y + dir[1]);
    Game.scheduler.setDuration(20);
  } else {
    path = new ROT.Path.Dijkstra(this.p_x, this.p_y, (function(_this) {
      return function(x, y) {
        if (_this.x === x && _this.y === y) {
          return true;
        }
        return Game.isBlocked(x, y, _this.z, false) === false;
      };
    })(this));
    tx = this.x;
    ty = this.y;
    path.compute(tx, ty, (function(_this) {
      return function(x, y) {
        if (Math.abs(tx - x) < 2 && Math.abs(ty - y) < 2) {
          return _this.move(x, y);
        }
      };
    })(this));
    Game.scheduler.setDuration(15);
  }
  return Game.scheduler.next().act();
};

Monster.prototype.move = function(x, y) {
  if (!Game.map(x, y)) {
    return;
  }
  if (Game.isBlocked(x, y, this.z, false) === true) {
    if (Game.map(x, y).type === "door" && this.p_x !== false && this.p_y !== false) {
      return console.log("Door Smash!");
    }
  } else if (Math.abs(this.x - x) < 2 && Math.abs(this.y - y) < 2) {
    this.x = x;
    this.y = y;
    Game.draw();
    if (this.x === this.p_x && this.y === this.p_y) {
      this.p_x = false;
      return this.p_y = false;
    }
  }
};

Game.init();
