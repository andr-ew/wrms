-- scriptname: minimal, extensible dual looper
-- v011820 @andrew
-- llllllll.co/t/22222

include 'wrms/lib/lib_wrms'

function init()
  wrms_init()
  
  -- softcut initial settings
  
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 2, 1.0)
  softcut.level_input_cut(1, 3, 1.0)
  softcut.level_input_cut(2, 4, 1.0)
  softcut.buffer(1,1)
  softcut.buffer(2,2)
  softcut.buffer(3,1)
  softcut.buffer(4,2)
  
  softcut.pan(1, -1)
  softcut.pan(2, 1)
  softcut.pan(3, -1)
  softcut.pan(4, 1)
  
  for i = 1,4 do
    softcut.enable(i, 1)
    softcut.loop(i, 1)
    softcut.fade_time(i, 0.1)
    softcut.rec_level(i, 1)
    softcut.position(i, 0)
  end
  
  softcut.play(1, 1)
  softcut.play(2, 1)
  
  softcut.loop_start(3, 0)
  softcut.loop_start(4, 0)
  
  softcut.pre_level(1, 0)
  softcut.pre_level(2, 0)
  
  redraw()
end

wrms_pages = { -- ordered pages of visual controls and actions (event callback functions)
  {
    label = "v",
    e2 = { -- wrm 1 volume
      worm = 1,
      label = "vol",
      value = 1.0,
      range = { 0.0, 2.0 },
      event = function(v) 
        softcut.level(1, v)
        softcut.level(2, v)
      end
    },
    e3 = { -- wrm 2 volume
      worm = 2,
      label = "vol",
      value = 1.0,
      range = { 0.0, 2.0 },
      event = function(v) 
        softcut.level(3, v)
        softcut.level(4, v)
      end
    },
    k2 = { -- wrm 2 record toggle
      worm = 1,
      label = "rec",
      value = 1,
      behavior = "toggle",
      event = function(v, t)
        if t < 2 then -- if short press toggle record
          softcut.rec(1, v)
          softcut.rec(2, v)
        else -- else long press clears loop region
          softcut.rec(1, 0)
          softcut.rec(2, 0)
          
          softcut.buffer_clear_region(wrms_loop[1].region_start, wrms_loop[1].region_end)
        end
      end
    },
    k3 = { -- wrm 2 record toggle + loop punch-in
      worm = 2,
      label = "rec",
      value = 0,
      behavior = "toggle",
      event = function(v, t)
        if t < 2 then -- if short press
          if wrms_loop[2].has_initial then -- if inital loop has been recorded, toggle recording (/ overdub)
            softcut.rec(3, v)
            softcut.rec(4, v)
          elseif wrms_loop[2].punch_in_time ~= nil then -- else if inital loop is being punched in, stop punch-in (stop recording, set loop points to punch-in time)
            softcut.rec(3, 0)
            softcut.rec(4, 0)
            
            local lt = util.clamp(util.time() - wrms_loop[2].punch_in_time, 0, 200) -- loop duration = now - when we punched-in
            wrms_loop[2].region_end = lt
            wrms_loop[2].loop_end = lt
            softcut.loop_end(3, lt)
            softcut.loop_end(4, lt)
            
            -- softcut.position(3, 0)
            -- softcut.position(4, 0)
            
            wrms_loop[2].has_initial = true
          else -- else start loop punch-in (start recording, set loop points to max)
            wrms_loop[2].region_end = 200
            wrms_loop[2].loop_end = 200
            softcut.loop_end(3, 200)
            softcut.loop_end(4, 200)
            
            softcut.rec(3, 1)
            softcut.rec(4, 1)
            softcut.play(3, 1)
            softcut.play(4, 1)
            
            wrms_loop[2].punch_in_time = util.time()
          end
        else -- else long press clears loop region, resets loop points
          softcut.rec(3, 0)
          softcut.rec(4, 0)
          softcut.play(3, 0)
          softcut.play(4, 0)
          
          wrms_loop[2].punch_in_time = nil
          wrms_loop[2].has_initial = false
        
          softcut.buffer_clear_region(wrms_loop[1].region_start, wrms_loop[1].region_end)
        end
      end
    }
  },
  {
    label = "o",
    e2 = { -- wrm 1 old volume (using level_cut_cut)
      worm = 1,
      label = "old",
      value = 0.5,
      range = { 0.0, 1.0 },
      event = function(v)
        if wrms_pages[6].k2 == 1 then -- if ping-pong is enabled (from '>' page)
        else
        end
      end
    },
    e3 = { -- wrm 2 old volume (using pre_level)
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
      label = "<<",
      value = 0,
      behavior = "momentary",
      event = function(v, t) end
    },
    k3 = {
      worm = 2,
      label = ">>",
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
      worm = "both",
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
