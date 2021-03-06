--softcut buffer regions
local reg = {}
reg.blank = warden.divide(warden.buffer_stereo, 2)
reg.rec = warden.subloop(reg.blank)
reg.play = warden.subloop(reg.rec)

-- utility functions & tables
local u = {
    stereo = function(command, pair, ...)
        local off = (pair - 1) * 2
        for i = 1, 2 do
            softcut[command](off + i, ...)
        end
    end,
    lvlmx = {
        {
            vol = 1, send = 1, pan = 0,
            update = function(s)
                softcut.level_cut_cut(1, 3, s.send * s.vol)
                softcut.level_cut_cut(2, 4, s.send * s.vol)
            end
        }, {
            vol = 1, send = 0, pan = 0,
            update = function(s)
                softcut.level_cut_cut(3, 1, s.send * s.vol)
                softcut.level_cut_cut(4, 2, s.send * s.vol)
            end
        },
        update = function(s, n)
            local v, p = s[n].vol, s[n].pan
            local off = (pair - 1) * 2
            softcut.level(off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level(off + 2, v * ((p < 0) and 1 - p or 1))
            s[n]:update()
        end
    },
    oldmx = {
        { old = 0.5, mode = 'ping-pong' },
        { old = 1, mode = 'overdub' },
        update = function(s, n)
            local off = n == 1 and 0 or 2
            if mode == 'overdub' then
                u.stereo('pre_level', n, s.old)
                softcut.level_cut_cut(1 + off, 2 + off, 0)
                softcut.level_cut_cut(2 + off, 1 + off, 0)
            else
                u.stereo('pre_level', n, 0)
                if mode == 'ping-pong' then
                    softcut.level_cut_cut(1 + off, 2 + off, s.old)
                    softcut.level_cut_cut(2 + off, 1 + off, s.old)
                else
                    softcut.level_cut_cut(1 + off, 1 + off, s.old)
                    softcut.level_cut_cut(2 + off, 2 + off, s.old)
                end
            end
        end
    },
    mod = {  
        { rate = 0, mul = 0, phase = 0,
            shape = function(p) return math.sin(2 * math.pi * p) end
            action = function(v) for i = 1,2 do
                u.ratemx[i].mod = v; u.ratemx:update(i)
            end end
        },
        { rate = 0, mul = 0, phase = 0,
            shape = function(p) return math.sin(2 * math.pi * p) end
            action = function(v) end
        },
        quant = 0.01, 
        init = function(s, n)
            s[n].clock = clock.run(function()
                clock.sleep(s.quant)

                local T = 1/s[n].rate
                local d = s.quant / T
                s[n].phase = s[n].phase + d
                while s[n].phase > 1 do s[n].phase = s[n].phase - 1 end

                s[n].action(s[n].shape(s[n].phase) * s[n].mul)
            end)
        end
    },
    ratemx = {
        { oct = 1, bnd = 1, mod = 0, dir = 1, rate = 0 },
        { oct = 1, bnd = 1, mod = 0, dir = -1, rate = 0 },
        update = function(s, n)
            s[n].rate = s[n].oct * 2^(s[n].bnd - 1) * 2^s[n].mod * s[n].dir
            u.stereo('rate', n, s[n].rate)
        end
    },
    slew = function(n, t)
        local st = (2 + (math.random() * 0.5)) * t 
        u.stereo('rate_slew_time', n, st)
        return st
    end,
    input = function(pair, inn, chan) return function(v) 
        local off = (pair - 1) * 2
        local vc = (chan - 1) + off
        softcut.level_input_cut(inn, vc, v)
    end end,
    voice = {
        { reg = 1, reg_name = 'play' },
        { reg = 2, reg_name = 'rec' },
        reg = function(s, pair, name) 
            name = name or s[pair].reg_name
            return reg[name][s[pair].reg] 
        end
    },
    punch_in = {
        quant = 0.01,
        { recording = false, recorded = false, t = 0, clock = nil },
        { recording = false, recorded = false, t = 0, clock = nil },
        toggle = function(s, pair, v)
            local i = u.voice[pair].reg

            if s[i].recorded then
                u.stereo('rec_level', pair, v)
            elseif v == 1 then
                u.stereo('rec_level', pair, 1)
                u.stereo('play', pair, 1)

                reg.rec[i]:set_length(1, 'fraction')
                reg.play[i]:set_length(1, 'fraction')

                s[i].clock = clock.run(function()
                    clock.sleep(s.quant)
                    s[i].t = s[i].t + (s.quant * u.ratemx[pair])
                end)

                s[i].recording = true
            elseif s[i].recording then
                u.stereo('rec_level', i, 0)

                reg.rec[i]:set_length(s[i].t)
                reg.play[i]:set_length(1, 'fraction')

                clock.cancel(s[i].clock)
                s[i].recorded = true
                s[i].recording = false
                s[i].t = 0

                --wrms.wake(2)
            end
        end,
        clear = function(s, pair)
            u.stereo('rec_level', pair, 0)

            local i = u.voice[pair].reg
            reg.rec[i]:clear()

            clock.cancel(s[i].clock)
            s[i].recorded = false
            s[i].recording = false
            s[i].t = 0
        end
    },
    _param_ctl = function(id, o)
        return _txt.enc.control {
            label = id,
            controlspec = params:lookup_param(id).controlspec,
            value = function() return params:get(id) end,
            action = function(s, v) params:set(id, v) end
        } :merge(o)
    end,
    _iparam_ctl = function(label, i, o)
        return _txt.enc.control {
            label = label,
            controlspec = params:lookup_param(label ..' '..i).controlspec,
            value = function() return params:get(label ..' '..i) end,
            action = function(s, v) params:set(label ..' '..i, v) end
        } :merge(o)
    end
}

--screen graphics
local mar, mul = 2, 29
local gfx = {
    pos = { 
        x = {
            [1] = { mar, mar + mul },
            [1.5] = mar + mul*1.5,
            [2] = { mar + mul*2, mar + mul*3 }
        }, 
        y = {
            enc = 46,
            key = 46 + 10
        }
    },
    wrms = {
        phase = { 0, 0 },
        draw = function()
            --feed indicators
            screen.level(math.floor(supercut.feed(1) * 4))
            screen.pixel(42, 23)
            screen.pixel(43, 24)
            screen.pixel(42, 25)
            screen.fill()
          
            screen.level(math.floor(supercut.feed(2) * 4))
            screen.pixel(54, 23)
            screen.pixel(53, 24)
            screen.pixel(54, 25)
            screen.fill()
          
            for i = 1,2 do
                local left = 2 + (i-1) * 58
                local top = 34
                local width = 44
                
                --phase
                screen.level(2)
                if supercut.is_punch_in(i) == false then
                    screen.pixel(left + width * supercut.loop_start(i) / supercut.region_length(i), top) --loop start
                    screen.fill()
                end
                if supercut.has_initial(i) then
                    screen.pixel(left + width * supercut.loop_end(i) / supercut.region_length(i), top) --loop end
                    screen.fill()
                end
        
                screen.level(6 + 10 * supercut.rec(i))
                if supercut.has_initial(i) == false then -- rec line
                    if supercut.is_punch_in(i) then
                        screen.move(left + width * util.clamp(0, 1, supercut.loop_start(i) / supercut.region_length(i)), top + 1)
                        screen.line(1 + left + width * math.abs(util.clamp(0, 1, supercut.region_position(i) / supercut.region_length(i))), top + 1)
                        screen.stroke()
                    end
                else
                    screen.pixel(left + width * supercut.region_position(i) / supercut.region_length(i), top) -- loop point
                    screen.fill()
                end
        
                --fun wrm animaions
                local top = 18
                local width = 24
                local lowamp = 0.5
                local highamp = 1.75
        
                screen.level(math.floor(supercut.level(i) * 10))
                local width = util.linexp(0, (supercut.region_length(i)), 0.01, width, (supercut.loop_length(i)  + 4.125))
                for j = 1, width do
                    local amp = supercut.segment_is_awake(i)[j] and math.sin(((supercut.position(i) - supercut.loop_start(i)) * (i == 1 and 1 or 2) / (supercut.loop_end(i) - supercut.loop_start(i)) + j / width) * (i == 1 and 2 or 4) * math.pi) * util.linlin(1, width / 2, lowamp, highamp + supercut.wiggle(i), j < (width / 2) and j or width - j) - 0.75 * util.linlin(1, width / 2, lowamp, highamp + supercut.wiggle(i), j < (width / 2) and j or width - j) - (util.linexp(0, 1, 0.5, 6, j/width) * (supercut.rate2(i) - 1)) or 0      
                    local left = left - (supercut.loop_start(i)) / (supercut.region_length(i)) * (width - 44)
                
                    screen.pixel(left - 1 + j, top + amp)
                end
                screen.fill()
        
            end
        end,
        update = function()
            wrms_.gfx:update()
        end
    }   
}

--param utilities
local param = {
    mix = function()
        params:add_seperator('mix')
        for i = 1,2 do
            params:add_control("in L > wrm " .. i .. "  L", "in L > wrm " .. i .. "  L", controlspec.new(0,1,'lin',0,1,''))
            params:set_action("in L > wrm " .. i .. "  L", u.input(i, 1, 1))

            params:add_control("in L > wrm " .. i .. "  R", "in L > wrm " .. i .. "  R", controlspec.new(0,1,'lin',0,0,''))
            params:set_action("in L > wrm " .. i .. "  R", u.input(i, 1, 2))
            
            params:add_control("in R > wrm " .. i .. "  R", "in R > wrm " .. i .. "  R", controlspec.new(0,1,'lin',0,1,''))
            params:set_action("in R > wrm " .. i .. "  R", u.input(i, 2, 2))

            params:add_control("in R > wrm " .. i .. "  L", "in R > wrm " .. i .. "  L", controlspec.new(0,1,'lin',0,0,''))
            params:set_action("in R > wrm " .. i .. "  L", u.input(i, 2, 1))

            params:add_control("wrm " .. i .. " pan", "wrm " .. i .. " pan", controlspec.PAN)
            params:set_action("wrm " .. i .. " pan", function(v) 
                u.lvlmx[i].pan = v 
                u.lvlmx:update(i)
            end)
        end
        params:add_seperator('wrms')
    end,
    filter = function(i)
        params:add {
            type = 'control', id = 'f', 
            controlspec = cs.new(50,5000,'exp',0,5000,'hz'),
            action = function(v) 
                u.stereo('post_filter_fc', i, v) 
                redraw()
            end
        }
        params:add {
            type = 'control', id = 'q',
            controlspec = cs.RQ,
            action = function(v) 
                u.stereo('post_filter_rq', i, v) 
                redraw()
            end
        }
        local options = { 'lp', 'bp', 'hp' } 
        params:add {
            type = 'option', id = 'filter type',
            options = options,
            action = function(v)
                for _,k in ipairs(options) do stereo('post_filter_'..k, i, 0) end
                stereo('post_filter_'..options[v], i, 1)
                redraw()
            end
        }
    end
}

return u, reg, gfx, param
