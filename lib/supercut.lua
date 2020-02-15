tabutil = require "tabutil"

-- temporary override
local SC = softcut

function SC.defaults()
   zeros = {}
   for i=1, SC.VOICE_COUNT do zeros[i] = 0 end
   
   local state = {}
   for i=1,SC.VOICE_COUNT do
     state[i] = {}
     
     state[i].enable = 0
     state[i].play = 0
     state[i].record = 0
     
     state[i].buffer = (i%2 + 1)
     state[i].level = 0
     state[i].pan = 0
     
     state[i].level_input_cut = {0,0}
     state[i].level_cut_cut = zeros
     
     state[i].rate = 1
     state[i].loop_start = (i-1)*2
     state[i].loop_end = (i-1)*2+1
     state[i].loop = 1
     
     state[i].fade_time =  0.0005
     state[i].rec_level = 0
     state[i].pre_level = 0
     state[i].rec = 0
     state[i].rec_offset = -0.00015
     state[i].position = 0
     
     state[i].pre_filter_fc = 16000
     state[i].pre_filter_dry = 0
     state[i].pre_filter_lp = 1
     state[i].pre_filter_hp = 0
     state[i].pre_filter_bp = 0
     state[i].pre_filter_br = 0
     state[i].pre_filter_fc_mod = 1

     state[i].post_filter_fc = 12000
     state[i].post_filter_dry = 0
     state[i].post_filter_lp = 0
     state[i].post_filter_hp = 0
     state[i].post_filter_bp = 0
     state[i].post_filter_br = 0
     
     state[i].level_slew_time = 0.001
     state[i].rate_slew_time = 0.001
     state[i].phase_quant = 1
     state[i].phase_offset = 0
  end
  return state
end

supercut = {}

local supercut_data = softcut.defaults()

-- create default functions
for k,v in pairs(supercut_data[1]) do
  local f = function(key)
    local key = key
    
    return function(voice, arg1, arg2)
      if arg1 ~= nil then
        if arg2 == nil then
          supercut_data[voice][key] = arg1
        else
          supercut_data[voice][key][arg1] = arg2
        end
        
        for i,v in ipairs(supercut_data[voice].subvoices) do
          softcut[key](v, arg1, arg2)
        end
      else
        return supercut_data[voice][key]
      end
    end
  end
  
  supercut[k] = f(k)
end

-- divide buffers into default regions per voice
local home = {}
local cant_math = {}
local cant_math2 = {}
local div = softcut.VOICE_COUNT / 2

local j = 0
local i = 1
while i <= softcut.VOICE_COUNT do
  cant_math[i] = j
  cant_math[i + 1] = j
  
  cant_math2[i] = 1
  cant_math2[i + 1] = 2
  
  i = i + 2
  j = j + 1
end

for i = 1, softcut.VOICE_COUNT do
  home[i] = {
    region_start = cant_math[i] * softcut.BUFFER_SIZE / div,
    region_end = (cant_math[i] + 1) * softcut.BUFFER_SIZE / div,
    buffer = cant_math2[i]
  }
end

-- additional data to store
for i,v in ipairs(supercut_data) do
  v.level_input_cut = { { 0 }, { 0 } }
  
  v.io = "mono"
  v.subvoices = { i }
  v.home_region_start = home[i].region_start
  v.home_region_end = home[i].region_end
  v.home_region_length = home[i].region_end - home[i].region_start
  v.home_buffer = { home[i].buffer }
  v.region_start = v.home_region_start
  v.region_end = v.home_region_end
  v.region_length = v.region_end - v.region_start
  v.loop_length = v.region_length
  v.rate2 = 1
  v.rate3 = 1
  v.rate4 = 1
  v.home_region_position = 0
  v.region_position = 0
  v.loop_position = 0
  v.buffer = { home[i].buffer }
end

-- set defaults to match regions
for i = 1, softcut.VOICE_COUNT do
  supercut.buffer(i, home[i].buffer)
  supercut.loop_start(i, home[i].region_start)
  supercut.loop_end(i, home[i].region_end)
