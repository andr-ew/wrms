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
    for i = 1, 2 do
        softcut.pan(i*2 - 1, -1)
        softcut.pan(i*2, 1)
        softcut.play(i, 1)

        --phase event -> update wrm.phase
    end
    for i = 1, 4 do
        softcut.rec(i, 1)
    end

    reg.blank = warden.divide(warden.buffer[1], 2)
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
    },
    ratemx = {
        { oct = 1, bnd = 1, mod = 0, dir = 1 },
        { oct = 1, bnd = 1, mod = 0, dir = -1 },
        update = function(s, n)
            u.stereo('rate', n, s.oct * 2^(s.bnd - 1) * 2^mod * dir)
        end
    },
    wrm = {
        phase = { 0, 0 },
        reg = { 
            1, 2,
            update = function(s, pair)
                local off = (pair-1) * 2
                local sub = (s[pair] == pair) and 1 or 2

                reg.play[pair][sub]:update_voice(off + 1, off + 2)
            end,
            update_all = function(s)
                for i = 1,2 do s:update(i) end
            end
        }
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
    punch_in = {
        { recording = false, recorded = false },
        { recording = false, recorded = false },
        toggle = function(s, pair, v)
            local i = u.wrm.reg[pair]

            if s[i].recorded then
                u.stereo('rec_level', pair, v)
            elseif v == 1 then
                u.stereo('rec_level', pair, 1)
                u.stereo('play', pair, 1)

                reg.rec[i]:set_length(1, 'fraction')
                reg.play[i][1]:set_length(1, 'fraction')
                reg.play[i][2]:set_length(1, 'fraction')

                u.wrm.reg:update_all()

                s[i].recording = true
            elseif s[i].recording then
                u.stereo('rec_level', i, 0)

                reg.rec[i]:set_length(u.phase[i] - 0.1)
                --reg.play[i][1]:set_length(1, 'fraction')
                --reg.play[i][2]:set_length(1, 'fraction')

                u.wrm.reg:update_all()

                s[i].recorded = true
                s[i].recording = false

                --wrms.wake(2)
            end
        end
    }
}

--screen interface
--todo: x, y, n
local rec = nest_ {
    _txt.key.toggle {
        label = 'rec', v = 1,
        action = function(s, v, t)
            if t < 0.5 then
                u.stereo('rec_level', 1, v)
            else
                u.stereo('rec_level', 1, 0)
                u.reg2('rec', 1, 'clear')

                return 0
            end
        end
    },
    _txt.key.toggle {
        label = 'rec', v = 0,
        action = function(s, v, t)
            if t < 0.5 then
            else
                return 0
            end
        end
    }
}

wrms_ = nest_ {
    pages = nest_ {
        -- todo: link these to params using v functions
        v = nest_ {
            vol = nest_(2):each(function(i)
                return _txt.enc.control {
                    label = 'vol',
                    v = 1, max = 2,
                    action = function(s, v)
                        u.lvlmx[i].vol = v
                        u.lvlmx:update(i)
                    end
                }
            end),
            rec = rec
        },
        o = nest_ {
            old = nest_(2):each(function(i)
                return _txt.enc.control {
                    label = 'old',
                    action = function(s, v)
                        u.oldmx[i].old = v
                        u.oldmx:update(i)
                    end
                }
            end),

            -- since rec is in the structure twice, p & k are ambiguous,
            -- but i think that's totally ok on paper - make sure it works!
            rec = rec
        },
        b = nest_ {
            bnd = _txt.enc.control {
                min = 1, max = 2, v = 1,
                action = function(s, v)
                    u.ratemx[1].bnd = v
                    u.ratemx:update(1)
                end
            },
            wgl = _txt.enc.control {
                min = 1, max = 100, quantum = 0.01/100,
                action = function(s, v) u.mod.amount = v end
            },
            oct = 1,
            dir = 1,
            slew = 0,
            trans = _txt.key.trigger {
                label = { '<<', '>>' },
                edge = 0,
                --set blink time to slew time
                action = function(s, v, t, d, add, rem, l)
                    u.slew(1, t)

                    if #l == 2 then
                        s.p.dir = s.p.dir * -1
                        u.ratemx[1].dir = s.p.dir
                        u.ratemx:update()
                    else
                        s.p.oct = (add == 2) and (s.p.oct * 2) or (s.p.oct / 2)
                        u.ratemx[2].oct = s.p.oct
                        u.ratemx:update(2)
                    end
                end
            }
        },
        s = nest_ {
            -- improved number for start & length. v is a function bound to wrdn
        }
    }
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
    end,
    core = function() 
        params:add_seperator('wrms')
        for i = 1,2 do 
            params:add {
                type = 'control',
                id = 'vol ' .. i,
                controlspec = cs.def { default = 1, max = 2 }
            }
            params:add {
                type = 'control',
                id = 'old ' .. i,
                default = 1,
            }
            params:add {
                type = 'binary',
                behavior = 'toggle',
                id = 'rec ' .. i,
                action = function(v)
                    wrms_.pages.v.rec[i].v = v
                    wrms_.pages.v.rec[i]:update()
                end
            }
            params:add {
                type = 'binary',
                behavior = 'trigger',
                id = 'clear ' .. i,
                action = function()
                    u.clear(i)
                end
            }
        end

        params:set('old 1', 0.5)
        params:set('old 2', 1)
    end,
    default = function()
    end
}

return { u = u, setup = setup, params = params, wrms_ = wrms_, reg = reg }
