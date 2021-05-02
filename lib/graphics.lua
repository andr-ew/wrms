local segs = function()
  ret = {}
  
  for i = 1, 24 do
      ret[i] = false
  end
  
  return ret
end

--screen graphics
local gfx = {
    action = function() end,
    awake = { 1, 0 },
    sleep = function(s, n) s.sleep_index[n] = 24 end,
    wake = function(s, n) s.sleep_index[n] = 24 end,
    segment_awake = { segs(), segs() },
    sleep_index = { 24, 24 },
}

gfx.draw = function()
    local s = gfx
    local top = 5
    local mar = wrms.pos.mar

    --feed indicators
    screen.level(math.floor(sc.lvlmx[1].send * 4))
    screen.pixel(mar - 2 + 42, top + 23)
    screen.pixel(mar - 2 + 43, top + 24)
    screen.pixel(mar - 2 + 42, top + 25)
    screen.fill()
  
    screen.level(math.floor(sc.lvlmx[2].send * 4))
    screen.pixel(mar - 2 + 54, top + 23)
    screen.pixel(mar - 2 + 53, top + 24)
    screen.pixel(mar - 2 + 54, top + 25)
    screen.fill()

    --rate display
    --[[
    screen.level(6)
    screen.move(128, gfx.pos.y.key + 3)
    local rate = {}
    for i = 1,2 do rate[i] = 2^sc.ratemx[i].oct * sc.ratemx[i].dir end
    for i = 1,2 do rate[i] = (rate[i] >= 1 and math.floor(rate[i]) or rate[i]) end
    screen.text_right(rate[1] .. 'x ' .. rate[2] .. 'x')
    ]]
  
    for i = 1,2 do
        local left = mar + (i-1) * 58
        local top = 34
        local width = 40
        local r = reg.play:get_slice(i*2)
        local rrec = reg.rec:get_slice(i*2)
        local recorded = sc.punch_in[sc.buf[i]].recorded
        local recording = sc.punch_in[sc.buf[i]].recording
        screen.fill()

        --phase
        screen.level(2)
        if not recording then
            screen.pixel(left + width * r:get_start('fraction'), top) --loop start
            screen.fill()
        end
        if recorded then
            screen.pixel(left + width * r:get_end('fraction'), top) --loop end
            screen.fill()
        end

        screen.level(6 + 10 * sc.oldmx[i].rec)
        if not recorded then 
            -- rec line
            if recording then
                screen.move(left + width*rrec:get_start('fraction'), top + 1)
                screen.line(1 + left + width*rrec:get_end('fraction'), top + 1)
                screen.stroke()
            end
        else
            screen.pixel(left + width*sc.phase[i], top) -- loop point
            screen.fill()
        end

        local top = 18
        local width = 18
        local lowamp = 0.5
        local highamp = 1.75
        
        --octave
        --[[
        screen.move(41 + i + 1, top + (sc.ratemx[i].oct > 0 and 1 or 0))
        screen.level(3)
        screen.line(41 + i + 1, top - sc.ratemx[i].oct + 1)
        screen.stroke()
        ]]
        screen.level(2)
        screen.pixel(mar - 2 + 41 + i, top)
        screen.fill()
        screen.level(6)
        screen.pixel(mar - 2 + 41 + i, top - sc.ratemx[i].oct)
        screen.fill()
        
        
        --fun wrm animaions
        screen.level(math.floor(sc.lvlmx[i].vol * 10))

        local length = recorded and (
            sc.buf[i]==1 and (
                util.linexp(0, 
                    rrec:get_length(), 0.01, width, (r:get_length() + 3.25*2) / 2
                )
            ) or (
                util.linlin(0, rrec:get_length(), 0, width, r:get_length()*1.1 + 1)
            )
        ) or width

        local humps = sc.punch_in[sc.buf[i]].manual and 1 or 2
        --if i == 2 and sc.buf[2] == 1 then humps = 1 end

        for j = 1, length do
            local rl = r:get_end() - r:get_start(i)
            rl = rl > 0 and rl or rrec:get_length(i)

            local amp = 
                s.segment_awake[i][j] and (
                    math.sin(
                        (
                            (sc.phase_abs[i] - r:get_start())*(humps==1 and 1 or 2) 
                            / rl + j/length
                        )
                        * (humps == 1 and 2 or 4) * math.pi
                    ) * util.linlin(
                        1, length / 2, lowamp, highamp + sc.mod[1].mul, 
                        j < (length / 2) and j or length - j
                    ) 
                    - 0.75*util.linlin(
                        1, length / 2, lowamp, highamp + sc.mod[1].mul, 
                        j < (length / 2) and j or length - j
                    ) - (
                        util.linexp(0, 1, 0.5, 6, j/length) 
                        * (sc.ratemx[i].bnd - 1)
                    ) 
                ) or 0      
           
            local x = (width - length + 20) * r:get_start('fraction')
        
            screen.pixel(left + x + j - 1, top + amp)
        end
        screen.fill()
    end
end

gfx.sleep_clock = clock.run(function()
    local s = gfx
    while true do
        clock.sleep(1/150)
        for i = 1,2 do
            local si = s.sleep_index[i]
            if si > 0 and si <= 24 then
                s.segment_awake[i][math.floor(si)] = sc.punch_in[sc.buf[i]].recorded
                s.sleep_index[i] = si + 0.5*(sc.punch_in[sc.buf[i]].recorded and -1 or -2)
            end
        end
    end
end)

return gfx
