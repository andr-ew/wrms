-- ~ wrms  ~~
--
-- dual asyncronous 
-- time-wigglers / echo loopers
--
-- version 1.0.0 @andrew
-- https://llllllll.co/t/wrms/28954
--
-- two wrms (stereo loops), 
-- similar in function but each 
-- with thier own quirks + 
-- abilities
-- 
-- E1 up top changes which page 
-- is displayed. pages contain 
-- controls, mapped to norns’ 
-- lower keys and encoders.
-- the location of the control 
-- dictates which wrm will be
-- affected.

wrms_lfo = include 'lib/hnds_wrms'
softloop = include 'lib/softloop'


function init()
  
  --wigl lfo setup via @justmat hnds lib
  wrms_lfo.init()
  wrms_lfo[1].freq = 0.5 -- keep the lfos out of phase
  wrms_lfo[2].freq = 0.4
  wrms_lfo.process = function() -- called on each lfo update
    for i = 1,2 do
      local rate = wrms_loop[1].rate + wrms_lfo[1].delta -- set wrm 1 rate = change in lfo1 each time it updates
      
      softcut.rate(i, rate * wrms_loop[1].bend)
      softcut.rate(i, rate * wrms_loop[1].bend)
      wrms_loop[1].rate = rate
    end
    
    for i = 3,4 do
      local rate = wrms_loop[2].rate + wrms_lfo[2].delta -- set wrm 2 rate = change in lfo2 each time it updates
      
      softcut.rate(i, rate * wrms_loop[2].bend)
      softcut.rate(i, rate * wrms_loop[2].bend)
      wrms_loop[2].rate = rate
    end
  end
  
  -- softcut initial settings
  softcut.buffer_clear()
  
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  
  for h, i in ipairs({ 0, 2 }) do
    softcut.play(h, 1)
    softcut.pre_level(h, 0.0)
    softcut.rate_slew_time(h, 0.2)
    softcut.rec_level(h + 2, 1.0)
    softcut.rate(h + 2, wrms_loop[2].rate * wrms_loop[2].bend)
    -- softcut.post_filter_dry(h, 0)
    
    for j = 1,2 do
      softcut.enable(i + j, 1)
      softcut.loop(i + j, 1)
      softcut.fade_time(i+j, 0.1)
      
      softcut.level_input_cut(j, i + j, 1.0)
      softcut.buffer(i + j,j)
      softcut.pan(i + j, j == 1 and -1 or 1)
      
      softcut.loop_start(i+j, wrms_loop[j].loop_start)
      softcut.loop_end(i+j, wrms_loop[j].loop_end)
      softcut.position(i+j, wrms_loop[j].loop_start)
      
      softcut.level_slew_time(i+j, 0.1)
      softcut.recpre_slew_time(i+j, 0.01)
    end
  end
  
  wrms_init()
  
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
        wrms_loop[1].vol = v
        
        wrms_pages[5].e2.event(wrms_pages[5].e2.value)
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
        wrms_loop[2].vol = v
        
        wrms_pages[5].e3.event(wrms_pages[5].e3.value)
      end
    },
    k2 = { -- wrm 2 record toggle
      worm = 1,
      label = "rec",
      value = 1,
      behavior = "toggle",
      event = function(v, t)
        if t < 0.5 then -- if short press toggle record
          softcut.rec(1, v)
          softcut.rec(2, v)
          wrms_loop[1].rec = v
        else -- else long press clears loop region
          softcut.rec(1, 0)
          softcut.rec(2, 0)
          wrms_loop[1].rec = 0
          
          wrms_pages[1].k2.value = 0
          
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
        wrms_loop[2].rec = v
        
        if t < 0.5 then -- if short press
          if wrms_loop[2].has_initial then -- if inital loop has been recorded
            softcut.rec(3, v) -- toggle recording
            softcut.rec(4, v)
            
          elseif wrms_loop[2].is_punch_in then -- else if inital loop is being punched in, punch out
            wrms_loop[2].region_end = wrms_loop[2].phase - 0.1 -- set loop & region end to loop time
            wrms_loop[2].loop_end = wrms_loop[2].region_end
            softcut.loop_end(3, wrms_loop[2].loop_end)
            softcut.loop_end(4, wrms_loop[2].loop_end)
            
            softcut.rec(3, 0) -- stop recording but keep playing
            softcut.rec(4, 0)
            
            wrms_loop[2].has_initial = true -- this is how we know we're done with the punch-in
            wrms_loop[2].is_punch_in = false
            
            wrms_loop[2].wake()
            
          elseif v == 1 then -- else start loop punch-in
            softcut.rec(3, 1) -- start recording
            softcut.rec(4, 1)
            softcut.play(3, 1)
            softcut.play(4, 1)
            
            wrms_loop[2].region_end = wrms_loop[2].default_region_end -- set loop & region end to default
            wrms_loop[2].loop_end = wrms_loop[2].region_end
            softcut.loop_start(3, wrms_loop[2].loop_start)
            softcut.loop_start(4, wrms_loop[2].loop_start)
            softcut.loop_end(3, wrms_loop[2].loop_end)
            softcut.loop_end(4, wrms_loop[2].loop_end)
            softcut.position(3, wrms_loop[2].loop_start)
            softcut.position(4, wrms_loop[2].loop_start)
            
            wrms_loop[2].is_punch_in = true -- this is how we started the punch in
          end
        else -- else (long press)
          softcut.rec(3, 0) -- stop recording
          softcut.rec(4, 0)
          softcut.play(3, 0)
          softcut.play(4, 0)
          wrms_pages[1].k3.value = 0
          wrms_loop[2].rec = 0
          
          wrms_loop[2].region_end = wrms_loop[2].default_region_end -- set loop & region end to default
          wrms_loop[2].loop_end = wrms_loop[2].region_end
          softcut.loop_start(3, wrms_loop[2].loop_start)
          softcut.loop_start(4, wrms_loop[2].loop_start)
          softcut.loop_end(3, wrms_loop[2].loop_end)
          softcut.loop_end(4, wrms_loop[2].loop_end)
          softcut.position(3, wrms_loop[2].loop_start)
          softcut.position(4, wrms_loop[2].loop_start)
          
          wrms_loop[2].punch_in_time = false
          wrms_loop[2].has_initial = false
        
          softcut.buffer_clear_region(wrms_loop[2].region_start, wrms_loop[2].region_end) -- clear loop region
          
          wrms_loop[2].sleep()
        end
      end
    }
  },
  {
    label = "o",
    e2 = { -- wrm 1 old volume (using rec_level)
      worm = 1,
      label = "old",
      value = 0.5,
      range = { 0.0, 1.0 },
      event = function(v)
        softcut.rec_level(1, v)
        softcut.rec_level(2, v)
      end
    },
    e3 = { -- wrm 2 old volume (using pre_level)
      worm = 2,
      label = "old",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(v) 
        softcut.pre_level(3,  v)
        softcut.pre_level(4,  v)
      end
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
      range = { 1, 2.0 },
      event = function(v) 
        wrms_loop[1].bend = 2^(v-1)
        softcut.rate(1, wrms_loop[1].rate * wrms_loop[1].bend)
        softcut.rate(2, wrms_loop[1].rate * wrms_loop[1].bend)
      end
    },
    e3 = {
      worm = "both",
      label = "wgl",
      value = 0.0,
      range = { 0.0, 100.0 },
      event = function(v) 
        local d = (util.linexp(0, 1, 0.01, 1, v) - 0.01) * 100
        wrms_lfo[1].depth = d
        wrms_lfo[2].depth = d
        wrms_loop[1].wgl = v
        wrms_loop[2].wgl = v + 0.5
      end
    },
    k2 = {
      worm = 2,
      label = "<<",
      value = 0,
      behavior = "momentary",
      event = function(v, t)
        local st = (1 + (math.random() * 0.5)) * t
        softcut.rate_slew_time(3, st)
        softcut.rate_slew_time(4, st)
        
        wrms_loop[2].rate = wrms_loop[2].rate / 2
        softcut.rate(3, wrms_loop[2].rate * wrms_loop[2].bend)
        softcut.rate(4, wrms_loop[2].rate * wrms_loop[2].bend)
      end
    },
    k3 = {
      worm = 2,
      label = ">>",
      value = 0,
      behavior = "momentary",
      event = function(v, t) 
        local st = (1 + (math.random() * 0.5)) * t
        softcut.rate_slew_time(3, st)
        softcut.rate_slew_time(4, st)
        
        wrms_loop[2].rate = wrms_loop[2].rate * 2
        softcut.rate(3, wrms_loop[2].rate * wrms_loop[2].bend)
        softcut.rate(4, wrms_loop[2].rate * wrms_loop[2].bend)
      end
    }
  },
  {
    label = "s", 
    e2 = { -- wrm 1 loop start point
      worm = 1,
      label = "s",
      value = 0.0,
      range = { 0.0, 1.0 },
      event = function(v) 
        wrms_pages[4].e2.range[2] = wrms_loop[1].region_end - wrms_loop[1].region_start -- set encoder range
        
        wrms_loop[1].loop_start = v + wrms_loop[1].region_start-- set start point
        softcut.loop_start(1, wrms_loop[1].loop_start)
        softcut.loop_start(2, wrms_loop[1].loop_start)
        
        wrms_pages[4].e3.event(wrms_pages[4].e3.value)
      end
    },
    e3 = { -- wrm 1 loop length
      worm = 1,
      label = "l",
      value = 0.3,
      range = { 0, 1.0 },
      event = function(v) 
        wrms_pages[4].e3.range[2] = wrms_loop[1].region_end - wrms_loop[1].region_start -- set encoder range
        
        wrms_loop[1].loop_end = v + wrms_loop[1].loop_start + 0.001 -- set loop end from length
        softcut.loop_end(1, wrms_loop[1].loop_end)
        softcut.loop_end(2, wrms_loop[1].loop_end)
      end
    },
    k2 = {
      worm = 1,
      label = "<<",
      value = 0,
      behavior = "momentary",
      event = function(v, t)
        
        local st = (1 + (math.random() * 0.5)) * t
        softcut.rate_slew_time(1, st)
        softcut.rate_slew_time(2, st)
        
        wrms_loop[1].rate = wrms_loop[1].rate / 2
        softcut.rate(1, wrms_loop[1].rate * wrms_loop[1].bend)
        softcut.rate(2, wrms_loop[1].rate * wrms_loop[1].bend)
      end
    },
    k3 = {
      worm = 1,
      label = ">>",
      value = 0,
      behavior = "momentary",
      event = function(v, t) 
        local st = (1 + (math.random() * 0.5)) * t
        softcut.rate_slew_time(1, st)
        softcut.rate_slew_time(2, st)
        
        wrms_loop[1].rate = wrms_loop[1].rate * 2
        softcut.rate(1, wrms_loop[1].rate * wrms_loop[1].bend)
        softcut.rate(2, wrms_loop[1].rate * wrms_loop[1].bend)
      end
    }
  },
  {
    label = ">",
    e2 = { -- feed wrm 1 to wrm 2
      worm = 1,
      label = ">",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(v)
        softcut.level_cut_cut(1, 3, v * wrms_pages[1].e2.value)
        softcut.level_cut_cut(2, 4, v * wrms_pages[1].e2.value)
        wrms_loop[1].feed = v
      end
    },
    e3 = { -- feed wrm 2 to wrm 1
      worm = 2,
      label = "<",
      value = 0.0,
      range = { 0.0, 1.0 },
      event = function(v) 
        softcut.level_cut_cut(3, 1, v * wrms_pages[1].e3.value)
        softcut.level_cut_cut(4, 2, v * wrms_pages[1].e3.value)
        wrms_loop[2].feed = v
      end
    },
    k2 = {
      worm = 1,
      label = "pp",
      value = 0,
      behavior = "toggle",
      event = function(v, t) 
        if v == 1 then -- if ping-pong is enabled, route across voices
          softcut.level_cut_cut(1, 2, 1)
          softcut.level_cut_cut(2, 1, 1)
          softcut.level_cut_cut(1, 1, 0)
          softcut.level_cut_cut(2, 2, 0)
        else -- else (ping-pong is not enabled) route voice to voice
          softcut.level_cut_cut(1, 2, 0)
          softcut.level_cut_cut(2, 1, 0)
          softcut.level_cut_cut(1, 1, 1)
          softcut.level_cut_cut(2, 2, 1)
        end
      end
    },
    k3 = { -- toggle share buffer region
      worm = "both",
      label = "share",
      value = 0,
      behavior = "toggle",
      event = function(v, t) 
        if v == 1 then -- if sharing
          wrms_loop[1].region_start = wrms_loop[2].region_start -- set wrm 1 region points to wrm 2 region points
          wrms_loop[1].region_end = wrms_loop[2].region_end
        else -- else (not sharing)
          wrms_loop[1].region_start = wrms_loop[1].default_region_start -- set wrm 1 region points to default
          wrms_loop[1].region_end = wrms_loop[1].default_region_end
        end
        
        wrms_pages[4].e2.event(wrms_pages[4].e2.value) -- update loop points
        wrms_pages[4].e3.event(wrms_pages[4].e3.value)
      end
    }
  }
}
-- ,
-- {
  --   label = "f",
  --   e2 = { -- wrm 1 filter cutoff
  --     worm = 1,
  --     label = "f",
  --     value = 1.0,
  --     range = { 0.0, 1.0 },
  --     event = function(v) 
  --       softcut.post_filter_fc(1, util.linexp(0, 1, 1, 12000, v))
  --       softcut.post_filter_fc(2, util.linexp(0, 1, 1, 12000, v))
  --     end
  --   },
  --   e3 = { -- wrm 1 filter resonance
  --     worm = 1,
  --     label = "q",
  --     value = 0.3,
  --     range = { 0.0, 1.0 },
  --     event = function(v) 
  --       softcut.post_filter_rq(1,1 - v)
  --       softcut.post_filter_rq(2,1 - v)
  --     end
  --   },
  --   k2 = { -- wrm 1 filter on/off
  --     worm = 1,
  --     label = "filt",
  --     value = 0,
  --     behavior = "toggle",
  --     event = function(v, t) 
  --       if v == 0 then
  --         softcut.post_filter_dry(1, 1)
  --         softcut.post_filter_dry(2, 1)
  --         softcut.post_filter_lp(1, 0)
  --         softcut.post_filter_lp(2, 0)
  --         softcut.post_filter_bp(1, 0)
  --         softcut.post_filter_bp(2, 0)
  --         softcut.post_filter_hp(1, 0)
  --         softcut.post_filter_hp(2, 0)
  --       else
  --         wrms_pages[5].k3.event(wrms_pages[5].k3.value)
  --       end
  --     end
  --   },
  --   k3 = { -- wrm 1 filter type
  --     worm = 1,
  --     label = { "lp", "bp", "hp"  },
  --     value = 1,
  --     behavior = "enum",
  --     event = function(v, t)
  --       if wrms_pages[5].k2.value == 1 then
  --         softcut.post_filter_dry(1, 0)
  --         softcut.post_filter_dry(2, 0)
  --         softcut.post_filter_lp(1, 0)
  --         softcut.post_filter_lp(2, 0)
  --         softcut.post_filter_bp(1, 0)
  --         softcut.post_filter_bp(2, 0)
  --         softcut.post_filter_hp(1, 0)
  --         softcut.post_filter_hp(2, 0)
          
  --         if v == 1 then -- v is lowpass
  --           softcut.post_filter_lp(1, 1)
  --           softcut.post_filter_lp(2, 1)
  --         elseif v == 2 then -- v is bandpass
  --           softcut.post_filter_bp(1, 1)
  --           softcut.post_filter_bp(2, 1)
  --         elseif v == 3 then -- v is hightpass
  --           softcut.post_filter_hp(1, 1)
  --           softcut.post_filter_hp(2, 1)
  --         end
  --       end
  --     end
  --   }
  -- },