end

local subvoice_voice_lookup = {}

-- delagate subvoices
local delegate = function()
  local i = 1
  local voice = 1
  
  while i <= softcut.VOICE_COUNT do
    if supercut_data[voice].io == "mono" then
      supercut_data[voice].subvoices = { i }
      
      for j,v in ipairs(supercut_data[i].level_input_cut) do
        supercut_data[voice].level_input_cut[j] = { 0 }
      end
      for j,v in ipairs(supercut_data[i].level_cut_cut) do
        supercut_data[voice].level_cut_cut[j] = { 0 }
      end
      
      subvoice_voice_lookup[i] = voice
      
      i = i + 1
    else
      supercut_data[voice].subvoices = { i, i + 1 }
      
      for j,v in ipairs(supercut_data[i].level_cut_cut) do
        supercut_data[voice].level_cut_cut[j] = { 0, 0 }
      end
      for j,v in ipairs(supercut_data[i].level_cut_cut) do
        supercut_data[voice].level_cut_cut[j] = { 0, 0 }
      end
      
      subvoice_voice_lookup[i] = voice
      subvoice_voice_lookup[i + 1] = voice
      
      i = i + 2
    end
    
    voice = voice + 1
  end
  
  for i = voice, softcut.VOICE_COUNT do 
    supercut_data[i].io = "mono"
    supercut_data[i].subvoices = {}
  end
  
  -- print("-delegate-")
  
  for i,v in ipairs(supercut_data) do
    v.buffer = {}
    
    -- print("voice: ", i)
    
    for j,w in ipairs(v.subvoices) do
      -- print("subvoice: ", w)
      
      table.insert(v.buffer, home[w].buffer)
    end
    
    -- print("-")
  end
end

-- manually defined voice functions

supercut.io = function(voice, val) 
  if val == nil then return supercut_data[voice].io end
  
  supercut_data[voice].io = val
  delegate()
end

supercut.init = function(vce, iio)
  supercut.io(vce, iio)
  supercut.enable(vce, 1)
end

supercut.rate = function(voice, val) 
  if val == nil then return supercut_data[voice].rate end
  
  supercut_data[voice].rate = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice))
  end
end
supercut.rate2 = function(voice, val) 
  if val == nil then return supercut_data[voice].rate2 end
  
  supercut_data[voice].rate2 = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice))
  end
end
supercut.rate3 = function(voice, val) 
  if val == nil then return supercut_data[voice].rate3 end
  
  supercut_data[voice].rate3 = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice))
  end
end
supercut.rate4 = function(voice, val) 
  if val == nil then return supercut_data[voice].rate4 end
  
  supercut_data[voice].rate4 = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice))
  end
end
  
supercut.pan = function(voice, val)
  if val == nil then return supercut_data[voice].pan end
  
  supercut_data[voice].pan = val
  
  if supercut_data[voice].io == "mono" then
    if supercut_data[i].subvoices[1] ~= nil then 
      softcut.pan(supercut_data[i].subvoices[1], val)
    end
  else
    softcut.pan(supercut_data[voice].subvoices[1], -1)
    softcut.pan(supercut_data[voice].subvoices[2], 1)
    
    softcut.level(supercut_data[voice].subvoices[1], supercut_data[voice].level * ((val > 0) and 1 - val or 1))
    softcut.level(supercut_data[voice].subvoices[2], supercut_data[voice].level * ((val < 0) and 1 - math.abs(val) or 1))
  end
end

supercut.level = function(voice, val)
  if val == nil then return supercut_data[voice].level end
  
  supercut_data[voice].level = val
  
  if supercut_data[voice].io == "mono" then
    if supercut_data[i].subvoices[1] ~= nil then 
      softcut.level(supercut_data[i].subvoices[1], val)
    end
  else
    local p = supercut_data[voice].pan
    
    softcut.level(supercut_data[voice].subvoices[1], supercut_data[voice].level * ((p > 0) and 1 - p or 1))
    softcut.level(supercut_data[voice].subvoices[2], supercut_data[voice].level * ((p < 0) and 1 - math.abs(p) or 1))
  end
