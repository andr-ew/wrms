--  _       ___________ ___  _____ 
-- | | /| / / ___/ __ `__ \/ ___/  
-- | |/ |/ / /  / / / / / (__  )   
-- |__/|__/_/  /_/ /_/ /_/____/    
--
-- dual asyncronous 
-- time-wigglers / echo loopers
--
-- version 2.0.0 @andrew
-- https://llllllll.co/t/wrms
--
-- two wrms (stereo loops), 
-- similar in function but each 
-- with thier own quirks + 
-- abilities
-- 
-- E1 up top changes which page 
-- is displayed. pages contain 
-- controls, mapped to norns’ 
-- lower keys and encoders. 
-- the location of the control 
-- shows which wrm will be 
-- affected. 

include 'wrms/lib/nest/core'
include 'wrms/lib/nest/norns'
include 'wrms/lib/nest/txt'

local warden = include 'wrms/lib/warden/warden'
local cs = require 'controlspec'
local reg = {}

--setup
local setup = function()
    for i = 1, 4 do
        softcut.enabled(i, 1)
        softcut.rec(i, 1)
    end
    for i = 1, 2 do
        softcut.pan(i*2 - 1, -1)
        softcut.pan(i*2, 1)
        
        softcut.phase_quant(i*2, 0.1)
    end
    softcut.event_phase(function(i, ph)
        if i == 2 then u.phase[1] = ph 
        elseif i == 4 then w.phase[2] = ph end
    end)
    softcut.poll_start_phase()

    reg.blank = warden.divide(warden.buffer_stereo, 2)
    reg.rec = warden.subloop(reg.blank)
    reg.play = warden.subloop(reg.rec, 2)
end

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
        { old = 0.5, mode = 'fb' },
        { old = 1, mode = 'pre' },
        update = function(s, n)
            local off = n == 1 and 0 or 2
            if mode == 'pre' then
                u.stereo('pre_level', n, s.old)
                softcut.level_cut_cut(1 + off, 2 + off, 0)
                softcut.level_cut_cut(2 + off, 1 + off, 0)
            else
                u.stereo('pre_level', n, 0)
                softcut.level_cut_cut(1 + off, 2 + off, s.old)
                softcut.level_cut_cut(2 + off, 1 + off, s.old)
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
    phase = { 0, 0 },
    voice = {
        { reg = 1 },
        { reg = 2 },
        slice = function(s, pair)
            local sub = (s[pair].reg == pair) and 1 or 2
            return reg.play[s[pair].reg][sub]
        end,
        update = function(s, pair)
            local off = (pair-1) * 2
            s:slice(pair):update_voice(off + 1, off + 2)
        end,
        update_all = function(s)
            for i = 1,2 do s:update(i) end
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
                reg.play[i][1]:set_length(1, 'fraction')
                reg.play[i][2]:set_length(1, 'fraction')

                u.voice:update(pair)

                s[i].clock = clock.run(function()
                    clock.sleep(s.quant)
                    s[i].t = s[i].t + (s.quant * u.ratemx[pair])
                end)

                s[i].recording = true
            elseif s[i].recording then
                u.stereo('rec_level', i, 0)

                reg.rec[i]:set_length(s[i].t)
                --reg.play[i][1]:set_length(1, 'fraction')
                --reg.play[i][2]:set_length(1, 'fraction')

                u.voice:update(pair)

                clock.cancel(s[i].clock)
                s[i].recorded = true
                s[i].recording = false
                s[i].t = 0

                --wrms.wake(2)
            end
        end,
        clear = function(s, pair)
            local i = u.voice[pair].reg
            u.stereo('rec_level', pair, 0)
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

--params
local params = {
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
    core = function() 
        for i = 1,2 do 
            params:add {
                type = 'control',
                id = 'vol ' .. i,
                controlspec = cs.def { default = 1, max = 2 },
                action = function(v)
                    u.lvlmx[i].vol = v
                    u.lvlmx:update(i)
                end
            }
            params:add {
                type = 'control',
                id = 'old ' .. i,
                default = 1,
                action = function(v)
                    u.oldmx[i].old = v
                    u.oldmx:update(i)
                end
            }
        end

        params:set('old 1', 0.5)
        params:set('old 2', 1)

        params:add {
            type = 'binary',
            behavior = 'toggle',
            id = 'rec 1'
            action = function(v)
                u.stereo('rec_level', 1, v)
                redraw()
            end
        }
        params:add {
            type = 'binary',
            behavior = 'trigger',
            id = 'clear 1',
            action = function()
                params:set('rec 1', 0)
                reg.rec[u.voice.reg[1]]:clear()
            end
        }
        params:add {
            type = 'binary',
            behavior = 'toggle',
            id = 'rec 2',
            action = function(v)
                u.punch_in:toggle(2, v)
                redraw()
            end
        }
        params:add {
            type = 'binary',
            behavior = 'trigger',
            id = 'clear 2',
            action = function()
                params:set('rec 2', 0)
                u.punch_in:clear(2)
            end
        }
    end,
    default = function()
        params:add {
            type = 'control', id = 'bnd',
            controlspec = cs.def { default = 1, min = 1, max = 2 },
            action = function(v)
                u.ratemx[1].bnd = v
                u.ratemx:update(1)
            end
        }
        params:add {
            type = 'control', id = 'wgl',
            controlspec = cs.def { min = 1, max = 100, quantum = 0.01/100 },
            action = function(v) u.mod.mul = v end
        }
    end
}

local _rec = function(i)
    return _txt.key.toggle {
        label = 'rec',
        v = function() return params:get('rec '..i) end,
        action = function(s, v, t)
            if t < 0.5 then params:set('rec '..i, v)
            else params:delta('clear '..i, 1) end
        end
    }
end

--screen interface
--todo: x, y, n
local wrms_ = nest_ {
    pages = nest_ {
        v = nest_ {
            vol = nest_(2):each(function(i)
                return u._iparam_ctl('vol', i, {
                    n = i + 1
                })
            end),
            rec = nest_(2):each(function(i)
                return _rec(i)
            end)
        },
        o = nest_ {
            old = nest_(2):each(function(i)
                return u._iparam_ctl('old', i, {
                    n = i + 1
                })
            end),
            rec = nest_(2):each(function(i)
                return _rec(i)
            end)
        },
        b = nest_ {
            bnd = u._param_ctl('bnd', 2, {
                n = 2
            }),
            wgl = u._param_ctl('wgl', 3, {
                n = 3
            }),
            trans = _txt.key.trigger {
                label = { '<<', '>>' },
                edge = 0,
                blinktime = 0.2,
                n = { 2, 3 },
                action = function(s, v, t, d, add, rem, l)
                    s.blinktime = u.slew(1, t)

                    if #l == 2 then
                        u.ratemx[1].dir = u.ratemx[1].dir * -1
                        u.ratemx:update()
                    else
                        local o = u.ratemx[1].oct
                        u.ratemx[1].oct = add==2 and o*2 or o/2
                        u.ratemx:update(1)
                    end
                end
            }
        },
        s = nest_ {
            s = _txt.enc.number {
                min = -math.huge, max = math.huge,
                n = 2,
                value = function() return voice:slice(1):get_start() end
                action = function(s, v) voice:slice(1):set_start(v) end
            },
            l = _txt.enc.number {
                min = -math.huge, max = math.huge,
                n = 3,
                value = function() return voice:slice(1):get_length() end
                action = function(s, v) voice:slice(1):set_length(v) end
            }
        }
    }
}

function init()
    setup()
    u.stereo('play', 1, 1)
    u.mod:init(1)
end

return { u = u, setup = setup, params = params, wrms_ = wrms_, reg = reg }
