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
  
  -- enc
  
  -- key
  
end