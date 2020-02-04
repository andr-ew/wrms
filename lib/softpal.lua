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

softpal = {}

local softpal_data = softcut.defaults()

-- create default functions
for k,v in pairs(softpal_data[1]) do
  local f = function(key)
    local key = key
    
    return function(voice, ...)
      if arg ~= nil then
        if #arg == 1 then
          softpal_data[voice][key] = arg[1]
        else
          softpal_data[voice][key][arg[1]] = arg[2]
        end
        
        for i,v in ipairs(softpal_data[voice].subvoices) do
          softcut[key](v, unpack(arg))
        end
      else
        return softpal_data[voice][key]
      end
    end
  end
  
  softpal[k] = f(k)
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

-- set defaults to match regions
for i = 1, softcut.VOICE_COUNT do
  softpal.buffer(i, home[i].buffer)
  softpal.loop_start(i, home[i].region_start)
  softpal.loop_end(i, home[i].region_end)
end

-- additional data to store
for i,v in ipairs(softpal_data) do
  v.io = "mono"
  v.subvoices = { i }
  v.home_region_start = home[i].region_start
  v.home_region_end = home[i].region_end
  v.home_region_length = home[i].region_end - home[i].region_start
  v.home_buffer = home[i].buffer
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
end

-- delagate subvoices
local delegate = function()
  local i = 1
  local iv = 1
  
  while i <= softcut.VOICE_COUNT do
    if softpal_data[i].io == "mono" then
      softpal_data[i].subvoices = { i }
      i = i + 1
    else
      softpal_data[i].subvoices = { i, i + 1 }
      i = i + 2
    end
    
    iv = iv + 1
  end
  
  for i = iv + 1, softcut.VOICE_COUNT do 
    softpal_data[i].io = "mono"
    softpal_data[i].subvoices = {}
  end
end

-- manually defined voice functions 

softpal.io = function(voice, val) 
  if val == nil then return softpal_data[voice].io end
  
  softpal_data[voice].io = val
  delegate()
end

softpal.rate = function(voice, val) 
  if val == nil then return softpal_data[voice].rate end
  
  softpal_data[voice].rate = val
  
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.rate(v, softpal.rate * softpal.rate2 * softpal.rate3 * softpal.rate4)
  end
end
softpal.rate2 = function(voice, val) 
  if val == nil then return softpal_data[voice].rate2 end
  
  softpal_data[voice].rate2 = val
  
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.rate(v, softpal.rate * softpal.rate2 * softpal.rate3 * softpal.rate4)
  end
end
softpal.rate3 = function(voice, val) 
  if val == nil then return softpal_data[voice].rate3 end
  
  softpal_data[voice].rate3 = val
  
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.rate(v, softpal.rate * softpal.rate2 * softpal.rate3 * softpal.rate4)
  end
end
softpal.rate4 = function(voice, val) 
  if val == nil then return softpal_data[voice].rate4 end
  
  softpal_data[voice].rate4 = val
  
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.rate(v, softpal.rate * softpal.rate2 * softpal.rate3 * softpal.rate4)
  end
end
  
softpal.pan = function(voice, val)
  if val == nil then return softpal_data[voice].pan end
  
  softpal_data[voice].pan = val
  
  if softpal_data[voice].io == "mono" then
    if softpal_data[i].subvoices[1] ~= nil then 
      softcut.pan(softpal_data[i].subvoices[1], val)
    end
  else
    softcut.pan(softpal_data[i].subvoices[1], -1)
    softcut.pan(softpal_data[i].subvoices[2], 1)
    
    softcut.level(softpal_data[i].subvoices[1], softpal_data[i].level * (val > 0) and 1 - val or 1)
    softcut.level(softpal_data[i].subvoices[2], softpal_data[i].level * (val < 0) and 1 - math.abs(val) or 1)
  end
end

softpal.level = function(voice, val)
  if val == nil then return softpal_data[voice].level end
  
  softpal_data[voice].level = val
  
  if softpal_data[voice].io == "mono" then
    if softpal_data[i].subvoices[1] ~= nil then 
      softcut.level(softpal_data[i].subvoices[1], val)
    end
  else
    local p = softpal_data[voice].pan
    
    softcut.level(softpal_data[i].subvoices[1], val * (p > 0) and 1 - p or 1)
    softcut.level(softpal_data[i].subvoices[2], val * (p < 0) and 1 - math.abs(p) or 1)
  end
end

