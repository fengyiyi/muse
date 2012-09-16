http = require('http')
send = require('send')
io = require('socket.io')
fs = require('fs')

LOCATION_DIR = 'store/'

locationNames = ['DC']
locations = {}

objMap = (obj, fn) ->
  newObj = {}
  for k, v of obj
    newObj[k] = fn.call(obj, v, k)
  return newObj

simplify = (obj) ->
  objType = typeof obj
  if objType isnt 'object'
    return obj
  else
    constructorName = obj.constructor.name
    throw "Bad constructor name" unless constructorName

    if obj.simple
      simple = objMap(obj.simple(), simplify)
      simple._c_ = constructorName
      return simple

    if constructorName is 'Date'
      return {
        _c_: constructorName
        date: obj.toISOString()
      }

    if constructorName is 'Object'
      return objMap(obj, simplify)

    if constructorName is 'Array'
      return {
        _c_: constructorName
        values: obj.map(simplify)
      }

    throw "Cound not handle #{obj.constructor.name}"

unsimplify = (obj) ->
  objType = typeof obj
  if objType isnt 'object'
    return obj
  else
    constructorName = obj._c_

    if not constructorName?
      return objMap(obj, unsimplify)

    if constructorName is 'Date'
      return new Date(obj.date)

    if constructorName is 'Array'
      return obj.values.map(unsimplify)

    ctr = this[constructorName]
    throw "unknown constructor name #{constructorName}"
    delete obj._c_
    return new ctr(objMap(obj, unsimplify))


class Card
  constructor: ({@text, @created}) ->
    @created or= new Date()

  simple: ->
    return this

class Drawer
  constructor: ({cards} = {}) ->
    cards ?= []
    @cards = cards.map((c) -> new Card(c))
    @claim = null
    @semiCard = null

  simple: ->
    return {
      cards: @cards
    }

class Location
  constructor: ({@name, lastChanged, drawers}) ->
    @drawers = objMap(drawers, (d) -> new Drawer(d))
    @lastChanged = new Date(lastChanged)
    @dirty = false

  makeDirty: -> @dirty = true
  clearDirty: -> @dirty = false

  simple: ->
    return {
      name: @name
      drawers: @drawers
      lastChanged: @lastChanged
    }

# loader
locationNames.forEach (locationName) ->
  file = LOCATION_DIR + locationName + '.json'
  try
    location = unsimplify(JSON.parse(fs.readFileSync(file)))
  catch e
    location = new Location({
      name: locationName
      lastChanged: new Date()
      drawers: {}
    })

  locations[locationName] = location

# saver
setInterval((->
  locationNames.forEach (locationName) ->
    location = locations[locationName]
    return unless location.dirty
    file = LOCATION_DIR + location.name + '.json'
    data = JSON.stringify(simplify(location), null, 2)
    fs.writeFile file, data, (err) ->
      if err
        console.error("There was an error writing the file [#{file}]", err)
      else
        console.log('Location file saved')
        location.clearDirty()
      return
    return
  return
), 2000)

app = http.createServer (req, res) ->
  # your custom error-handling logic:
  error = (err) ->
    res.statusCode = err.status or 500
    res.end(err.message)

  # your custom directory handling logic:
  redirect = ->
    res.statusCode = 301;
    res.setHeader('Location', req.url + '/')
    res.end('Redirecting to ' + req.url + '/')

  if req.url is '/'
    res.statusCode = 302
    res.setHeader('Location', '/DC')
    res.end('Redirecting to /DC')
  else if match = req.url.match(/^\/([a-z]+)$/i)
    send(req, 'index.html')
      .root('public')
      .on('error', error)
      .pipe(res)
  else if req.url is '/_archive'
    archive()
    res.end('A reset has been sent')
  else
    send(req, req.url)
      .root('public')
      .on('error', error)
      .pipe(res)

  return

io = io.listen(app)
app.listen(8181)

io.sockets.on 'connection', (socket) ->
  client = {
    claim: null
  }

  # when the client emits 'adduser', this listens and executes
  socket.on 'register', (locationName) ->
    location = locations[locationName]
    return unless location

    # send client to location
    socket.join(client.locationName = location.name)

    # echo to client they've connected
    socket.emit('drawerInfo', location.drawers)
    return

  socket.on 'drawerClaim', (drawer) ->
    location = locations[client.locationName]
    if drawer.match(/^\d+_\d+$/) and location and (location.drawers[drawer] or= new Drawer()).claim is null
      clinetUnclaim()
      location.drawers[drawer].claim = client
      client.claim = drawer
      socket.emit('drawerClaimResult', 'OK')
      socket.broadcast.to(location.name).emit('drawerClaim', drawer)
    else
      socket.emit('drawerClaimResult', 'FAIL')
    return

  socket.on 'drawerUnclaim', clinetUnclaim = ->
    drawer = client.claim
    return unless drawer
    location = locations[client.locationName]
    return unless location
    location.drawers[drawer].claim = null
    client.claim = null
    socket.broadcast.to(location.name).emit('drawerUnclaim', drawer)
    return

  socket.on 'makeCard', (text) ->
    drawer = client.claim
    location = locations[client.locationName]
    if drawer and location
      card = new Card({text})
      location.drawers[drawer].cards.unshift(card)
      socket.emit('makeCardResult', 'OK')
      socket.broadcast.to(location.name).emit('putCard', drawer, card)
      location.makeDirty()
    else
      socket.emit('makeCardResult', 'FAIL')
    return

  socket.on 'disconnect', clinetUnclaim
  return

archive = ->
  for locationName, location of locations
    location.drawers = {}
    location.dirty = true
  io.sockets.emit('reset')
  return

# 'CRON' job :-)
offset = -7 # PST
getDate = -> (new Date(Date.now() + offset * 60 * 60 * 1000)).getUTCDate()
lastDate = getDate()
setInterval((->
  nowDate = getDate()
  return if lastDate is nowDate
  archive()
  lastDate = nowDate
), 10000)




