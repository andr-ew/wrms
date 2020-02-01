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

softloop = {}

local softloop_data = softcut.defaults()

-- create default functions
for k,v in pairs(softloop_data[1]) do
  local f = function(key)
    local key = key
    
    return function(voice, ...)
      if arg ~= nil then
        if #arg == 1 then
          softloop_data[voice][key] = arg[1]
        else
          softloop_data[voice][key][arg[1]] = arg[2]
        end
        
        for i,v in ipairs(softloop_data[voice].subvoices) do
          softcut[key](v, unpack(arg))
        end
      else
        return softloop_data[voice][key]
      end
    end
  end
  
  softloop[k] = f(k)
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
  softloop.buffer(i, home[i].buffer)
  softloop.loop_start(i, home[i].region_start)
  softloop.loop_end(i, home[i].region_end)
end

-- additional data to store
for i,v in ipairs(softloop_data) do
  v.io = "mono"
  v.subvoices = { i }
  v.home_region_start = home[i].region_start
  v.home_region_end = home[i].region_end
  v.home_region_length = home[i].region_end - home[i].region_start
  v.home_buffer = home[i].buffer
  v.region_start = v.home_region_start
  v.region_end = v.home_region_end
  v.region_length = v.region_end - v.region_start
  v.rate2 = 1
  v.rate3 = 1
  v.rate4 = 1
end

-- delagate subvoices
local delegate = function()
  local i = 1
  local iv = 1
  
  while i <= softcut.VOICE_COUNT do
    if softloop_data[i].io == "mono" then
      softloop_data[i].subvoices = { i }
      i = i + 1
    else
      softloop_data[i].subvoices = { i, i + 1 }
      i = i + 2
    end
    
    iv = iv + 1
  end
  
  for i = iv + 1, softcut.VOICE_COUNT do 
    softloop_data[i].io = "mono"
    softloop_data[i].subvoices = {}
  end
end

-- a gaggle of manually defined voice functions 

softloop.io = function(voice, val) 
  softloop_data[voice].io = val
  delegate()
end

softloop.rate = function(voice, val) 
  softloop_data[voice].rate = val
  
  for i,v in ipairs(softloop_data[voice].subvoices) do
    softcut.rate(v, softloop.rate * softloop.rate2 * softloop.rate3 * softloop.rate4)
  end
end
softloop.rate2 = function(voice, val) 
  softloop_data[voice].rate2 = val
  
  for i,v in ipairs(softloop_data[voice].subvoices) do
    softcut.rate(v, softloop.rate * softloop.rate2 * softloop.rate3 * softloop.rate4)
  end
end
softloop.rate3 = function(voice, val) 
  softloop_data[voice].rate3 = val
  
  for i,v in ipairs(softloop_data[voice].subvoices) do
    softcut.rate(v, softloop.rate * softloop.rate2 * softloop.rate3 * softloop.rate4)
  end
end
softloop.rate4 = function(voice, val) 
  softloop_data[voice].rate4 = val
  
  for i,v in ipairs(softloop_data[voice].subvoices) do
    softcut.rate(v, softloop.rate * softloop.rate2 * softloop.rate3 * softloop.rate4)
  end
end
  
softloop.pan = function(voice, val) 
  softloop_data[voice].pan = val
  
  if softloop_data[voice].io == "mono" then
    if softloop_data[i].subvoices[1] ~= nil then 
      softcut.pan(softloop_data[i].subvoices[1], val)
    end
  else
    softcut.pan(softloop_data[i].subvoices[1], -1)
    softcut.pan(softloop_data[i].subvoices[2], 1)
    
    softcut.level(softloop_data[i].subvoices[1], softloop_data[i].level * (val > 0) and 1 - val or 1)
    softcut.level(softloop_data[i].subvoices[2], softloop_data[i].level * (val < 0) and 1 - math.abs(val) or 1)
  end
end

softloop.level = function(voice, val)
  softloop_data[voice].level = val
  
  if softloop_data[voice].io == "mono" then
    if softloop_data[i].subvoices[1] ~= nil then 
      softcut.level(softloop_data[i].subvoices[1], val)
    end
  else
    local p = softloop_data[voice].pan
    
    softcut.level(softloop_data[i].subvoices[1], val * (p > 0) and 1 - p or 1)
    softcut.level(softloop_data[i].subvoices[2], val * (p < 0) and 1 - math.abs(p) or 1)
  end
end
softloop.home_region_start = function(voice, val) end
softloop.home_region_end = function(voice, val) end
softloop.home_region_length = function(voice, val) end
softloop.home_buffer = function(voice, val) end
softloop.region_start = function(voice, val) end
softloop.region_end = function(voice, val) end
softloop.region_length = function(voice, val) end
softloop.loop_start = function(voice, val) end
softloop.loop_end = function(voice, val) end
softloop.use_region = function(voice, val) end
softloop.level_cut_cut = function(voice, val) end
softloop.level_input_cut = function(voice, val) end

-- phase stuff - auto-update positions
softloop.event_phase = function(f) end

setmetatable(softloop, { __index = softcut })