local update_loop_points = function(voice)
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.loop_start(util.clamp(softpal_data[voice].region_start, softpal_data[voice].region_end, softpal_data[voice].region_start + softpal_data[voice].loop_start))
    softcut.loop_end(util.clamp(softpal_data[voice].region_start, softpal_data[voice].region_end, softpal_data[voice].region_start + softpal_data[voice].loop_end))
  end
end

softpal.home_region_start = function(voice, val)
  if val == nil then return softpal_data[voice].home_region_start end
  
  softpal_data[voice].home_region_start = val 
end
softpal.home_region_end = function(voice, val)
  if val == nil then return softpal_data[voice].home_region_end end
  
  softpal_data[voice].home_region_end = val 
  softpal_data[voice].home_region_length = softpal_data[voice].home_region_end - softpal_data[voice].home_region_start
end
softpal.home_region_length = function(voice, val)
  if val == nil then return softpal_data[voice].home_region_length end
  
  softpal_data[voice].home_region_length = v
  softpal_data[voice].home_region_end = softpal_data[voice].home_region_start + val 
end
softpal.home_buffer = function(voice, val)
  if val == nil then return softpal_data[voice].home_buffer end
  
  softpal_data[voice].home_buffer = val 
end
softpal.region_start = function(voice, val)
  if val == nil then return softpal_data[voice].region_start end
  
  softpal_data[voice].region_start = val
  update_loop_points(voice)
end
softpal.region_end = function(voice, val)
  if val == nil then return softpal_data[voice].region_end end
  
  softpal_data[voice].region_end = val
  softpal_data[voice].region_length = softpal_data[voice].region_end - softpal_data[voice].region_start
  update_loop_points(voice)
end
softpal.region_length = function(voice, val)
  if val == nil then return softpal_data[voice].region_length end
  
  softpal_data[voice].region_length = val
  softpal_data[voice].region_end = softpal_data[voice].region_start + val
  update_loop_points(voice)
end
softpal.loop_start = function(voice, val)
  if val == nil then return softpal_data[voice].loop_start end
  
  softpal_data[voice].loop_start = val 
  update_loop_points(voice)
end
softpal.loop_end = function(voice, val)
  if val == nil then return softpal_data[voice].loop_end end
  
  softpal_data[voice].loop_end = val
  softpal_data[voice].loop_length = softpal_data[voice].loop_end - softpal_data[voice].loop_start
  update_loop_points(voice)
end
softpal.loop_length = function(voice, val)
  if val == nil then return softpal_data[voice].loop_length end
  
  softpal_data[voice].loop_length = val
  softpal_data[voice].loop_end = softpal_data[voice].loop_start + val
  
  update_loop_points(voice)
end

softpal.use_voice_home_region = function(voice, val)
  softpal.region_start(voice, softpal_data[voice].home_region_start)
  softpal.region_end(voice, softpal_data[voice].home_region_end)
  
  update_loop_points(voice)
end

softpal.use_voice_region = function(voice, val)
  softpal.region_start(voice, softpal_data[voice].region_start)
  softpal.region_end(voice, softpal_data[voice].region_end)
  
  update_loop_points(voice)
end

softpal.home_region_position = function(voice, val)
  if val == nil then return softpal_data[voice].home_region_position end
  
  softpal_data[voice].home_region_position = val
  
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.position(voice, softpal_data[voice].home_region_start + util.clamp(0, softpal_data[voice].home_region_length, val))
  end
end
softpal.region_position = function(voice, val)
  if val == nil then return softpal_data[voice].region_position end
  
  softpal_data[voice].region_position = val
  
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.position(voice, softpal_data[voice].region_start + util.clamp(0, softpal_data[voice].region_length, val))
  end
end
softpal.loop_position = function(voice, val)
  if val == nil then return softpal_data[voice].loop_position end
  
  softpal_data[voice].loop_position = val
  
  for i,v in ipairs(softpal_data[voice].subvoices) do
    softcut.position(voice, softpal_data[voice].loop_start + util.clamp(0, softpal_data[voice].loop_length, val))
  end
end

-- phase stuff - auto-update positions

local softpal_event_phase = function(voice, p) end
local softcut_event_phase = function(voice, p) 
  softpal_data[voice].home_region_position = val - softpal_data[voice].home_region_start
  softpal_data[voice].region_position = val - softpal_data[voice].region_start
  softpal_data[voice].loop_position = val - softpal_data[voice].loop_start
  
  softpal_event_phase(voice, p)
end

softpal.event_phase = function(f) softpal_event_phase = f end
softcut.event_phase(softcut_event_phase)

setmetatable(softpal, { __index = softcut })

return softpal