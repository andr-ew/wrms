--TODO
--persistence 
--  paramset
--  all preset data
--  manual lengths
--  reset all pitch data
--add 'in mode' param - mono, stereo
--tp: display +/-st (nest)
--punch-in varispeed (cartographer -> rate_query)
--s: small length bugs (cartographer) (add delta_startend)
--gfx = _screen { } when available
--pan: map input/output based on record state
--tap tempo o->K3/4
--K1+E1 alt lock
--bug: old mode ping-pong overdub -> ping-pong
--config.lua >> ./data/init, config post_init
--move the whole nest to config.lua (!)


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

-- softcut utilities
local sc = {
    phase = { 0, 0 },
    phase_abs = { 0, 0 },
    set_phase = function(s, n, v)
        s.phase_abs[n] = v
        s.phase[n] = reg.rec:phase_relative(n*2, v, 'fraction')
    end,
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
            if i == 1 then sc:set_phase(1, ph) 
            elseif i == 3 then 
                sc:set_phase(2, ph)
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
            softcut.level(off + 2, v * ((p < 0) and 1 + p or 1))
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
    inmx = {
        { vol = 1, pan = 0 },
        { vol = 1, pan = 0 },
        update = function(s, n)
            local v, p = s[n].vol, s[n].pan
            local off = (n - 1) * 2
            softcut.level_input_cut(1, off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level_input_cut(2, off + 1, 0)
            softcut.level_input_cut(2, off + 2, v * ((p < 0) and 1 + p or 1))
            softcut.level_input_cut(1, off + 2, 0)
        end
    },
    --buf, punch_in, length -> buf
    buf = {
        1, 2, -- [pair] = buf
        assign = function(s, pair, buf, slice)
            local off = (pair - 1) * 2
            s[pair] = buf
            cartographer.assign(reg.play[buf][slice], 1 + off, 2 + off)

            wrms.preset:set('buf', (s[1]-1) + (s[2]-1)*2)
        end
    },
    punch_in = {
        quant = 0.01,
        delay_size = 4,
        { recording = false, recorded = false, manual = false, big = true, play = 0, t = 0, clock = nil },
        { recording = false, recorded = false, manual = false, big = false, play = 0, t = 0, clock = nil },
        update_play = function(s, buf)
            sc.stereo('play', buf, s[buf].play)
        end,
        big = function(s, pair, v)
            local buf = sc.buf[pair]
            if v > 0.2 then s[buf].big = true end
        end,
        toggle = function(s, pair, v)
            local buf = sc.buf[pair]
            local i = buf * 2

            if pair ~= buf then
                sc.oldmx[pair].rec = v; sc.oldmx:update(pair)
            elseif s[buf].recorded then
                sc.oldmx[buf].rec = v; sc.oldmx:update(buf)
            elseif v == 1 then
                sc.oldmx[buf].rec = 1; sc.oldmx:update(buf)
                s[buf].play = 1; s:update_play(buf)

                --[[
                reg.blank:set_length(i, 16777216 / 48000 / 2)
                reg.rec:punch_in(i)
                --]]
                -- set quant to sc.ratemx.rate * s.quant
                reg.blank[buf]:set_length(16777216 / 48000 / 2)
                reg.rec[buf]:punch_in()

                s[buf].manual = false
                wrms.preset:set('manual '..buf, s[buf].manual)

                s[buf].recording = true
            elseif s[buf].recording then
                sc.oldmx[buf].rec = 0; sc.oldmx:update(buf)
            
                --reg.rec:punch_out(i)
                reg.rec[buf]:punch_out()

                s[buf].recorded = true
                s[buf].big = true
                s[buf].recording = false

                wrms.gfx:wake(buf)
            end
        end,
        manual = function(s, pair)
            local buf = sc.buf[pair]
            if not s[buf].recorded then
                reg.blank[buf]:set_length(s.delay_size)
                
                s[buf].manual = true
                wrms.preset:set('manual '..buf, s[buf].manual)

                sc.oldmx[buf].rec = 1; sc.oldmx:update(buf)
                s[buf].play = 1; s:update_play(buf)

                s[buf].recorded = true
                wrms.gfx:wake(buf)
            end
        end,
        clear = function(s, pair)
            local buf = sc.buf[pair]
            local i = buf * 2

            s[buf].play = 0; s:update_play(buf)

            --[[
            reg.rec:position(i, 0)
            reg.rec:clear(i)
            reg.rec:punch_out(i)
            --]]
            reg.rec[buf]:position(0)
            reg.rec[buf]:clear()
            reg.rec[buf]:punch_out()


            s[buf].recorded = false
            s[buf].recording = false
            s[buf].big = false
            s[buf].manual = false

            reg.rec[buf]:expand()
            for j = 1,2 do
                reg.play[buf][j]:set_length(0)
            end
                
            wrms.gfx:sleep(buf)
        end,
        save = function(s)
            local data = {}
            for i,v in ipairs(s) do data[i] = s[i].manual end
            return data
        end,
        load = function(s, data)
            for i,v in ipairs(data) do
                s[i].manual = v
                if v==true then 
                    s:manual(i)
                    s:big(i, reg.play:get_length(i*2))
                else 
                    --s:clear(i) 
                    if sc.buf[i]==i then params:delta('clear '..i) end
                end
            end
        end
    },
    length = {
        save = function()
            local data = {}
            for i,v in ipairs(reg.play) do
                data[i] = {}
                for j,w in ipairs(v) do
                    data[i][j] = v:get_length()        
                end
            end
            return data
        end,
        load = function(data) --run before punch_in:load()
            for i,v in ipairs(data) do
                for j,w in ipairs(v) do
                    reg.play[i][j]:set_length(w)
                end
            end
        end
    }
}

return sc, reg