wrms_pages[2].k2 = wrms_pages[1].k2
wrms_pages[2].k3 = wrms_pages[1].k3

---------------------------------------------------------------------------------------------------------------------------

wrms_sens = 0.01
wrms_phase_quant = 0.01

wrms_page_n = 1
local get_page_n = function() return math.floor(wrms_page_n) end

wrms_loop = {
  {
    is_punch_in = false,
    has_initial = true,
    phase = 0,
    default_region_start = 295,
    default_region_end = 300,
    region_start = 0,
    region_end = 0,
    loop_start = 0,
    loop_end = 0,
    rate = 1,
    bend = 1,
    vol = 1,
    wgl = 0,
    feed = 1,
    rec = 1
  },
  {
    is_punch_in = false,
    has_initial = false,
    phase = 0,
    default_region_start = 1,
    default_region_end = 60,
    region_start = 0,
    region_end = 0,
    loop_start = 0,
    loop_end = 0,
    rate = 1,
    bend = 1,
    vol = 1,
    wgl = 0,
    feed = 0,
    rec = 0
  }
}

for i,v in ipairs(wrms_loop) do
  v.region_start = v.default_region_start
  v.region_end = v.default_region_end
  v.loop_start = v.default_region_start
  v.loop_end = v.default_region_end
end

