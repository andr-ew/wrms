--TODO
--mix: in levels & in pans
--alt >: inpan 1, outpan 2, aa
--tp: trim digits
--combine punch-in & delay behaviors
--  (punch or len>0) -> loop -> clear
--  wrm1 starts at step 2
--persistence 
--  paramset
--  all preset data
--  regions
--  clear punched in loops, 
--  reset all pitch data
--grid ????????? 
--use _affordance:link() when available
--gfx = _screen { } when available


--cartographer hax
Slice.skew = 0

function Slice:update()
    --re-clamp start/end
    self.startend[1] = util.clamp(self.startend[1], self.bounds[1], self.bounds[2])
    self.startend[2] = util.clamp(self.startend[2], self.startend[1], self.bounds[2])

    local b = self.buffer
    for i,v in ipairs(self.voices) do
        softcut.loop_start(v, self.startend[1])
        softcut.loop_end(v, 
            self.startend[2]
            + (self.skew)*(i==1 and 0 or -1)
        )
        softcut.buffer(v, b[(i - 1)%(#b) + 1])
    end

    --propagate downward
    for i,v in ipairs(self.children) do
        v:update()
    end
end

--softcut buffer regions
local reg = {}
reg.blank = cartographer.divide(cartographer.buffer_stereo, 2)
reg.rec = cartographer.subloop(reg.blank)
reg.play = cartographer.subloop(reg.rec, 2)

local sc, gfx, param

-- softcut utilities
sc = {
    setup = function()
        audio.level_cut(1.0)
        audio.level_adc_cut(1)
        audio.level_eng_cut(1)

        for i = 1, 4 do
            softcut.enable(i, 1)
            softcut.rec(i, 1)
            softcut.loop(i, 1)
            softcut.level_slew_time(i, 0.1)
            softcut.recpre_slew_time(i, 0.1)
            softcut.rate(i, 1)
            softcut.post_filter_dry(i, 0)
        end
        for i = 1, 2 do
            local l, r = i*2 - 1, i*2

            softcut.pan(l, -1)
            softcut.pan(r, 1)
            softcut.level_input_cut(1, r, 1)
            softcut.level_input_cut(2, r, 0)
            softcut.level_input_cut(1, l, 0)
            softcut.level_input_cut(2, l, 1)
            
            softcut.phase_quant(i*2 - 1, 1/60)
            sc.slew(i, 0.2)
        end

        local function e(i, ph)
            if i == 1 then gfx.wrms:set_phase(1, ph) 
            elseif i == 3 then 
                gfx.wrms:set_phase(2, ph)
                redraw()
            end
        end

        softcut.event_phase(e)
        softcut.poll_start_phase()
    end,
    scoot = function()
        reg.play:position(2, 0)
        reg.play:position(4, 0)
    end,
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
            local off = (n - 1) * 2
            softcut.level(off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level(off + 2, v * ((p < 0) and 1 - p or 1))
            s[n]:update()
        end
    },
    oldmx = {
        { old = 0.5, mode = 'ping-pong', rec = 1 },
        { old = 1, mode = 'overdub', rec = 0 },
        update = function(s, n)
            local off = n == 1 and 0 or 2
            local mode = s[n].mode

            sc.stereo('rec_level', n, s[n].rec)
            if s[n].rec == 0 then
                sc.stereo('pre_level', n, 1)
            else
                if mode == 'overdub' then
                    sc.stereo('pre_level', n, s[n].old)
                    softcut.level_cut_cut(1 + off, 2 + off, 0)
                    softcut.level_cut_cut(2 + off, 1 + off, 0)
                else
                    sc.stereo('pre_level', n, 0)
                    if mode == 'ping-pong' then
                        softcut.level_cut_cut(1 + off, 2 + off, s[n].old)
                        softcut.level_cut_cut(2 + off, 1 + off, s[n].old)
                    else
                        softcut.level_cut_cut(1 + off, 1 + off, s[n].old)
                        softcut.level_cut_cut(2 + off, 2 + off, s[n].old)
                    end
                end
            end
        end
    },
    mod = {  
        { rate = 0.4, mul = 0, phase = 0,
            shape = function(p) return math.sin(2 * math.pi * p) end,
            action = function(v) for i = 1,2 do
                sc.ratemx[i].mod = v; sc.ratemx:update(i)
            end end
        },
        quant = 0.01, 
        init = function(s, n)
            s[n].clock = clock.run(function()
                while true do
                    clock.sleep(s.quant)

                    local T = 1/s[n].rate
                    local d = s.quant / T
                    s[n].phase = s[n].phase + d
                    while s[n].phase > 1 do s[n].phase = s[n].phase - 1 end

                    s[n].action(s[n].shape(s[n].phase) * s[n].mul)
                end
            end)
        end
    },
    ratemx = {
        { oct = 1, bnd = 1, bndw = 0, mod = 0, dir = 1, rate = 0 },
        { oct = 1, bnd = 1, bndw = 0, mod = 0, dir = 1, rate = 0 },
        update = function(s, n)
            s[n].rate = 2^s[n].oct * 2^(s[n].bnd - 1) * 2^s[n].bndw * (1 + s[n].mod) * s[n].dir
            sc.stereo('rate', n, s[n].rate)
        end
    },
    slew = function(n, t)
        local st = (2 + (math.random() * 0.5)) * (t or 0)
        sc.stereo('rate_slew_time', n, st)
        return st
    end,
    input = function(pair, inn, chan) return function(v) 
        local off = (pair - 1) * 2
        local vc = (chan - 1) + off
        softcut.level_input_cut(inn, vc, v)
    end end,
    buf = {
        1, 2, -- [pair] = buf
        assign = function(s, pair, buf, slice)
            local off = (pair - 1) * 2
            s[pair] = buf
            cartographer.assign(reg.play[buf][slice], 1 + off, 2 + off)

            param.preset:set((s[1]-1) + (s[2]-1)*2)
        end
    },
    punch_in = {
        quant = 0.01,
        { recording = false, recorded = true, play = 0, t = 0, clock = nil },
        { recording = false, recorded = false, play = 0, t = 0, clock = nil },
        update_play = function(s, pair)
            sc.stereo('play', pair, s[pair].play)
        end,
        toggle = function(s, pair, v) --only use when pair==2 and voice[2]==2
            local i = pair * 2

            if s[pair].recorded then
                sc.oldmx[pair].rec = v; sc.oldmx:update(pair)
            elseif v == 1 then
                sc.oldmx[pair].rec = 1; sc.oldmx:update(pair)

                reg.rec:trigger(i)

                s[pair].play = 1; s:update_play(pair)

                -- set quant to sc.ratemx.rate * s.quant
                reg.rec:punch_in(i)

                s[pair].recording = true
            elseif s[pair].recording then
                sc.oldmx[pair].rec = 0; sc.oldmx:update(pair)
            
                reg.rec:punch_out(i)

                s[pair].recorded = true
                s[pair].recording = false

                gfx.wrms:wake(pair)
            end
        end,
        clear = function(s, pair)
            local i = pair * 2

            sc.oldmx[pair].rec = 0; sc.oldmx:update(pair)
            s[pair].play = 0; s:update_play(pair)

            reg.rec:position(i, 0)
            reg.rec:clear(i)
            reg.rec:punch_out(i)

            s[pair].recorded = false
            s[pair].recording = false

            reg.rec:expand(i)
                
            gfx.wrms:sleep(pair)

            --[[
            sc.ratemx[pair].oct = 1
            sc.ratemx[pair].dir = 1
            sc.ratemx:update(pair)
            --]]
        end
    }
}

local segs = function()
  ret = {}
  
  for i = 1, 24 do
      ret[i] = false
  end
  
  return ret
end

local mar, mul = 2, 29

--screen graphics
gfx = {
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
        phase_abs = { 0, 0 },
        set_phase = function(s, n, v)
            s.phase_abs[n] = v
            s.phase[n] = reg.rec:phase_relative(n*2, v, 'fraction')
        end,
        action = function() end,
        sleep = function(s, n) s.sleep_index[n] = 24 end,
        wake = function(s, n) s.sleep_index[n] = 24 end,
        segment_awake = { segs(), segs() },
        sleep_index = { 24, 24 },
        draw = function()
            local s = gfx.wrms
            local top = 5

            --feed indicators
            screen.level(math.floor(sc.lvlmx[1].send * 4))
            screen.pixel(42, top + 23)
            screen.pixel(43, top + 24)
            screen.pixel(42, top + 25)
            screen.fill()
          
            screen.level(math.floor(sc.lvlmx[2].send * 4))
            screen.pixel(54, top + 23)
            screen.pixel(53, top + 24)
            screen.pixel(54, top + 25)
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
                local left = 2 + (i-1) * 58
                local top = 34
                local width = 44
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
                    screen.pixel(left + width*s.phase[i], top) -- loop point
                    screen.fill()
                end
        
                local top = 18
                local width = 24
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
                screen.pixel(41 + i, top)
                screen.fill()
                screen.level(6)
                screen.pixel(41 + i, top - sc.ratemx[i].oct)
                screen.fill()
                
                
                --fun wrm animaions
                screen.level(math.floor(sc.lvlmx[i].vol * 10))

                local length = sc.buf[i]==1 and (
                    util.linexp(0, 
                        rrec:get_length(), 0.01, width, (r:get_length() + 3.25*2) / 2
                    )
                ) or (
                    util.linlin(0, rrec:get_length(), 0, width, r:get_length()*1.1 + 1)
                )
                local humps = i
                if i == 2 and sc.buf[2] == 1 then humps = 1 end

                for j = 1, length do
                    local amp = 
                        s.segment_awake[i][j] and (
                            math.sin(
                                (
                                    (s.phase_abs[i] - r:get_start())*(humps==1 and 1 or 2) 
                                    / (r:get_end() - r:get_start(i)) + j/length
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
    }   
}

gfx.wrms.sleep_clock = clock.run(function()
    local s = gfx.wrms
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

--param utilities
param = {
    preset = {
        [0] = {
            ['rec 1'] = 1, 
            ['>'] = 0, ['<'] = 0, 
            ['filter type 1'] = 2, 
            ['filter type 2'] = 2,
            ['f1'] = 0.7, ['f2'] = 0.7,
            ['oct 1'] = 0, ['oct 2'] = -1,
            ['dir 1'] = 2, ['dir 2'] = 1
        },
        [3] = {
            ['rec 1'] = 0, 
            ['>'] = 0, ['<'] = 0, 
            ['filter type 1'] = 2, 
            ['filter type 2'] = 2,
            ['f1'] = 0.9, ['f2'] = 0.9,
            ['oct 1'] = 1, ['oct 2'] = 0,
            ['dir 1'] = 2, ['dir 2'] = 2
        },
        active = 2,
        save = function(s, i) 
            local keys = s[#s]
            s[i] = {}
            for k,_ in pairs(keys) do s[i][k] = params:get(k) end
        end,
        load = function(s, i)
            if s[i] then for k,v in pairs(s[i]) do params:set(k, v) end end
        end,
        set = function(s, active)
            s:save(s.active)
            s:load(active)
            s.active = active
        end
    },
    _control = function(id, o)
        return _txt.enc.control {
            label = id,
            controlspec = params:lookup_param(id).controlspec,
            value = function() return params:get(id) end,
            action = function(s, v) params:set(id, v) end
        } :merge(o)
    end,
    _icontrol = function(label, i, o)
        return _txt.enc.control {
            label = label,
            controlspec = params:lookup_param(label ..' '..i).controlspec,
            value = function() return params:get(label ..' '..i) end,
            action = function(s, v) params:set(label ..' '..i, v) end
        } :merge(o)
    end
}

return sc, gfx, param, reg
