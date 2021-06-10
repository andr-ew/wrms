-- 
-- wrms/lite
--
-- simple stereo delay & looper
--
-- version 2.0.0 @andrew
-- https://norns.community/
--         authors/andrew/
--         wrms#wrmslite
--
-- E1 changes which page 
-- is displayed. pages contain 
-- controls, mapped to the
-- lower keys and encoders. 
-- the location of the control 
-- (left, right, center)
-- shows which wrm will be 
-- affected.
--
-- wrm 1 (on the left) is a delay 
-- & wrm 2 (on the right) is a 
-- live looper. feed the wrms 
-- some audio to begin exploring! 
-- tap K3 once to begin 
-- recording a loop, then again 
-- to begin playback.
--
-- for documentation of each 
-- control, head to:
-- https://norns.community/
--         authors/andrew/
--         wrms#wrmslite

function r() norns.script.load(norns.script.state) end

--external libs
include 'wrms/lib/nest/core'
include 'wrms/lib/nest/norns'
include 'wrms/lib/nest/txt'
cartographer, Slice = include 'wrms/lib/cartographer/cartographer'
crowify = include 'wrms/lib/crowify/lib/crowify' .new(0.01)
cs = require 'controlspec'

wrms = include 'wrms/lib/globals'      --saving, loading, values, etc
sc, reg = include 'wrms/lib/softcut'   --softcut utilities
wrms.gfx = include 'wrms/lib/graphics' --graphics & animations
include 'wrms/lib/params'              --create params


local x, y = wrms.pos.x, wrms.pos.y

local _rec = function(i)
    return _txt.key.toggle {
        n = i+1, x = x[i][1], y = y.key,
        label = 'rec', edge = 'falling',
        v = function() return params:get('rec '..i) end,
        action = function(s, v, t)
            if t < 0.5 then params:set('rec '..i, v)
            else params:delta('clear '..i, 1) end
        end
    }
end
local _trans = function(i, o)
    return _txt.key.trigger {
        label = { '<<', '>>' },
        edge = 'falling',
        blinktime = 0.2,
        n = { 2, 3 },
        y = y.key, x = { { x[i][1] }, { x[i][2] } },
        action = function(s, v, t, d, add, rem, l)
            s.blinktime = sc.slew(i, t[add]) / 2

            if #l == 2 then
                params:set('dir '..i, params:get('dir '..i)==1 and 2 or 1)
            else
                params:delta('oct '..i, add==2 and 1 or -1)
            end
        end
    } :merge(o)
end

--the wrmslite template
wrms_ = nest_ {
    gfx = _screen {
        redraw = wrms.gfx.draw
    },
    tab = _txt.enc.option {
        n = 1, x = x.tab, y = y.tab, sens = 0.5, align = sh and 'right' or 'left', margin = 2,
        flow = 'y', options = { 1, 2, 3 },
        lvl = { 4, 15 }
    },
    pages = nest_ {
        [1] = nest_ {
            v = _txt.enc.control {
                n = 2, x = x[1][1], y = y.enc,
            } :param('vol 1'),
            l = _txt.enc.number {
                min = 0, max = math.huge, inc = 0.01,
                n = 3, x = x[1][2], y = y.enc, step = 1/100/100/100,
                value = function() return reg.play:get_length(1) end,
                sens = function(s) 
                    return sc.punch_in[sc.buf[1]].big and (
                        s.p_.v <= 0.00019 and 1/100/100 or s.p_.v <= 0.019 and 1/100 or 1 
                    ) or 1
                end,
                action = function(s, v)
                    reg.play:set_length(1, v)
                    
                    if v > 0 and not sc.punch_in[sc.buf[1]].recorded then 
                        params:set('rec 1', 1, true)
                        sc.punch_in:manual(1) 
                    end
                    sc.punch_in:big(1, v)
                    sc.fade(1, v)
                    sc.punch_in:untap(1)
                end
            },
            rec = _rec(2)
        },
        [2] = nest_ {
            old = nest_(2):each(function(i)
                return _txt.enc.control {
                    n = i + 1, x = x[i][1], y = y.enc, label = 'old'
                } :param('old '..i)
            end),
            rec = _rec(2)
        },
        [3] = nest_ {
            bnd = _txt.enc.control {
                n = 2, x = x[1][1], y = y.enc, label = 'bnd',
                min = -1, max = 1,
                action = function(s, v) 
                    sc.ratemx[1].bnd = v + 1
                    sc.ratemx:update(1)
                end
            },
            wgl = _txt.enc.control {
                n = 3, x = x[1.5], y = y.enc
            } :param('wgl'),
            trans = _trans(2, {})
        }
    } :each(function(k, v)
        v.enabled = function(s) return wrms_.tab.options[wrms_.tab.v//1] == k end
    end)
} :connect { screen = screen, enc = enc, key = key } 

function init()
    params:set('>', 0)
    params:set('<', 1)

    wrms.setup()
    params:read()
    wrms.load()

    params:bang()
    wrms_:init()
end

function cleanup()
    -- wrms.save()
    -- params:write()
end