end

local update_loop_points = function(voice)
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.loop_start(v, util.clamp(supercut_data[voice].region_start, supercut_data[voice].region_end, supercut_data[voice].region_start + supercut_data[voice].loop_start))
    softcut.loop_end(v, util.clamp(supercut_data[voice].region_start, supercut_data[voice].region_end, supercut_data[voice].region_start + supercut_data[voice].loop_end))
  end
end

supercut.home_region_start = function(voice, val)
  if val == nil then return supercut_data[voice].home_region_start end
  
  supercut_data[voice].home_region_start = val 
end
supercut.home_region_end = function(voice, val)
  if val == nil then return supercut_data[voice].home_region_end end
  
  supercut_data[voice].home_region_end = val 
  supercut_data[voice].home_region_length = supercut_data[voice].home_region_end - supercut_data[voice].home_region_start
end
supercut.home_region_length = function(voice, val)
  if val == nil then return supercut_data[voice].home_region_length end
  
  supercut_data[voice].home_region_length = v
  supercut_data[voice].home_region_end = supercut_data[voice].home_region_start + val 
end
supercut.home_buffer = function(voice, val)
  if val == nil then return supercut_data[voice].home_buffer end
  
  supercut_data[voice].home_buffer = val 
end
supercut.region_start = function(voice, val)
  if val == nil then return supercut_data[voice].region_start end
  
  supercut_data[voice].region_start = val
  update_loop_points(voice)
end
supercut.region_end = function(voice, val)
  if val == nil then return supercut_data[voice].region_end end
  
  supercut_data[voice].region_end = val
  supercut_data[voice].region_length = supercut_data[voice].region_end - supercut_data[voice].region_start
  update_loop_points(voice)
end
supercut.region_length = function(voice, val)
  if val == nil then return supercut_data[voice].region_length end
  
  supercut_data[voice].region_length = val
  supercut_data[voice].region_end = supercut_data[voice].region_start + val
  update_loop_points(voice)
end
supercut.loop_start = function(voice, val)
  if val == nil then return supercut_data[voice].loop_start end
  
  supercut_data[voice].loop_start = val 
  update_loop_points(voice)
end
supercut.loop_end = function(voice, val)
  if val == nil then return supercut_data[voice].loop_end end
  
  supercut_data[voice].loop_end = val
  supercut_data[voice].loop_length = supercut_data[voice].loop_end - supercut_data[voice].loop_start
  update_loop_points(voice)
end
supercut.loop_length = function(voice, val)
  if val == nil then return supercut_data[voice].loop_length end
  
  supercut_data[voice].loop_length = val
  supercut_data[voice].loop_end = supercut_data[voice].loop_start + val
  
  update_loop_points(voice)
end

supercut.steal_voice_home_region = function(voice, dst)
  supercut.region_start(voice, supercut_data[dst].home_region_start)
  supercut.region_end(voice, supercut_data[dst].home_region_end)
  
  update_loop_points(voice)
end

supercut.steal_voice_region = function(voice, val)
  supercut.region_start(voice, supercut_data[voice].region_start)
  supercut.region_end(voice, supercut_data[voice].region_end)
  
  update_loop_points(voice)
end

supercut.home_region_position = function(voice, val)
  if val == nil then return supercut_data[voice].home_region_position end
  
  supercut_data[voice].home_region_position = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.position(v, supercut_data[voice].home_region_start + util.clamp(0, supercut_data[voice].home_region_length, val))
  end
end
supercut.region_position = function(voice, val)
  if val == nil then return supercut_data[voice].region_position end
  
  supercut_data[voice].region_position = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.position(v, supercut_data[voice].region_start + util.clamp(0, supercut_data[voice].region_length, val))
  end
end
supercut.loop_position = function(voice, val)
  if val == nil then return supercut_data[voice].loop_position end
  
  supercut_data[voice].loop_position = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.position(v, supercut_data[voice].loop_start + util.clamp(0, supercut_data[voice].loop_length, val))
  end
