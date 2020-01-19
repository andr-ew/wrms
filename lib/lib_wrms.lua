wrms_sens = 0.1

wrms_page_n = 1
local get_page_n = function() return math.floor(wrms_page_n) end

wrms_pages = {}

wrms_loops = {
  {
    is_punch_in = false,
    has_initial = false,
    region_start = 0,
    region_end = 200,
    loop_start = 0,
    loop_end = 0,
    wrm_wgl = 0.2,
    wrm_bend = 0,
    wrm_lvl = 0
  },
  {
    is_punch_in = false,
    has_initial = false,
    region_start = 0,
    region_end = 200,
    loop_start = 0,
    loop_end = 0,
    wrm_wgl = 0.2,
    wrm_bend = 0,
    wrm_lvl = 0
  }
}

function wrms_init()
end

function wrms_enc(n, delta)
  if n == 1 then
    if delta > 0 then
      wrms_page_n = wrms_page_n + ((get_page_n() == #wrms_pages) and 0 or 0.5)
    else
      wrms_page_n = wrms_page_n - ((get_page_n() == 1) and 0 or 0.25)
    end
  else
    
  end
end

function wrms_key(n,z)
  if n == 1 then
  else
    if z == 1 then
    else
      
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
  
  local function get_x_pos(wrm1, wrm2)
    local ret
    
    if wrm1 == 1 and wrm2 == 2 then ret = { 0, 2 }
    elseif wrm1 == 1 and wrm2 == 1 then ret = { 0, 1 }
    elseif wrm1 == 2 and wrm2 == 2 then ret = { 2, 3 }
    elseif wrm1 == "both" and wrm2 == 2 then ret = { 1.5, 3 }
    elseif wrm1 == 1 and wrm2 == "both" then ret = { 0, 1.5 }
    else ret = { 2, 0 } end
    
    return ret
  end
  
  -- enc
  
  local ex = get_x_pos(wrms_pages[get_page_n()].e2.worm, wrms_pages[get_page_n()].e3.worm)
  for i,v in ipairs({ wrms_pages[get_page_n()].e2, wrms_pages[get_page_n()].e3 }) do
    screen.move(2 + ex[i] * 29, 44)
    screen.level(4)
    screen.text(v.label)
    screen.move(2 + (ex[i] * 29) + ((string.len(v.label) + 1) * 5), 44)
    screen.level(10)
    screen.text(v.value)
  end
  
  -- key
  local kx = get_x_pos(wrms_pages[get_page_n()].k2.worm, wrms_pages[get_page_n()].k3.worm)
  for i,v in ipairs({ wrms_pages[get_page_n()].k2, wrms_pages[get_page_n()].k3 }) do
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