wrms_sens = 0.01
wrms_phase_quant = 0.01

wrms_page_n = 1
local get_page_n = function() return math.floor(wrms_page_n) end

wrms_pages = {}

wrms_lfo = include 'lib/hnds_wrms'
softloop = include 'lib/softloop'

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