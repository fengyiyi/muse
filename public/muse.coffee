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

writerWidth = 600;
writerHeight = 400;

$totalInnerWidth =  (drawerWidth  + gap) * (number - 1);
$totalInnerHeight = (drawerHeight + gap) * (number - 1);
$totalOuterWidth =  $totalInnerWidth  + drawerWidth  + gap*2;
$totalOuterHeight = $totalInnerHeight + drawerHeight + gap*2;

# --------------------------

drawers = []
drawerPos = {}
for ix in [0...number]
  for iy in [0...number]
    id = "#{ix}_#{iy}"
    drawers.push(id)
    x = ix * (drawerWidth  + gap) + gap
    y = iy * (drawerHeight + gap) + gap
    drawerPos[id] = { ix, iy, x, y }


drawerState = {}
resetDrawerState = ->
  for d in drawers
    drawerState[d] = {
      open: false
      cards: []
    }
  return
resetDrawerState()

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


next = (fn) -> setTimeout(fn, 100)

make_box = (box) ->
  faces = ['front', 'back', 'right', 'left', 'top', 'bottom']
  return box.selectAll('div.box-side').data(faces)
    .enter().append('div')
    .attr('class', (d) -> 'box-side ' + d)

make_cards = (box) ->
  card = box.selectAll('div.card')
    .data((d) -> if d then cross({card: drawerState[d].cards.map((c) -> c.text), pos:[drawerPos[d]]}) else [])

  animEnd = ->
    el = d3.select(this)
    next ->
      el.attr('class', 'card')
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
drawerClick = (d) ->
  return if drawerState[d].open

  drawerClaim d, (res) ->
    console.log 'claim result:', res
    return unless res is 'OK'

    if myDrawer
      drawerState[myDrawer].open = false
      notifyChange(myDrawer)

    if myDrawer is d
      myDrawer = null
      #drawerChest.attr('class', "drawer-chest")
    else
      myDrawer = d
      #drawerChest.attr('class', "drawer-chest focus focus-x#{d.ix}y#{d.iy}")
      drawerState[d].open = true
      if drawerState[d].cards.length is 0
        drawerState[d].cards.push('')

      makeWriter(d)
      notifyChange(d)

    updateDrawers()
    return
  return

drawerChest.selectAll('div.drawer').data(drawers)
  .enter().append('div')
  .attr('class', drawerClassFn)
  .style('left', (d) -> drawerPos[d].x + 'px')
  .style('top',  (d) -> drawerPos[d].y + 'px')
  .on('click', drawerClick)
  .call(make_box)

updateDrawers = ->
  drawerChest.selectAll('div.drawer')
    .attr('class', drawerClassFn)
    .call(make_cards)
  return

updateDrawers()

makeWriter = closeWriter = null
do ->
  writerDrawer = null
  makeWriter = (drawer, delay = 2000) ->
    setTimeout((->
      makeCard '', ->
        editCont.style('display', null)
        writerDrawer = drawer
        editor.property('value', '')  # drawerState[writerDrawer].cards[0].text
        writer
          .style('left', (d) -> drawerPos[writerDrawer].x + 'px')
          .style('top',  (d) -> (drawerPos[writerDrawer].y - drawerHeight) + 'px')
          .style('width', drawerWidth + 'px')
          .style('height', drawerHeight + 'px')
          .style('border-radius', '0px')
          .transition()
            .duration(1000)
            .delay(500)
            .style('left', ($totalOuterWidth - writerWidth)/2 + 'px')
            .style('top',  ($totalOuterHeight - writerHeight)/2 + 'px')
            .style('width', writerWidth + 'px')
            .style('height', writerHeight + 'px')
            .style('border-radius', '3px')
            .each('end', -> editor.node().focus())
        return
    ), delay)
    return

  closeWriter = ->
    console.log 'closeWriter', writerDrawer
    return unless writerDrawer
    drawerState[writerDrawer].cards[0] = editor.property('value')
    notifyChange(writerDrawer)
    updateDrawers(writerDrawer)
    editCont.style('display', 'none')
    writerDrawer = null
    return

  d3.select(document)
    .on('click.writer', closeWriter)

  editCont = d3.select('.edit-cont')
    .style('display', 'none')

  writer = editCont.append('div')
    .attr('class', 'writer')
    .on('click', -> d3.event.stopPropagation())

  editor = writer.append('textarea')
    .on('keyup', ->
      updateCard editor.property('value'), (res) ->
        console.log 'updateCardResult', res
        return
      return
    )

  writer.append('button')
    .text('Close')
    .on('click', closeWriter)

  return

# makeWriter('5_5', 100)

hideLoading = ->
  d3.select('.loading-cont')
    .style('opacity', 1)
    .transition()
    .duration(1000)
      .style('opacity', 0)
      .remove()

# -------------------------------------------------------
# -------------------------------------------------------

drawerClaim = (d, cb) -> setTimeout(cb, 1, 'OK')
makeCard = (text, cb) -> setTimeout(cb, 1, 'OK')
updateCard = (text, cb) -> setTimeout(cb, 1, 'OK')
notifyChange = -> return
do ->
  if window.io
    console.log 'IO detected'

    socket = io.connect()

    socket.on 'connect', ->
      socket.emit('register', 'DC')
      return

    socket.on 'drawerInfo', (dr) ->
      console.log 'DRAWER INFO:', dr
      for ix in [0...number]
        for iy in [0...number]
          id = "#{ix}_#{iy}"
          drawerState[id] = {
            cards: dr[id]?.cards or []
            open:  dr[id]?.claimed or false
          }
      updateDrawers()
      hideLoading()
      return

    # socket.on 'putCard', (drawer, card) ->
    #   return unless drawer.match(/^\d+_\d+$/)
    #   console.log 'GOT putCard', drawer, card
    #   drawerState[drawer].cards.unshift(card)
    #   updateDrawers()
    #   return

    socket.on 'drawerClaim', (drawer) ->
      return unless drawer.match(/^\d+_\d+$/)
      drawerState[drawer].open = true
      return

    socket.on 'drawerUnclaim', (drawer) ->
      return unless drawer.match(/^\d+_\d+$/)
      drawerState[drawer].open = false
      return

    socket.on 'reset', ->
      console.log 'GOT reset'
      resetDrawerState()
      updateDrawers()
      return

    do ->
      callback = null
      socket.on 'drawerClaimResult', (res) ->
        callback?(res)
        callback = null
        return

      drawerClaim = (d, cb) ->
        callback = cb
        socket.emit 'drawerClaim', d
        return

    do ->
      callback = null
      socket.on 'makeCardResult', (res) ->
        callback?(res)
        callback = null
        return

      makeCard = (text, cb) ->
        callback = cb
        socket.emit 'makeCard', text
        return

    do ->
      callback = null
      socket.on 'updateCardResult', (res) ->
        callback?(res)
        callback = null
        return

      updateCard = (text, cb) ->
        callback = cb
        socket.emit 'updateCard', text
        return

    notifyChange = (d) ->
      socket.emit('drawerChange', d, drawerState[d])
      return
  else
    console.log 'IO not detected :-('

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

    for d in drawers
      drawerState[d] = {
        cards: if Math.random() > 0.85 then [{ text: msgs[Math.floor(Math.random() * msgs.length)] }] else []
        open: false
      }

    hideLoading()




