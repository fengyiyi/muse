window.console ?= {
  log: -> return
  error: -> return
}

number = 14
scale = 1
drawerWidth = 60 * scale
drawerHeight = 40 * scale
drawerDepth = 40 * scale
openDepth = 27 * scale
gap = 6 * scale

# --------------------------

msgs = "
Dear DC, It's all theatre, and some of it's bad, but I still love it. - Shira
-----
Dear D.C, I've been pretty serious with New York, but if one of your fine law firms gives me a job, I'm pretty sure I'd break up with her for you. Love, a frustrated 3L.
Tho I will always love you, i don't have to like you right now.
-----
I have yet to experience another city who supports the arts with the same generosity. DC is my haven for the arts.
-----
Dear DC, you're the most kickass and most vibrant big town I've ever met. You have your own music, your own art culture, you have waterfronts and parks and rivers. There's more to you than just stately buildings filled with pretentious people, and I'm lucky to have grown up here and experienced the real dc. Best of all, you never make me feel like I'm alone, or just another number in a swarm of people on the street: you're a city that actually feels like a home. ALL my love, Lida
-----
Dear DC, thank you for letting me see your big blue sky on my way to work and during lunch. And giving me access to free education in the Smithsonian institutes. I hope to bring my children to see your beautiful museums and exhibits. One day, I will leave you to return to my home city. But I will always remember you and your sky.
-----
Dear DC, We should have gotten to know each other when we had the chance. My friend thinks you're really great. Love Gabi
-----
Dear DC, I've loved you from afar all these years. I'm looking forward to getting to know you better. Love, Becca
-----
The monuments inspire me to think of the founding principles that make our country great. They give me hope that we can remember who we are as a nation.
-----
Dear DC, I love standing next to Lincoln and looking up at a giant for democracy and freedom
-----
Hey DC, thanks for the clean ride… I like your metro
-----
Dear DC, I love you for fostering a surprising intelligent community of artists!
-----
To the District of Columbia - thank you for your hidden gardens in Georgetown
-----
In 2002, I walked for the Homeless in DC, it's the one place I felt I made a difference.
"

msgs = msgs.split('-----')

drawers = []
drawerPos = {}
drawerState = {}
for ix in [0...number]
  for iy in [0...number]
    id = "#{ix}_#{iy}"
    drawers.push(id)
    x = ix * (drawerWidth  + gap) + gap
    y = iy * (drawerHeight + gap) + gap
    drawerPos[id] = { ix, iy, x, y }
    drawerState[id] = {
      open: false
      cards: []
    }

drawers.sort (da, db) ->
  np1o2 = (number+1)
  np1o2 = (number+1) / 2
  daix = drawerPos[da].ix - np1o2
  dbix = drawerPos[db].ix - np1o2
  daiy = drawerPos[da].iy - np1o2
  dbiy = drawerPos[db].iy - np1o2
  return (2 * dbix * dbix + dbiy * dbiy) - (2 * daix * daix + daiy * daiy)


cross = (arrays) ->
  vectorName = []
  vectorValues = []
  retLength = 1
  for k,vs of arrays
    return [] unless vs.splice
    vectorName.push(k)
    vectorValues.push(vs)
    retLength *= vs.length

  return [] unless vectorValues.length

  ret = []
  i = 0
  while i < retLength
    row = {}
    k = i
    for vs,j in vectorValues
      t = k % vs.length
      row[vectorName[j]] = vs[t]
      k = Math.floor(k / vs.length)

    ret[i] = row
    i++

  return ret



make_box = (box) ->
  faces = ['front', 'back', 'right', 'left', 'top', 'bottom']
  return box.selectAll('div.box-side').data(faces)
    .enter().append('div')
    .attr('class', (d) -> 'box-side ' + d)

make_cards = (box) ->
  card = box.selectAll('div.card')
    .data((d) -> if d then cross({card: drawerState[d].cards, pos:[drawerPos[d]]}) else [])

  animEnd = ->
    #d3.select(this).attr('class', 'card normal')
    return

  cardEnter = card.enter().append('div').attr('class', 'card new')
    .on("webkitAnimationEnd", animEnd)

  cardEnter.append('div').attr('class', 'card-side back') #.append('textarea')
  cardEnter.append('div').attr('class', 'card-side front')
    .style('background-position', (d) -> "-#{d.pos.ix * drawerWidth}px -#{d.pos.iy * drawerHeight}px")

  card.exit().remove()

  card.select('.back').text((d) -> d.card)
  # .select('textarea')
  #   .property('value', (d) -> d.card)
  #   .on('click', -> d3.event.stopPropagation())

  return card


