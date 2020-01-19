-- scriptname: minimal, extensible dual looper
-- v011820 @andrew
-- llllllll.co/t/22222

include 'wrms/lib/lib_wrms'

function init()
  wrms_init()
  
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 2, 1.0)
  softcut.level_input_cut(1, 3, 1.0)
  softcut.level_input_cut(2, 4, 1.0)
  softcut.enable(1,1)
  softcut.enable(2,1)
  softcut.enable(3,1)
  softcut.enable(4,1)
  softcut.buffer(1,1)
  softcut.buffer(2,2)
  softcut.buffer(3,1)
  softcut.buffer(4,2)
  
  softcut.pan(1, -1)
  softcut.pan(2, 1)
  softcut.pan(3, -1)
  softcut.pan(4, 1)
  
  for i = 1,4 do
    softcut.loop(i, 1)
    softcut.fade_time(i, 0.1)
    softcut.rec_level(i, 1)
    softcut.position(i, 0)
  end
  
  redraw()
end

wrms_pages = {
  {
    label = "v",
    e2 = {
      worm = 1,
      label = "vol",
      value = 1.0,
      range = { 0.0, 2.0 },
      event = function(v) end
    },
    e3 = {
      worm = 2,
      label = "vol",
      value = 1.0,
      range = { 0.0, 2.0 },
      event = function(v) end
    },
    k2 = {
      worm = 1,
      label = "rec",
      value = 1,
      behavior = "toggle",
      event = function(v, t) end
    },
    k3 = {
      worm = 2,
      label = "rec",
      value = 0,
      behavior = "toggle",
      event = function(v, t) end
    }
  },
  {
    label = "o",
    e2 = {
      worm = 1,
      label = "old",
      value = 0.5,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    e3 = {
      worm = 2,
      label = "old",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    k2 = {},
    k3 = {}
  },
  {
    label = "b",
    e2 = {
      worm = 1,
      label = "bnd",
      value = 1.0,
      range = { 0.0, 2.0 },
      event = function(v) end
    },
    e3 = {
      worm = "both",
      label = "wgl",
      value = 0.0,
      range = { 0.0, 10.0 },
      event = function(v) end
    },
    k2 = {
      worm = 2,
      label = "x0.5",
      value = 0,
      behavior = "momentary",
      event = function(v, t) end
    },
    k3 = {
      worm = 2,
      label = "x2",
      value = 0,
      behavior = "momentary",
      event = function(v, t) end
    }
  },
  {
    label = "s",
    e2 = {
      worm = 1,
      label = "s",
      value = 0.0,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    e3 = {
      worm = 1,
      label = "e",
      value = 0.3,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    k2 = {
      worm = 1,
      label = "p",
      value = 0,
      behavior = "toggle",
      event = function(v, t) end
    },
    k3 = {
      worm = 1,
      label = "p",
      value = 0,
      behavior = "toggle",
      event = function(v, t) end
    }
  },
  {
    label = "f",
    e2 = {
      worm = 1,
      label = "f",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    e3 = {
      worm = 1,
      label = "q",
      value = 0.3,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    k2 = {
      worm = 1,
      label = { "1", "2" },
      value = 1,
      behavior = "enum",
      event = function(v, t) end
    },
    k3 = {
      worm = 1,
      label = { "lp", "bp", "hp"  },
      value = 1,
      behavior = "enum",
      event = function(v, t) end
    }
  },
  {
    label = ">",
    e2 = {
      worm = 1,
      label = ">",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    e3 = {
      worm = 2,
      label = "<",
      value = 0.0,
      range = { 0.0, 1.0 },
      event = function(v) end
    },
    k2 = {
      worm = 1,
      label = "pp",
      value = 0,
      behavior = "toggle",
      event = function(v, t) end
    },
    k3 = {
      worm = 1,
      label = "share",
      value = 0,
      behavior = "toggle",
      event = function(v, t) end
    }
  }
}

wrms_pages[2].k2 = wrms_pages[1].k2
wrms_pages[2].k3 = wrms_pages[1].k3


---------------------------------------------------------------------------------------------------------------------------

function enc(n, delta)
  wrms_enc(n, delta)
  
  redraw()
end

function key(n,z)
  wrms_key(n,z)
  
  redraw()
end

function redraw()
  screen.clear()
  
  wrms_redraw()
  
  screen.update()
end
