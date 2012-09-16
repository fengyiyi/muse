// Generated by CoffeeScript 1.3.1
(function() {
  var Card, Drawer, LOCATION_DIR, Location, app, archive, fs, getDate, http, io, lastDate, locationNames, locations, objMap, offset, send, simplify, unsimplify;

  http = require('http');

  send = require('send');

  io = require('socket.io');

  fs = require('fs');

  LOCATION_DIR = 'store/';

  locationNames = ['DC'];

  locations = {};

  objMap = function(obj, fn) {
    var k, newObj, v;
    newObj = {};
    for (k in obj) {
      v = obj[k];
      newObj[k] = fn.call(obj, v, k);
    }
    return newObj;
  };

  simplify = function(obj) {
    var constructorName, objType, simple;
    objType = typeof obj;
    if (objType !== 'object') {
      return obj;
    } else {
      constructorName = obj.constructor.name;
      if (!constructorName) {
        throw "Bad constructor name";
      }
      if (obj.simple) {
        simple = objMap(obj.simple(), simplify);
        simple._c_ = constructorName;
        return simple;
      }
      if (constructorName === 'Date') {
        return {
          _c_: constructorName,
          date: obj.toISOString()
        };
      }
      if (constructorName === 'Object') {
        return objMap(obj, simplify);
      }
      if (constructorName === 'Array') {
        return {
          _c_: constructorName,
          values: obj.map(simplify)
        };
      }
      throw "Cound not handle " + obj.constructor.name;
    }
  };

  unsimplify = function(obj) {
    var constructorName, ctr, objType;
    objType = typeof obj;
    if (objType !== 'object') {
      return obj;
    } else {
      constructorName = obj._c_;
      if (!(constructorName != null)) {
        return objMap(obj, unsimplify);
      }
      if (constructorName === 'Date') {
        return new Date(obj.date);
      }
      if (constructorName === 'Array') {
        return obj.values.map(unsimplify);
      }
      ctr = this[constructorName];
      throw "unknown constructor name " + constructorName;
      delete obj._c_;
      return new ctr(objMap(obj, unsimplify));
    }
  };

  Card = (function() {

    Card.name = 'Card';

    function Card(_arg) {
      this.text = _arg.text, this.created = _arg.created;
      this.created || (this.created = new Date());
    }

    Card.prototype.simple = function() {
      return this;
    };

    return Card;

  })();

  Drawer = (function() {

    Drawer.name = 'Drawer';

    function Drawer(_arg) {
      var cards;
      cards = (_arg != null ? _arg : {}).cards;
      if (cards == null) {
        cards = [];
      }
      this.cards = cards.map(function(c) {
        return new Card(c);
      });
      this.claim = null;
      this.semiCard = null;
    }

    Drawer.prototype.simple = function() {
      return {
        cards: this.cards
      };
    };

    return Drawer;

  })();

  Location = (function() {

    Location.name = 'Location';

    function Location(_arg) {
      var drawers, lastChanged;
      this.name = _arg.name, lastChanged = _arg.lastChanged, drawers = _arg.drawers;
      this.drawers = objMap(drawers, function(d) {
        return new Drawer(d);
      });
      this.lastChanged = new Date(lastChanged);
      this.dirty = false;
    }

    Location.prototype.makeDirty = function() {
      return this.dirty = true;
    };

    Location.prototype.clearDirty = function() {
      return this.dirty = false;
    };

    Location.prototype.simple = function() {
      return {
        name: this.name,
        drawers: this.drawers,
        lastChanged: this.lastChanged
      };
    };

    return Location;

  })();

  locationNames.forEach(function(locationName) {
    var file, location;
    file = LOCATION_DIR + locationName + '.json';
    try {
      location = unsimplify(JSON.parse(fs.readFileSync(file)));
    } catch (e) {
      location = new Location({
        name: locationName,
        lastChanged: new Date(),
        drawers: {}
      });
    }
    return locations[locationName] = location;
  });

  setInterval((function() {
    locationNames.forEach(function(locationName) {
      var data, file, location;
      location = locations[locationName];
      if (!location.dirty) {
        return;
      }
      file = LOCATION_DIR + location.name + '.json';
      data = JSON.stringify(simplify(location), null, 2);
      fs.writeFile(file, data, function(err) {
        if (err) {
          console.error("There was an error writing the file [" + file + "]", err);
        } else {
          console.log('Location file saved');
          location.clearDirty();
        }
      });
    });
  }), 2000);

  app = http.createServer(function(req, res) {
    var error, match, redirect;
    error = function(err) {
      res.statusCode = err.status || 500;
      return res.end(err.message);
    };
    redirect = function() {
      res.statusCode = 301;
      res.setHeader('Location', req.url + '/');
      return res.end('Redirecting to ' + req.url + '/');
    };
    if (req.url === '/') {
      res.statusCode = 302;
      res.setHeader('Location', '/DC');
      res.end('Redirecting to /DC');
    } else if (match = req.url.match(/^\/([a-z]+)$/i)) {
      send(req, 'index.html').root('public').on('error', error).pipe(res);
    } else if (req.url === '/_archive') {
      archive();
      res.end('A reset has been sent');
    } else {
      send(req, req.url).root('public').on('error', error).pipe(res);
    }
  });

  io = io.listen(app);

  app.listen(8181);

  io.sockets.on('connection', function(socket) {
    var client, clinetUnclaim;
    client = {
      claim: null
    };
    socket.on('register', function(locationName) {
      var location;
      location = locations[locationName];
      if (!location) {
        return;
      }
      socket.join(client.locationName = location.name);
      socket.emit('drawerInfo', location.drawers);
    });
    socket.on('drawerClaim', function(drawer) {
      var location, _base;
      location = locations[client.locationName];
      if (drawer.match(/^\d+_\d+$/) && location && ((_base = location.drawers)[drawer] || (_base[drawer] = new Drawer())).claim === null) {
        clinetUnclaim();
        location.drawers[drawer].claim = client;
        client.claim = drawer;
        socket.emit('drawerClaimResult', 'OK');
        socket.broadcast.to(location.name).emit('drawerClaim', drawer);
      } else {
        socket.emit('drawerClaimResult', 'FAIL');
      }
    });
    socket.on('drawerUnclaim', clinetUnclaim = function() {
      var drawer, location;
      drawer = client.claim;
      if (!drawer) {
        return;
      }
      location = locations[client.locationName];
      if (!location) {
        return;
      }
      location.drawers[drawer].claim = null;
      client.claim = null;
      socket.broadcast.to(location.name).emit('drawerUnclaim', drawer);
    });
    socket.on('makeCard', function(text) {
      var card, drawer, location;
      drawer = client.claim;
      location = locations[client.locationName];
      if (drawer && location) {
        card = new Card({
          text: text
        });
        location.drawers[drawer].cards.unshift(card);
        socket.emit('makeCardResult', 'OK');
        socket.broadcast.to(location.name).emit('putCard', drawer, card);
        location.makeDirty();
      } else {
        socket.emit('makeCardResult', 'FAIL');
      }
    });
    socket.on('disconnect', clinetUnclaim);
  });

  archive = function() {
    var location, locationName;
    for (locationName in locations) {
      location = locations[locationName];
      location.drawers = {};
      location.dirty = true;
    }
    io.sockets.emit('reset');
  };

  offset = -7;

  getDate = function() {
    return (new Date(Date.now() + offset * 60 * 60 * 1000)).getUTCDate();
  };

  lastDate = getDate();

  setInterval((function() {
    var nowDate;
    nowDate = getDate();
    if (lastDate === nowDate) {
      return;
    }
    archive();
    return lastDate = nowDate;
  }), 10000);

}).call(this);