end
supercut.position = function(voice, val)
  if val == nil then return supercut_data[voice].position end
  
  supercut_data[voice].position = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.position(v, val)
  end
end

supercut.level_input_cut = function(ch, voice, amp, subvoice)
  if subvoice == nil and amp == nil then return supercut_data[voice].level_input_cut[ch] end
  if amp == nil then return supercut_data[voice].level_input_cut[ch][subvoice] end
  
  if subvoice == nil then
    for i,v in ipairs(supercut_data[voice].subvoices) do
      supercut_data[voice].level_input_cut[ch][i] = amp
      softcut.level_input_cut(ch, v, amp)
    end
  else
    supercut_data[voice].level_input_cut[ch][subvoice] = amp
    softcut.level_input_cut(ch, supercut_data[voice].subvoices[subvoice], amp)
  end
end

supercut.level_cut_cut = function(voice, dst, amp, subvoice, dst_subvoice)
  if subvoice == nil and amp == nil then return supercut_data[voice].level_cut_cut[dst] end
  if amp == nil then return supercut_data[voice].level_input_cut[dst][subvoice] end
  if dst_subvoice == nil then subvoice2 = subvoice end
  
  local p = supercut_data[voice].pan
  local pl = supercut_data[voice].level * ((p > 0) and 1 - p or 1)
  local pr = supercut_data[voice].level * ((p < 0) and 1 - math.abs(p) or 1)
  
  if subvoice == nil then
    if #supercut_data[voice].subvoices == 1 and #supercut_data[dst].subvoices == 1 then
      supercut_data[voice].level_cut_cut[dst][1] = amp
      softcut.level_cut_cut(supercut_data[voice].subvoices[1], supercut_data[dst].subvoices[1], amp)
    elseif #supercut_data[voice].subvoices == 1 and #supercut_data[dst].subvoices == 2 then
      supercut_data[voice].level_cut_cut[dst][1] = amp * pl
      supercut_data[voice].level_cut_cut[dst][2] = amp * pr
      
      softcut.level_cut_cut(supercut_data[voice].subvoices[1], supercut_data[dst].subvoices[1], amp * pl)
      softcut.level_cut_cut(supercut_data[voice].subvoices[1], supercut_data[dst].subvoices[2], amp * pr)
    elseif #supercut_data[voice].subvoices == 2 and #supercut_data[dst].subvoices == 1 then
      supercut_data[voice].level_cut_cut[dst][1] = amp
      
      softcut.level_cut_cut(supercut_data[voice].subvoices[1], supercut_data[dst].subvoices[1], amp)
      softcut.level_cut_cut(supercut_data[voice].subvoices[2], supercut_data[dst].subvoices[1], amp)
    elseif #supercut_data[voice].subvoices == 2 and #supercut_data[dst].subvoices == 2 then
      supercut_data[voice].level_cut_cut[dst][1] = amp * pl
      supercut_data[voice].level_cut_cut[dst][2] = amp * pr
      
      softcut.level_cut_cut(supercut_data[voice].subvoices[1], supercut_data[dst].subvoices[1], amp * pl)
      softcut.level_cut_cut(supercut_data[voice].subvoices[2], supercut_data[dst].subvoices[2], amp * pr)
    end 
  else
    supercut_data[voice].level_input_cut[dst][subvoice] = amp
    softcut.level_cut_cut(supercut_data[voice].subvoices[subvoice], supercut_data[dst].subvoices[dst_subvoice], amp)
  end
end

supercut.buffer = function(...) print("supercut doesn't steal this function!") end

supercut.buffer_clear_region = function(voice, ...)
  if arg == nil then
    for i,v in ipairs(supercut_data[voice].subvoices) do
      softcut.buffer_clear_region_channel(supercut_data[voice].buffer[i], supercut_data[voice].region_start, supercut_data[voice].region_end)
    end
  else
    softcut.buffer_clear_region(voice, unpack(arg))
  end
end

