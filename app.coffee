http = require('http')
send = require('send')
io = require('socket.io')
fs = require('fs')

LOCATION_DIR = 'store/'

locationNames = ['dc']
locations = {}

# loader
for locationName in locationNames
  file = LOCATION_DIR + locationName + '.json'
  json = fs.readFileSync file
  try
    json = JSON.parse(json)
  catch e
    json = {
      dirty: false
      lastChanged: new Date()
      drawers: {}
    }

  locations[locationName] = json

# saver
setInterval((->
  for locationName in locationNames
    do (locationName) ->
      locationSpec = locations[locationName]
      return unless locationSpec.dirty
      file = LOCATION_DIR + locationName + '.json'
      data = JSON.stringify(locationSpec, null, 2)
      fs.writeFile file, data, (err) ->
        if err
          console.error("There was an error writing the file [#{file}]", err)
        else
          console.log('Location file saved')
          locationSpec.dirty = false
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
    res.setHeader('Location', '/dc')
    res.end('Redirecting to /dc')
  else if match = req.url.match(/^\/(\w+)$/)
    send(req, 'index.html')
      .root('public')
      .on('error', error)
      .pipe(res)
  else
    send(req, req.url)
      .root('public')
      .on('error', error)
      .pipe(res)

  return

io = io.listen(app)
app.listen(8181)

io.sockets.on 'connection', (socket) ->
  client = {}

  # when the client emits 'adduser', this listens and executes
  socket.on 'addClient', (locationStr) ->
    client.location = locationStr
    location = locations[client.location]

    # send client to location
    socket.join(client.location)

    # echo to client they've connected
    socket.emit('updateDrawers', location.drawers)
    return

  socket.on 'drawerChange', (drawer, state) ->
    location = locations[client.location]
    location.drawers[drawer] = state
    socket.broadcast.to(client.location).emit('drawerChange', drawer, state)
    location.dirty = true
    return

  return