-- for putting wrms to sleep zZzz :)
for i,v in ipairs(wrms_loop) do
  v.segment_is_awake = {}
  v.sleep_index = 24
  
  local sleep_closure = function(i) return function() 
    wrms_loop[i].sleep_index = 1
  end end
  
  local wake_closure = function(i) return function() 
    wrms_loop[i].sleep_index = 24
  end end
  
  v.sleep = wake_closure(i)
  v.wake = v.sleep
  
  for j = 1, 24 do
    v.segment_is_awake[j] = false
  end
end

function wrm_phase_event(voice, p)
  if voice == 1 or voice == 3 then
    local l = voice == 1 and 1 or 2
    wrms_loop[l].phase = p
    
    redraw()
  end
end

softcut.phase_quant(1, wrms_phase_quant)
softcut.phase_quant(3, wrms_phase_quant)

softcut.event_phase(wrm_phase_event)
softcut.poll_start_phase()

function wrms_init()
  for i,v in ipairs(wrms_pages) do
    for j,w in ipairs({ v.e2, v.e3 }) do
      if w ~= nil then w.event(w.value) end
    end
    for j,w in ipairs({ v.k2, v.k3 }) do
      if w ~= nil then if w.behavior ~= "momentary" then w.event(w.value, 0) end end
    end
  end