supercut.buffer_clear_region_channel = function(...)
  if #arg == 1 then
    local voice = arg[1]
    for i,v in ipairs(supercut_data[voice].subvoices) do
      softcut.buffer_clear_region_channel(supercut_data[voice].buffer[i], supercut_data[voice].region_start, supercut_data[voice].region_end)
    end
  else
    softcut.buffer_clear_region_channel(unpack(arg))
  end
end

supercut.buffer_read = function(file, voice, start_src, ch_src)
  local voice = arg[2]
  local file = arg[1]
  local start_src = 0
  local ch_src = 1
  if arg[3] ~= nil then start_src = arg[3] end
  if arg[4] ~= nil then ch_src = arg[4] end
  
  if supercut_data[voice].io == "mono" then
    softcut.buffer_read_mono(file, start_src, supercut_data[voice].region_start, supercut_data[voice].region_length, ch_src, supercut_data[voice].buffer[1])
  else
    buffer_read_stereo(file, start_src, supercut_data[voice].region_start, supercut_data[voice].region_length)
  end
end

supercut.buffer_write = function(file, voice)
  if supercut_data[voice].io == "mono" then
    buffer_write_mono(file, supercut_data[voice].region_start, supercut_data[voice].region_length, supercut_data[voice].buffer[1])
  else
    buffer_write_stereo(file, supercut_data[voice].region_start, supercut_data[voice].region_length)
  end
end

supercut.add_data = function(name, default, callback)
  if callback == nil then callback = function(...) end end
  
  for i,v in ipairs(supercut_data) do
    if type(default) == "function" then
      v[name] = default()
    else
      v[name] = default
    end
  end
  
  local closure = function(name)
    return function(voice, arg1, ar2)
      if arg1 ~= nil then
        if arg2 == nil then
          supercut_data[voice][name] = arg1
        else
          supercut_data[voice][name][arg1] = arg2
        end
        
        callback(voice, arg1, arg2)
      else
        return supercut_data[voice][name]
      end
    end
  end
  
  supercut[name] = closure(name)
end

-- phase stuff - auto-update positions

local supercut_event_phase = function(voice, val) end

local softcut_event_phase = function(subvoice, val) --------------------- !
  supercut_data[subvoice_voice_lookup[subvoice]].home_region_position = val - supercut_data[subvoice_voice_lookup[subvoice]].home_region_start
  supercut_data[subvoice_voice_lookup[subvoice]].region_position = val - supercut_data[subvoice_voice_lookup[subvoice]].region_start
  supercut_data[subvoice_voice_lookup[subvoice]].loop_position = val - supercut_data[subvoice_voice_lookup[subvoice]].loop_start
  supercut_data[subvoice_voice_lookup[subvoice]].position = val
  
  supercut_event_phase(voice, val)
end

supercut.event_phase = function(f) supercut_event_phase = f end
softcut.event_phase(softcut_event_phase)

softcut.poll_start_phase()

supercut.status = function(voice)
  if voice == nil then
    for i,v in ipairs(supercut_data) do
      if #v.subvoices > 0 then
        print("voice " .. i .. " {")
        
        for k,w in pairs(v) do
          if type(w) == "table" then
            print("  " .. k .. " = { ")
            for l,x in ipairs(w) do
              print(x)
            end
            print("}")
          else
            print("  " .. k .. " = " .. tostring(w))
          end
        end
        
        print("}")
      end
    end
  else
    print("voice " .. voice .. " {")
    
    for k,w in pairs(supercut_data[voice]) do
      if type(w) == "table" then
        local stuff = ""
        for l,x in ipairs(w) do
          if type(x) == "table" then
            local stuff2 = "{ "
            for m,y in ipairs(x) do
              stuff2 = stuff2 .. tostring(y) .. ", "
            end
            stuff = stuff .. stuff2 .. "}, "
          else
            stuff = stuff .. tostring(x) .. ", "
          end
        end
        print("  " .. k .. " = { " .. stuff .. "}")
      else
        print("  " .. k .. " = " .. tostring(w))
      end
    end
    
    print("}")
  end
end

setmetatable(supercut, { __index = softcut })

return supercut