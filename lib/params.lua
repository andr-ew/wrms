wrms.preset = { 
    data = {
        buf = {
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
            }
        },
        ['manual 1'] = {
            [false] = {
                ['old 1'] = 1,
                ['old mode 1'] = 1 --overdub
            }
        },
        ['manual 2'] = {
            [true] = {
                ['old 2'] = 0.5,
            }
        },
    },
    active = {
        buf = 2,
        ['manual 1'] = true,
        ['manual 2'] = false
    },
    remember = function(s, id, i) 
        local _, any = next(s.data[id]) --any table value
        s.data[id][i] = {}
        for k,_ in pairs(any) do s.data[id][i][k] = params:get(k) end
    end,
    recall = function(s, id, i)
        if s.data[id][i] then for k,v in pairs(s.data[id][i]) do params:set(k, v) end end
    end,
    save = function(s)
    end,
    load = function(s, st)
        --reset both buf[2].oct,dir
        --reset buf[3][oct 2], buf[0][oct 1]

        --go agead and recall once done, params should be banged already
    end,
    set = function(s, id, active)
        s:remember(id, s.active[id])
        s:recall(id, active)
        s.active[id] = active
    end
}

params:add_separator('mix')
for i = 1,2 do
    params:add {
        type = 'control', id = 'in lvl '..i, controlspec = cs.def { default = 1 },
        action = function(v) sc.inmx[i].vol = v; sc.inmx:update(i) end
    }
    params:add {
        type = 'control', id = 'in pan '..i, controlspec = cs.PAN,
        action = function(v) sc.inmx[i].pan = v; sc.inmx:update(i) end
    }
    params:add {
        type = 'control', id = 'out pan '..i, controlspec = cs.PAN,
        action = function(v) sc.lvlmx[i].pan = v; sc.lvlmx:update(i) end
    }
end
params:add_separator('wrms')
for i = 1,2 do 
    params:add {
        type = 'control',
        id = 'vol ' .. i,
        controlspec = cs.def { default = 1, max = 2 },
        action = function(v)
            sc.lvlmx[i].vol = v
            sc.lvlmx:update(i)
        end
    }
    params:add {
        type = 'control',
        id = 'old ' .. i,
        controlspec = cs.def { default = i==1 and 0.5 or 1 },
        action = function(v)
            sc.oldmx[i].old = v
            sc.oldmx:update(i)
        end
    }
    local options = { 'overdub', 'feedback', 'ping-pong' } 
    params:add {
        type = 'option',
        id = 'old mode ' .. i,
        options = options, default = i==1 and 3 or 1,
        action = function(v)
            sc.oldmx[i].mode = options[v]
            sc.oldmx:update(i)
        end
    }
