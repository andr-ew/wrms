--  _       ___________ ___  _____ 
-- | | /| / / ___/ __ `__ \/ ___/  
-- | |/ |/ / /  / / / / / (__  )   
-- |__/|__/_/  /_/ /_/ /_/____/    
--
-- dual asyncronous 
-- time-wigglers / echo loopers
--
-- version 2.0.0 @andrew
-- default template
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
warden = include 'wrms/lib/warden/warden'
cs = require 'controlspec'

local sc, reg, gfx, param = include 'wrms/lib/wrms'

--params
param.mix()
for i = 1,2 do 
    params:add {
        type = 'control',
        id = 'vol ' .. i,
        controlspec = cs.def { default = 1, max = 2 },
        action = function(v)
            sc.lvlmx[i].vol = v
            sc.lvlmx:update(i)
            redraw()
        end
    }
    params:add {
        type = 'control',
        id = 'old ' .. i,
        default = 1,
        action = function(v)
            sc.oldmx[i].old = v
            sc.oldmx:update(i)
            redraw()
        end
    }
    local options = { 'overdub', 'feedback', 'ping-pong' } 
    params:add {
        type = 'option',
        id = 'old mode ' .. i,
        options = options,
        action = function(v)
            oldmx[i].mode = options[v]
            oldmx:update(i)
        end
    }
end
params:add {
    type = 'binary',
    behavior = 'toggle',
    id = 'rec 1'
    action = function(v)
        sc.recmx[1].rec = v; sc.recmx:update(1)
        redraw()
    end
}
params:add {
    type = 'binary',
    behavior = 'trigger',
    id = 'clear 1',
    action = function()
        params:set('rec 1', 0)
        sc.voice:reg(1, 'rec'):clear()
    end
}
params:add {
    type = 'binary',
    behavior = 'toggle',
    id = 'rec 2',
    action = function(v)
        sc.punch_in:toggle(2, v)

        sc.voice:reg(1):update_voice(1, 2)
        sc.voice:reg(2):update_voice(3, 4)

        redraw()
    end
}
params:add {
    type = 'binary',
    behavior = 'trigger',
    id = 'clear 2',
    action = function()
        params:set('rec 2', 0)
        sc.punch_in:clear(2)
    end
}
params:add {
    type = 'control', id = 'bnd',
    controlspec = cs.def { default = 1, min = 1, max = 2 },
    action = function(v)
        sc.ratemx[1].bnd = v
        sc.ratemx:update(1)
        redraw()
    end
}
params:add {
    type = 'control', id = 'wgl',
    controlspec = cs.def { min = 1, max = 100, quantum = 0.01/100 },
    action = function(v) sc.mod.mul = v; redraw() end
}
params:add {
    type = 'control', id = '>',
    controlspec = cs.def { default = 1 },
    action = function(v) sc.lvlmx[1].send = v; sc.lvlmx:update(1); redraw() end
}
params:add {
    type = 'control', id = '<',
    controlspec = cs.def { default = 0 },
    action = function(v) sc.lvlmx[2].send = v; sc.lvlmx:update(2); redraw() end
}
params:add {
    type = 'number', id = 'buf 1', default = 1,
    min = 1, max = 2, wrap = true,
    action = function(v)
        sc.voice[1].reg = v
        sc.voice[1].reg_name = 'play'
        sc.voice:reg(1):update_voice(1, 2)
        sc.voice:reg(2):update_voice(3, 4)
    end
}
params:add {
    type = 'number', id = 'buf 2', default = 2,
    min = 1, max = 2, wrap = true,
    action = function(v)
        sc.voice[2].reg = v
        sc.voice[2].reg_name = v==1 and 'play' or 'rec'
        sc.voice:reg(1):update_voice(1, 2)
        sc.voice:reg(2):update_voice(3, 4)
    end
}
param.filter(1)

local x, y = gfx.pos.x, gfx.pos.y

local _rec = function(i)
    return _txt.key.toggle {
        n = i+1, x = x[i][1], y = y.key,
        label = 'rec',
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
        edge = 0,
        blinktime = 0.2,
        n = { 2, 3 },
        y = y.key, x = { { x[i][1] }, { x[i][2] } },
        action = function(s, v, t, d, add, rem, l)
            s.blinktime = sc.slew(i, t)

            if #l == 2 then
                sc.ratemx[i].dir = sc.ratemx[i].dir * -1
                sc.ratemx:update(i)
            else
                local o = sc.ratemx[i].oct
                sc.ratemx[i].oct = add==2 and o*2 or o/2
                sc.ratemx:update(i)
            end
        end
    } :merge(o)
end

--screen interface
wrms_ = nest_ {
    gfx = _screen {
        redraw = gfx.wrms.draw
    },
    tab = _txt.enc.option {
        n = 1, x = 128, y = 0, sens = 0.5, align = 'right',
        flow = 'y', options = { 'v', 'o', 'b', 's', '>', 'f' }
    },
    pages = nest_ {
        v = nest_ {
            vol = nest_(2):each(function(i)
                return sc._iparam_ctl('vol', i, {
                    n = i + 1, x = x[i][1], y = y.enc
                })
            end),
            rec = nest_(2):each(function(i)
                return _rec(i)
            end)
        },
        o = nest_ {
            old = nest_(2):each(function(i)
                return sc._iparam_ctl('old', i, {
                    n = i + 1, x = x[i][1], y = y.enc
                })
            end),
            rec = nest_(2):each(function(i)
               return _rec(i)
            end)
        },
        b = nest_ {
            bnd = sc._param_ctl('bnd', {
                n = 2, x = x[1][1], y = y.enc
            }),
            wgl = sc._param_ctl('wgl', {
                n = 3, x = x[1.5], y = y.enc
            }),
            trans = _trans(i, {})
        },
        s = nest_ {
            s = _txt.enc.number {
                min = 0, max = math.huge, inc = 0.01,
                n = 2, x = x[1][1], y = y.enc,
                value = function() return sc.voice:reg(1):get_start() end
                action = function(s, v)
                    sc.voice:reg(1):set_start(v)
                    sc.voice:reg(1):update_voice(1, 2)
                    sc.voice:reg(1):update_voice(3, 4)
                end
            },
            l = _txt.enc.number {
                min = 0, max = math.huge, inc = 0.01,
                n = 3, x = x[1][2], y = y.enc,
                value = function() return sc.voice:reg(1):get_length() end
                action = function(s, v)
                    sc.voice:reg(1):set_length(v)
                    sc.voice:reg(1):update_voice(1, 2)
                    sc.voice:reg(2):update_voice(1, 2)
                end
            },
            trans = _trans(i, {})
        },
        ['>'] = nest_ {
            ['>'] = sc._param_ctl('>', {
                n = 2, x = x[1][1], y = y.enc,
            }),
            ['<'] = sc._param_ctl('<', {
                n = 3, x = x[2][1], y = y.enc,
            }),
            buf = nest_(2):each(function(i)
                return _txt.key.number {
                    label = 'buf', n = i+1, x = x[i][1], y = y.key,
                    min = 1, max = 2, inc = 1, wrap = true, step = 1,
                    value = function() params:get('buf '..i) end,
                    action = function(s, v) params:set(l, v) end
                }
            end)
        },
        f = nest_ {
            f = sc._param_ctl('f', {
                n = 2, x = x[1][1], y = y.enc,
            }),
            q = sc._param_ctl('f', {
                n = 3, x = x[1][2], y = y.enc,
            }),
            type = _txt.key.option {
                n = { 2, 3 }, x = x[1][1], y = y.key,
                value = function() return params:get('filter type') end,
                action = function(s, v) params:set('filter type', v) end
            }
        }    
    }: each(function(k, v)
        v.enabled = function(s) return wrms_.tab.options[wrms_.tab.v//1] == k end
    end)
}

function init()
    sc.setup()
    sc.stereo('play', 1, 1)
    sc.mod:init(1)
    sc.mod:init(2)

    gfx.wrms.action = function() wrms_.gfx:update() end
end

function cleanup()
    --todo: save state for wrm 1 regions
end

return u, reg, param, gfx
