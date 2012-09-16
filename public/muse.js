// Generated by CoffeeScript 1.3.1
(function() {
  var $totalInnerHeight, $totalInnerWidth, $totalOuterHeight, $totalOuterWidth, closeWriter, cross, drawerChest, drawerClaim, drawerClassFn, drawerClick, drawerDepth, drawerHeight, drawerPos, drawerState, drawerWidth, drawers, drawersCont, gap, hideLoading, id, ix, iy, makeCard, makeWriter, make_box, make_cards, myDrawer, next, notifyChange, number, openDepth, resetDrawerState, scale, updateDrawers, writerHeight, writerWidth, x, y, _i, _j;

  if (window.console == null) {
    window.console = {
      log: function() {},
      error: function() {}
    };
  }

  number = 14;

  scale = 1;

  drawerWidth = 60 * scale;

  drawerHeight = 40 * scale;

  drawerDepth = 40 * scale;

  openDepth = 27 * scale;

  gap = 6 * scale;

  writerWidth = 600;

  writerHeight = 400;

  $totalInnerWidth = (drawerWidth + gap) * (number - 1);

  $totalInnerHeight = (drawerHeight + gap) * (number - 1);

  $totalOuterWidth = $totalInnerWidth + drawerWidth + gap * 2;

  $totalOuterHeight = $totalInnerHeight + drawerHeight + gap * 2;

  drawers = [];

  drawerPos = {};

  for (ix = _i = 0; 0 <= number ? _i < number : _i > number; ix = 0 <= number ? ++_i : --_i) {
    for (iy = _j = 0; 0 <= number ? _j < number : _j > number; iy = 0 <= number ? ++_j : --_j) {
      id = "" + ix + "_" + iy;
      drawers.push(id);
      x = ix * (drawerWidth + gap) + gap;
      y = iy * (drawerHeight + gap) + gap;
      drawerPos[id] = {
        ix: ix,
        iy: iy,
        x: x,
        y: y
      };
    }
  }

  drawerState = {};

  resetDrawerState = function() {
    var d, _k, _len;
    for (_k = 0, _len = drawers.length; _k < _len; _k++) {
      d = drawers[_k];
      drawerState[d] = {
        open: false,
        cards: []
      };
    }
  };

  resetDrawerState();

  drawers.sort(function(da, db) {
    var daix, daiy, dbix, dbiy, np1o2;
    np1o2 = number + 1;
    np1o2 = (number + 1) / 2;
    daix = drawerPos[da].ix - np1o2;
    dbix = drawerPos[db].ix - np1o2;
    daiy = drawerPos[da].iy - np1o2;
    dbiy = drawerPos[db].iy - np1o2;
    return (2 * dbix * dbix + dbiy * dbiy) - (2 * daix * daix + daiy * daiy);
  });

  cross = function(arrays) {
    var i, j, k, ret, retLength, row, t, vectorName, vectorValues, vs, _k, _len;
    vectorName = [];
    vectorValues = [];
    retLength = 1;
    for (k in arrays) {
      vs = arrays[k];
      if (!vs.splice) {
        return [];
      }
      vectorName.push(k);
      vectorValues.push(vs);
      retLength *= vs.length;
    }
    if (!vectorValues.length) {
      return [];
    }
    ret = [];
    i = 0;
    while (i < retLength) {
      row = {};
      k = i;
      for (j = _k = 0, _len = vectorValues.length; _k < _len; j = ++_k) {
        vs = vectorValues[j];
        t = k % vs.length;
        row[vectorName[j]] = vs[t];
        k = Math.floor(k / vs.length);
      }
      ret[i] = row;
      i++;
    }
    return ret;
  };

  next = function(fn) {
    return setTimeout(fn, 100);
  };

  make_box = function(box) {
    var faces;
    faces = ['front', 'back', 'right', 'left', 'top', 'bottom'];
    return box.selectAll('div.box-side').data(faces).enter().append('div').attr('class', function(d) {
      return 'box-side ' + d;
    });
  };

  make_cards = function(box) {
    var animEnd, card, cardEnter;
    card = box.selectAll('div.card').data(function(d) {
      if (d) {
        return cross({
          card: drawerState[d].cards,
          pos: [drawerPos[d]]
        });
      } else {
        return [];
      }
    });
    animEnd = function() {
      var el;
      el = d3.select(this);
      next(function() {
        return el.attr('class', 'card');
      });
    };
    cardEnter = card.enter().append('div').attr('class', 'card new').on("webkitAnimationEnd", animEnd);
    cardEnter.append('div').attr('class', 'card-side back');
    cardEnter.append('div').attr('class', 'card-side front').style('background-position', function(d) {
      return "-" + (d.pos.ix * drawerWidth) + "px -" + (d.pos.iy * drawerHeight) + "px";
    });
    card.exit().remove();
    card.select('.back').text(function(d) {
      return d.card;
    });
    return card;
  };

  drawersCont = d3.select('.drawers-cont');

  drawerChest = drawersCont.append('div').attr('class', 'drawer-chest');

  drawerChest.selectAll('div.sep.vertical').data(d3.range(number + 1)).enter().append('div').attr('class', 'sep vertical').style('left', function(ix) {
    return ix * (drawerWidth + gap) + gap / 2 + 'px';
  });

  drawerChest.selectAll('div.sep.horizontal').data(cross({
    x: d3.range(number),
    y: d3.range(number + 1)
  })).enter().append('div').attr('class', 'sep horizontal').style('left', function(d) {
    return d.x * (drawerWidth + gap) + gap + 'px';
  }).style('top', function(d) {
    return d.y * (drawerHeight + gap) + gap / 2 + 'px';
  });

  drawerChest.selectAll('div.fronts.vertical').data(d3.range(number + 1)).enter().append('div').attr('class', 'fronts vertical').style('left', function(ix) {
    return ix * (drawerWidth + gap) + 'px';
  });

  drawerChest.selectAll('div.fronts.horizontal').data(cross({
    x: d3.range(number),
    y: d3.range(number + 1)
  })).enter().append('div').attr('class', 'fronts horizontal').style('left', function(d) {
    return d.x * (drawerWidth + gap) + gap + 'px';
  }).style('top', function(d) {
    return d.y * (drawerHeight + gap) + 'px';
  });

  drawerClassFn = function(d) {
    return ['drawer', drawerState[d].open ? 'open' : 'closed', drawerState[d].cards.length ? 'carded' : 'cardless'].join(' ');
  };

  myDrawer = null;

  drawerClick = function(d) {
    if (drawerState[d].open) {
      return;
    }
    drawerClaim(d, function(res) {
      console.log('claim result:', res);
      if (res !== 'OK') {
        return;
      }
      if (myDrawer) {
        drawerState[myDrawer].open = false;
        notifyChange(myDrawer);
      }
      if (myDrawer === d) {
        myDrawer = null;
      } else {
        myDrawer = d;
        drawerState[d].open = true;
        if (drawerState[d].cards.length === 0) {
          drawerState[d].cards.push('');
        }
        makeWriter(d);
        notifyChange(d);
      }
      updateDrawers();
    });
  };

  drawerChest.selectAll('div.drawer').data(drawers).enter().append('div').attr('class', drawerClassFn).style('left', function(d) {
    return drawerPos[d].x + 'px';
  }).style('top', function(d) {
    return drawerPos[d].y + 'px';
  }).on('click', drawerClick).call(make_box);

  updateDrawers = function() {
    drawerChest.selectAll('div.drawer').attr('class', drawerClassFn).call(make_cards);
  };

  updateDrawers();

  makeWriter = closeWriter = null;

  (function() {
    var editCont, editor, writer, writerDrawer;
    writerDrawer = null;
    makeWriter = function(drawer, delay) {
      if (delay == null) {
        delay = 2000;
      }
      setTimeout((function() {
        return makeCard('', function() {
          editCont.style('display', null);
          writerDrawer = drawer;
          editor.property('value', drawerState[writerDrawer].cards[0]);
          writer.style('left', function(d) {
            return drawerPos[writerDrawer].x + 'px';
          }).style('top', function(d) {
            return (drawerPos[writerDrawer].y - drawerHeight) + 'px';
          }).style('width', drawerWidth + 'px').style('height', drawerHeight + 'px').style('border-radius', '0px').transition().duration(1000).delay(500).style('left', ($totalOuterWidth - writerWidth) / 2 + 'px').style('top', ($totalOuterHeight - writerHeight) / 2 + 'px').style('width', writerWidth + 'px').style('height', writerHeight + 'px').style('border-radius', '3px');
        });
      }), delay);
    };
    closeWriter = function() {
      console.log('closeWriter', writerDrawer);
      if (!writerDrawer) {
        return;
      }
      drawerState[writerDrawer].cards[0] = editor.property('value');
      notifyChange(writerDrawer);
      updateDrawers(writerDrawer);
      editCont.style('display', 'none');
      writerDrawer = null;
    };
    d3.select(document).on('click.writer', closeWriter);
    editCont = d3.select('.edit-cont').style('display', 'none');
    writer = editCont.append('div').attr('class', 'writer').on('click', function() {
      return d3.event.stopPropagation();
    });
    editor = writer.append('textarea');
    writer.append('button').text('Close').on('click', closeWriter);
  })();

  hideLoading = function() {
    return d3.select('.loading-cont').style('opacity', 1).transition().duration(1000).style('opacity', 0).remove();
  };

  drawerClaim = function(d, cb) {
    return setTimeout(cb, 1, 'OK');
  };

  makeCard = function(text, cb) {
    return setTimeout(cb, 1, 'OK');
  };

  notifyChange = function() {};

  (function() {
    var d, msgs, socket, _k, _len;
    if (window.io) {
      console.log('IO detected');
      socket = io.connect();
      socket.on('connect', function() {
        socket.emit('register', 'DC');
      });
      socket.on('drawerInfo', function(dr) {
        var ix, iy, _k, _l, _ref, _ref1;
        console.log('DRAWER INFO:', dr);
        for (ix = _k = 0; 0 <= number ? _k < number : _k > number; ix = 0 <= number ? ++_k : --_k) {
          for (iy = _l = 0; 0 <= number ? _l < number : _l > number; iy = 0 <= number ? ++_l : --_l) {
            id = "" + ix + "_" + iy;
            drawerState[id] = {
              cards: ((_ref = dr[id]) != null ? _ref.cards : void 0) || [],
              open: ((_ref1 = dr[id]) != null ? _ref1.claimed : void 0) || false
            };
          }
        }
        updateDrawers();
        hideLoading();
      });
      socket.on('putCard', function(drawer, card) {
        if (!drawer.match(/^\d+_\d+$/)) {
          return;
        }
        console.log('GOT putCard', drawer, card);
        drawerState[drawer].cards.unshift(card);
        updateDrawers();
      });
      socket.on('drawerClaim', function(drawer) {
        if (!drawer.match(/^\d+_\d+$/)) {
          return;
        }
        drawerState[drawer].open = true;
      });
      socket.on('drawerUnclaim', function(drawer) {
        if (!drawer.match(/^\d+_\d+$/)) {
          return;
        }
        drawerState[drawer].open = false;
      });
      socket.on('reset', function() {
        console.log('GOT reset');
        resetDrawerState();
        updateDrawers();
      });
      (function() {
        var callback;
        callback = null;
        socket.on('drawerClaimResult', function(res) {
          if (typeof callback === "function") {
            callback(res);
          }
          callback = null;
        });
        return drawerClaim = function(d, cb) {
          callback = cb;
          socket.emit('drawerClaim', d);
        };
      })();
      (function() {
        var callback;
        callback = null;
        socket.on('makeCardResult', function(res) {
          if (typeof callback === "function") {
            callback(res);
          }
          callback = null;
        });
        return makeCard = function(text, cb) {
          callback = cb;
          socket.emit('makeCard', text);
        };
      })();
      return notifyChange = function(d) {
        socket.emit('drawerChange', d, drawerState[d]);
      };
    } else {
      console.log('IO not detected :-(');
      msgs = "Dear DC, It's all theatre, and some of it's bad, but I still love it. - Shira-----Dear D.C, I've been pretty serious with New York, but if one of your fine law firms gives me a job, I'm pretty sure I'd break up with her for you. Love, a frustrated 3L.Tho I will always love you, i don't have to like you right now.-----I have yet to experience another city who supports the arts with the same generosity. DC is my haven for the arts.-----Dear DC, you're the most kickass and most vibrant big town I've ever met. You have your own music, your own art culture, you have waterfronts and parks and rivers. There's more to you than just stately buildings filled with pretentious people, and I'm lucky to have grown up here and experienced the real dc. Best of all, you never make me feel like I'm alone, or just another number in a swarm of people on the street: you're a city that actually feels like a home. ALL my love, Lida-----Dear DC, thank you for letting me see your big blue sky on my way to work and during lunch. And giving me access to free education in the Smithsonian institutes. I hope to bring my children to see your beautiful museums and exhibits. One day, I will leave you to return to my home city. But I will always remember you and your sky.-----Dear DC, We should have gotten to know each other when we had the chance. My friend thinks you're really great. Love Gabi-----Dear DC, I've loved you from afar all these years. I'm looking forward to getting to know you better. Love, Becca-----The monuments inspire me to think of the founding principles that make our country great. They give me hope that we can remember who we are as a nation.-----Dear DC, I love standing next to Lincoln and looking up at a giant for democracy and freedom-----Hey DC, thanks for the clean ride… I like your metro-----Dear DC, I love you for fostering a surprising intelligent community of artists!-----To the District of Columbia - thank you for your hidden gardens in Georgetown-----In 2002, I walked for the Homeless in DC, it's the one place I felt I made a difference.";
      msgs = msgs.split('-----');
      for (_k = 0, _len = drawers.length; _k < _len; _k++) {
        d = drawers[_k];
        drawerState[d] = {
          cards: Math.random() > 0.85 ? [msgs[Math.floor(Math.random() * msgs.length)]] : [],
          open: false
        };
      }
      return hideLoading();
    }
  })();

}).call(this);
