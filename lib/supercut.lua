tabutil = require "tabutil"
--[[

these are the guts for the supercut lib! it is documented over this a way -> https://llllllll.co/t/supercut-lib/29526

]]--

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

local function update_regions()
  for i,v in ipairs(supercut_data) do
    local sv = v.subvoices[1]
    
    if sv ~= nil then
      v.home_region_start = home[sv].region_start
      v.home_region_end = home[sv].region_end
      v.home_region_length = home[sv].region_end - home[sv].region_start
      
      v.region_start = v.home_region_start
      v.region_end = v.home_region_end
      v.region_length = v.region_end - v.region_start
      v.loop_length = v.region_length
      
      for j,w in ipairs(v.subvoices) do
        v.home_buffer[j] = home[w].buffer
        v.buffer[j] = home[w].buffer
      end
    end
  end
end

-- additional data to store
for i,v in ipairs(supercut_data) do
  v.level_input_cut = { { 0 }, { 0 } }
  
  v.io = "mono"
  v.subvoices = { i }
  v.home_region_start = 0
  v.home_region_end = 0
  v.home_region_length = 0
  v.home_buffer = {}
  v.region_start = 0
  v.region_end = 0
  v.region_length = 0
  v.loop_length = 0
  v.rate2 = 1
  v.rate3 = 1
  v.rate4 = 1
  v.home_region_position = 0
  v.region_position = 0
  v.loop_position = 0
  v.buffer = { }
end

update_regions()

-- set defaults to match regions
for i = 1, softcut.VOICE_COUNT do
  supercut.buffer(i, home[i].buffer)
  supercut.loop_start(i, home[i].region_start)
  supercut.loop_end(i, home[i].region_end)
end

local subvoice_voice_lookup = {}

-- delagate subvoices
local function delegate()
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
  
  for i,v in ipairs(supercut_data) do
    v.buffer = {}
    
    -- print("voice: ", i)
    
    for j,w in ipairs(v.subvoices) do
      -- print("subvoice: ", w)
      
      table.insert(v.buffer, home[w].buffer)
    end
  end
end

-- manually defined voice functions

supercut.io = function(voice, val) 
  if val == nil then return supercut_data[voice].io end
  
  supercut_data[voice].io = val
  delegate()
  update_regions()
end

supercut.init = function(vce, iio)
  supercut.io(vce, iio)
  supercut.enable(vce, 1)
  supercut.level_input_cut(1, vce, 1)
  supercut.level_input_cut(2, vce, 1)
  supercut.rate(vce, 1)
  supercut.loop(vce, 1)
  -- supercut.fade_time(i, 0.1)
  supercut.loop_position(vce, 0)
  supercut.level(vce, 1)
  supercut.pan(vce, 0)
  supercut.rec_level(vce, 1)
end

supercut.rate = function(voice, val) 
  if val == nil then return supercut_data[voice].rate end
  
  if val > 0 and val >= 64 then val = supercut_data[voice].rate
  elseif val < 0 and val <= -64 then val = supercut_data[voice].rate
  end
  
  supercut_data[voice].rate = val
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, util.clamp(-63, 63, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice)))
  end
end
supercut.rate2 = function(voice, val) 
  if val == nil then return supercut_data[voice].rate2 end
  
  if val > 0 and val >= 64 then val = supercut_data[voice].rate
  elseif val < 0 and val <= -64 then val = supercut_data[voice].rate
  end
  
  supercut_data[voice].rate2 = util.clamp(-16, 16, val)
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, util.clamp(-63, 63, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice)))
  end
end
supercut.rate3 = function(voice, val) 
  if val == nil then return supercut_data[voice].rate3 end
  
  if val > 0 and val >= 64 then val = supercut_data[voice].rate
  elseif val < 0 and val <= -64 then val = supercut_data[voice].rate
  end
  
  supercut_data[voice].rate3 = util.clamp(-16, 16, val)
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, util.clamp(-63, 63, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice)))
  end
end
supercut.rate4 = function(voice, val) 
  if val == nil then return supercut_data[voice].rate4 end
  
  if val > 0 and val >= 64 then val = supercut_data[voice].rate
  elseif val < 0 and val <= -64 then val = supercut_data[voice].rate
  end
  
  supercut_data[voice].rate4 = util.clamp(-16, 16, val)
  
  for i,v in ipairs(supercut_data[voice].subvoices) do
    softcut.rate(v, util.clamp(-63, 63, supercut.rate(voice) * supercut.rate2(voice) * supercut.rate3(voice) * supercut.rate4(voice)))
  end
