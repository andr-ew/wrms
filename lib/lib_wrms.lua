wrms_sens = 0.1

wrms_page_n = 1
local get_page_n = function() return math.floor(wrms_page_n) end

wrms_pages = {}

wrms_loop = {
  {
    punch_in_time = nil,
    has_initial = true,
    region_start = 200,
    region_end = 301,
    loop_start = 201,
    loop_end = 230,
    rate = 1,
    wrm_wgl = 0.2,
    wrm_bend = 0,
    wrm_lvl = 0
  },
  {
    punch_in_time = nil,
    has_initial = false,
    region_start = 1,
    region_end = 201,
    loop_start = 1,
    loop_end = 201,
    rate = 1,
    wrm_wgl = 0.2,
    wrm_bend = 0,
    wrm_lvl = 0
  }
}

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
      e.value = util.clamp(e.value + (delta * (e.sens == nil and wrms_sens or e.sens)), e.range[1], e.range[2])
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
      screen.move(2 + ex[i] * 29, 44)
      screen.level(4)
      screen.text(v.label)
      screen.move(2 + (ex[i] * 29) + ((string.len(v.label) + 0.5) * 5), 44)
      screen.level(10)
      screen.text(v.value)
    end
  end
  
  -- key
  local kx = get_x_pos(wrms_pages[get_page_n()].k2, wrms_pages[get_page_n()].k3)
  for i,v in ipairs({ wrms_pages[get_page_n()].k2, wrms_pages[get_page_n()].k3 }) do
    if v ~= nil then
      screen.move(2 + kx[i] * 29, 44 + 10)
      
      if v.behavior == "enum" then
        screen.level(8)
        screen.text(v.label[math.floor(v.value)])
      else
        screen.level(v.value * 10 + 2)
        screen.text(v.label)
      end
    end
  end
end