end
params:add {
    type = 'binary',
    behavior = 'toggle',
    id = 'rec 1', default = 1,
    action = function(v)
        sc.punch_in:toggle(1, v)
    end
}
params:add {
    type = 'binary',
    behavior = 'trigger',
    id = 'clear 1',
    action = function()
        params:set('rec 1', 0)
        sc.punch_in:clear(1)
    end
}
params:add {
    type = 'binary',
    behavior = 'toggle',
    id = 'rec 2',
    action = function(v)
        if sc.buf[2]==2 then
            sc.punch_in:toggle(2, v)
        else
            -- regular record toggle probably
        end
    end
}
params:add {
    type = 'binary',
    behavior = 'trigger',
    id = 'clear 2',
    action = function()
        params:set('rec 2', 0)

        if sc.buf[2]==2 then
            sc.punch_in:clear(2)
            params:set('oct 2', 0)
            params:set('dir 2', 2)
        else
        end
    end
}
params:add {
    type = 'control', id = 'bnd 1',
    controlspec = cs.def { default = 1, min = 1, max = 2 },
    action = function(v)
        sc.ratemx[1].bnd = v
        sc.ratemx:update(1)
    end
}
params:add {
    type = 'control', id = 'tp 1', 
    controlspec = cs.def { 
        default = 0, min = -10, max = 4, quantum = 1/12/14, step = 1/12
    },
    action = function(v)
        sc.ratemx[1].bndw = v
        sc.ratemx:update(1)
    end
}
params:add {
    type = 'control', id = 'tp 2',
    controlspec = cs.def { 
        default = 0, min = -10, max = 4, quantum = 1/12/14, step = 1/12
    },
    action = function(v)
        sc.ratemx[2].bndw = v
        sc.ratemx:update(2)
    end
}
params:add {
    type = 'control', id = 'wgl',
    controlspec = cs.def { min = 0, max = 100, quantum = 0.01/100 },
    action = function(v) 
        local d = (util.linexp(0, 1, 0.01, 1, v) - 0.01) * 100
        sc.mod[1].mul = d * 0.01 
    end
}
for i = 1,2 do
    params:add {
        type = 'number', id = 'oct '..i,
        min = -32, max = 4, default = 0,
        action = function(v) sc.ratemx[i].oct = v; sc.ratemx:update(i) end
    }
    local options = { -1, 1 }
    params:add {
        type = 'option', id = 'dir '..i, options = options, default = 2,
        action = function(v) sc.ratemx[i].dir = options[v]; sc.ratemx:update(i) end
    }
end
params:add {
    type = 'control', id = '>',
    controlspec = cs.def { default = 1 },
    action = function(v) sc.lvlmx[1].send = v; sc.lvlmx:update(1) end
}
params:add {
    type = 'control', id = '<',
    controlspec = cs.def { default = 0 },
    action = function(v) sc.lvlmx[2].send = v; sc.lvlmx:update(2) end
}
params:add {
    type = 'number', id = 'buf 1', default = 1,
    min = 1, max = 2, wrap = true,
    action = function(v) 
        sc.buf:assign(1, v, v) -- play[1][1] or play[2][2]
    end
}
params:add {
    type = 'number', id = 'buf 2', default = 2,
    min = 1, max = 2, wrap = true,
    action = function(v) 
        if v==1 then
            sc.buf:assign(2, 1, 1)  --play[1][1] or play[2][1]
            sc.stereo('play', 2, 1)
            if sc.punch_in[2].play == 0 then wrms.gfx:wake(2) end
        else
            sc.buf:assign(2, 2, 1) 
            sc.punch_in:update_play(2)
            if sc.punch_in[2].play == 0 then wrms.gfx:sleep(2) end
        end
    end
}
for i = 1,2 do
    params:add {
        type = 'control', id = 'f'..i,
        --controlspec = cs.new(20,20000,'exp',0,20000,'hz'),
        controlspec = cs.def { default = 1, quantum = 1/100/2, step = 0 },
        action = function(v) 
            sc.stereo('post_filter_fc', i, util.linexp(0, 1, 20, 20000, v)) 
        end
    }
    params:add {
        type = 'control', id = 'q'..i,
        --controlspec = cs.new(min,max,'exp',0,10),
        controlspec = cs.def { default = 0.4 },
        action = function(v)
            sc.stereo('post_filter_rq', i, util.linexp(0, 1, 0.01, 20, 1 - v))
        end
    }
    local options = { 'dry', 'lp', 'hp', 'bp' } 
    params:add {
        type = 'option', id = 'filter type '..i,
        options = options,
        action = function(v)
            for _,k in pairs(options) do sc.stereo('post_filter_'..k, i, 0) end
            sc.stereo('post_filter_'..options[v], i, 1)
        end
    }
end
params:add {
    type = 'binary', id = 'aliasing', behavior = 'toggle', default = 0,
    action = function(v)
        for i = 1,4 do
            if v==1 then
                softcut.pre_filter_dry(i, 1)
                softcut.pre_filter_lp(i, 0)
            else
                softcut.pre_filter_dry(i, 0)
                softcut.pre_filter_lp(i, 1)
            end
        end
    end
}