end
  
supercut.pan = function(voice, val)
  if val == nil then return supercut_data[voice].pan end
  
  supercut_data[voice].pan = val
  
  if supercut_data[voice].io == "mono" then
    if supercut_data[voice].subvoices[1] ~= nil then 
      softcut.pan(supercut_data[voice].subvoices[1], val)
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
    if supercut_data[voice].subvoices[1] ~= nil then 
      softcut.level(supercut_data[voice].subvoices[1], val)
    end
  else
    local p = supercut_data[voice].pan
    
    softcut.level(supercut_data[voice].subvoices[1], supercut_data[voice].level * ((p > 0) and 1 - p or 1))
    softcut.level(supercut_data[voice].subvoices[2], supercut_data[voice].level * ((p < 0) and 1 - math.abs(p) or 1))
  end
end

local function update_loop_points(voice)
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
  
  supercut_data[voice].loop_start = (val > 0) and util.clamp(0, supercut_data[voice].region_length, val) or 0
  update_loop_points(voice)
end
supercut.loop_end = function(voice, val)
  if val == nil then return supercut_data[voice].loop_end end
  
  supercut_data[voice].loop_end = (val > 0) and util.clamp(0, supercut_data[voice].region_length, val) or 0
  supercut_data[voice].loop_length = supercut_data[voice].loop_end - supercut_data[voice].loop_start
  update_loop_points(voice)
end
supercut.loop_length = function(voice, val)
  if val == nil then return supercut_data[voice].loop_length end
  
  supercut_data[voice].loop_length = (val > 0) and util.clamp(0, supercut_data[voice].region_length, val) or 0
  supercut_data[voice].loop_end = supercut_data[voice].loop_start + val
  
  update_loop_points(voice)
end

supercut.buffer = function(voice, val) 
  if type(val) ~= "table" then val = { val } end
  
  for i,v in ipairs(supercut_data[voice].buffer) do
    if val[i] ~= nil then
      supercut_data[voice].buffer[i] = val[i]
      softcut.buffer(supercut_data[voice].subvoices[i], val[i])
    end
  end
end

supercut.steal_voice_home_region = function(voice, dst)
  supercut.region_start(voice, supercut_data[dst].home_region_start)
  supercut.region_end(voice, supercut_data[dst].home_region_end)
  supercut.buffer(voice, supercut_data[dst].home_buffer)
  
  update_loop_points(voice)
end

supercut.steal_voice_region = function(voice, dst)
  supercut.region_start(voice, supercut_data[dst].region_start)
  supercut.region_end(voice, supercut_data[dst].region_end)
  supercut.buffer(voice, supercut_data[dst].buffer)
  
  
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
    supercut_data[voice].level_input_cut[ch][util.clamp(1, #supercut_data[voice].subvoices, ch)] = amp
    softcut.level_input_cut(ch, supercut_data[voice].subvoices[util.clamp(1, #supercut_data[voice].subvoices, ch)], amp)
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

supercut.buffer_clear_region = function(voice, ...)
  if arg == nil then
    for i,v in ipairs(supercut_data[voice].subvoices) do
      -- softcut.buffer_clear_region_channel(supercut_data[voice].buffer[i], supercut_data[voice].region_start, supercut_data[voice].region_end)
      softcut.buffer_clear_region(supercut_data[voice].region_start, supercut_data[voice].region_end)
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

supercut.buffer_read = function(file, voice, ss, cs)
  local start_src = ss or 0
  local ch_src = cs or 1
  
  if util.file_exists(file) then
    if supercut_data[voice].io == "mono" then
      softcut.buffer_read_mono(file, start_src, supercut_data[voice].region_start, supercut_data[voice].region_length, ch_src, supercut_data[voice].buffer[1])
    else
      softcut.buffer_read_stereo(file, start_src, supercut_data[voice].region_start, supercut_data[voice].region_length)
    end
  end
end

supercut.buffer_write = function(file, voice)
  if supercut_data[voice].io == "mono" then
    softcut.buffer_write_mono(file, math.floor(supercut_data[voice].region_start), math.floor(supercut_data[voice].region_length), supercut_data[voice].buffer[1])
  else
    softcut.buffer_write_stereo(file, math.floor(supercut_data[voice].region_start), math.floor(supercut_data[voice].region_length))
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
        
        for k,w in pairs(tabutil.sort(v)) do
          
          k = w
          w = supercut_data[voice][k]
          
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
    
    for k,w in pairs(tabutil.sort(supercut_data[voice])) do
      
      k = w
      w = supercut_data[voice][k]
      
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