end

function wrms_enc(n, delta)
  if n == 1 then wrms_page_n = util.clamp(wrms_page_n + (util.clamp(delta, -1, 1) * 0.25), 1, #wrms_pages)
  else
    local e = wrms_pages[get_page_n()]["e" .. n]
    
    if e ~= nil then
      local sens = e.sens == nil and wrms_sens or e.sens
      e.value = util.round(util.clamp(e.value + (delta * sens), e.range[1], e.range[2]), sens)
      e.event(e.value)
    end
  end
end

function wrms_key(n,z)
  if n == 1 then
    rec = z
  else
    local k = wrms_pages[get_page_n()]["k" .. n]
    
    if k ~= nil then
      if z == 1 then
        k.time = util.time()
        if k.behavior == "momentary" then k.value = 1 end
      else
        if k.behavior == "momentary" then k.value = 0
        elseif k.behavior == "toggle" then k.value = k.value == 0 and 1 or 0
        elseif k.behavior == "enum" then k.value = k.value == #k.label and 1 or k.value + 1 end
        
        k.event(k.value, util.time() - k.time)
        k.time = nil
      end
    end
  end
end

function wrms_redraw()
  
  -- pager
  for i,v in ipairs(wrms_pages) do
    screen.move(128 - 4, i * 7)
    screen.level(get_page_n() == i and 8 or 2)
    screen.text_center(v.label)
  end
  
  local function get_x_pos(c1, c2)
    local ret, wrm1, wrm2
    
    if c1 == nil then wrm1 = 1 else wrm1 = c1.worm end
    if c2 == nil then wrm2 = 2 else wrm2 = c2.worm end
    
    if wrm1 == 1 and wrm2 == 2 then ret = { 0, 2 }
    elseif wrm1 == 1 and wrm2 == 1 then ret = { 0, 1 }
    elseif wrm1 == 2 and wrm2 == 2 then ret = { 2, 3 }
    elseif wrm1 == "both" and wrm2 == 2 then ret = { 1.5, 3 }
    elseif wrm1 == 1 and wrm2 == "both" then ret = { 0, 1.5 }
    else ret = { 2, 0 } end
    
    return ret
  end
  
  -- enc
  local ex = get_x_pos(wrms_pages[get_page_n()].e2, wrms_pages[get_page_n()].e3)
  for i,v in ipairs({ wrms_pages[get_page_n()].e2, wrms_pages[get_page_n()].e3 }) do
    if v ~= nil then
      screen.move(2 + ex[i] * 29, 46)
      screen.level(4)
      screen.text(v.label)
      screen.move(2 + (ex[i] * 29) + ((string.len(v.label) + 0.5) * 5), 46)
      screen.level(10)
      screen.text(v.value)
    end
  end
  
  -- key
  local kx = get_x_pos(wrms_pages[get_page_n()].k2, wrms_pages[get_page_n()].k3)
  for i,v in ipairs({ wrms_pages[get_page_n()].k2, wrms_pages[get_page_n()].k3 }) do
    if v ~= nil then
      screen.move(2 + kx[i] * 29, 46 + 10)
      
      if v.behavior == "enum" then
        screen.level(8)
        screen.text(v.label[math.floor(v.value)])
      else
        screen.level(v.value * 10 + 2)
        screen.text(v.label)
      end
    end
  end
  
  --feed indicators
  screen.level(math.floor(wrms_loop[1].feed * 4))
  screen.pixel(42, 23)
  screen.pixel(43, 24)
  screen.pixel(42, 25)
  screen.fill()
  
  screen.level(math.floor(wrms_loop[2].feed * 4))
  screen.pixel(54, 23)
  screen.pixel(53, 24)
  screen.pixel(54, 25)
  screen.fill()
  
  for i,v in ipairs(wrms_loop) do
    local left = 2 + (i-1) * 58
    local top = 34
    local width = 44
    
    --phase
    screen.level(2)
    if v.is_punch_in == false then
      screen.pixel(left + width * (v.loop_start - v.region_start) / (v.region_end - v.region_start), top)
      screen.fill()
    end
    if v.has_initial then
      screen.pixel(left + width * (v.loop_end- v.region_start) / (v.region_end - v.region_start), top)
      screen.fill()
    end
    
    screen.level(6 + 10 * v.rec)
    if v.has_initial == false then
      if v.is_punch_in then
        screen.move(left + width * (v.loop_start - v.region_start) / (v.region_end - v.region_start), top + 1)
        screen.line(1 + left + width * (v.phase - v.region_start) / (v.region_end - v.region_start), top + 1)
        screen.stroke()
      end
    else
      screen.pixel(left + width * (v.phase - v.region_start) / (v.region_end - v.region_start), top)
      screen.fill()
    end
    
    --fun wrm animaions
    local top = 18
    local width = 24
    local lowamp = 0.5
    local highamp = 1.75
    
    if v.sleep_index > 0 and v.sleep_index <= 24 then
      v.segment_is_awake[math.floor(v.sleep_index)] = v.has_initial
      v.sleep_index = v.sleep_index + (0.25 * (v.has_initial and -1 or -4))
    end
    
    screen.level(math.floor(v.vol * 10))
    local width = util.linexp(0, (v.region_end - v.region_start), 0.01, width, (v.loop_end  + 4.125 - v.loop_start))
    for j = 1, width do
      local amp = v.segment_is_awake[j] and math.sin(((v.phase - v.loop_start) * (i == 1 and 1 or 2) / (v.loop_end - v.loop_start) + j / width) * (i == 1 and 2 or 4) * math.pi) * util.linlin(1, width / 2, lowamp, highamp + v.wgl, j < (width / 2) and j or width - j) - 0.75 * util.linlin(1, width / 2, lowamp, highamp + v.wgl, j < (width / 2) and j or width - j) - (util.linexp(0, 1, 0.5, 6, j/width) * (v.bend - 1)) or 0
      local left = left - (v.loop_start - v.region_start) / (v.region_end - v.region_start) * (width - 44)
      
      screen.pixel(left - 1 + j, top + amp)
    end
    screen.fill()
  end
end

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