drawersCont = d3.select('.drawers-cont')

drawerChest = drawersCont.append('div')
  .attr('class', 'drawer-chest')

# drawerChest.append('div')
#   .attr('class', 'border')
#   .call(make_box)

drawerChest.selectAll('div.sep.vertical').data(d3.range(number+1))
  .enter().append('div')
    .attr('class', 'sep vertical')
    .style('left', (ix) -> ix * (drawerWidth  + gap) + gap/2 + 'px')

# drawerChest.selectAll('div.sep.horizontal').data(d3.range(number+1))
#   .enter().append('div')
#     .attr('class', 'sep horizontal')
#     .style('top',  (iy) -> iy * (drawerHeight + gap) + gap/2 + 'px')

drawerChest.selectAll('div.sep.horizontal').data(cross(x:d3.range(number), y:d3.range(number+1)))
  .enter().append('div')
    .attr('class', 'sep horizontal')
    .style('left', (d) -> d.x * (drawerWidth  + gap) + gap + 'px')
    .style('top',  (d) -> d.y * (drawerHeight + gap) + gap/2 + 'px')

drawerChest.selectAll('div.fronts.vertical').data(d3.range(number+1))
  .enter().append('div')
    .attr('class', 'fronts vertical')
    .style('left', (ix) -> ix * (drawerWidth  + gap) + 'px')

drawerChest.selectAll('div.fronts.horizontal').data(cross(x:d3.range(number), y:d3.range(number+1)))
  .enter().append('div')
    .attr('class', 'fronts horizontal')
    .style('left', (d) -> d.x * (drawerWidth  + gap) + gap + 'px')
    .style('top',  (d) -> d.y * (drawerHeight + gap) + 'px')

drawerClassFn = (d) ->
  return [
    'drawer'
    #"x#{drawerPos[d].ix}y#{drawerPos[d].iy}"
    if drawerState[d].open then 'open' else 'closed'
    if drawerState[d].cards.length then 'carded' else 'cardless'
  ].join(' ')

myDrawer = null
box_click = (d) ->
  if myDrawer
    drawerState[myDrawer].open = false
    notify_change?(myDrawer)

  if myDrawer is d
    myDrawer = null
    #drawerChest.attr('class', "drawer-chest")
  else
    myDrawer = d
    #drawerChest.attr('class', "drawer-chest focus focus-x#{d.ix}y#{d.iy}")
    drawerState[d].open = true
    if drawerState[d].open and drawerState[d].cards.length is 0
      drawerState[d].cards.push(msgs[Math.floor(Math.random() * msgs.length)])
    notify_change?(d)

  update_drawers()
  return

drawerChest.selectAll('div.drawer').data(drawers)
  .enter().append('div')
  .attr('class', drawerClassFn)
  .style('left', (d) -> drawerPos[d].x + 'px')
  .style('top',  (d) -> drawerPos[d].y + 'px')
  .on('click', box_click)
  .call(make_box)

update_drawers = ->
  drawerChest.selectAll('div.drawer')
    .attr('class', drawerClassFn)
    .call(make_cards)
  return

update_drawers()

editCont = d3.select('.edit-cont')
  .style('display', 'none')

# -------------------------------------------------------
# -------------------------------------------------------

if window.io
  console.log 'IO detected'

  socket = io.connect()

  socket.on 'connect', ->
    socket.emit('addClient', 'dc')
    return

  socket.on 'updateDrawers', (dr) ->
    console.log 'DRAWERS!', dr
    for k,v of dr
      drawerState[k] = v or { open: false, cards: [] }
    update_drawers()
    return

  socket.on 'drawerChange', (drawer, state) ->
    console.log 'GOT drawerChange', drawer
    for d in drawers
      if d is drawer
        drawerState[d] = state
        update_drawers()
        return
    return

  notify_change = (d) ->
    socket.emit('drawerChange', d, drawerState[d])
    return
else
  console.log 'IO not detected :-('

  for d in drawers
    d.cards = if Math.random() > 0.85 then [msgs[Math.floor(Math.random() * msgs.length)]] else []
