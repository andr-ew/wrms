local param_ids = {}
local function add_param(args)
    table.insert(param_ids, args.id)
    params:add(args)
end


params:add_separator('mix')
local ir_op = { 'stereo', 'mono', '2x mono', 'left', 'right' } 
add_param{
    type = 'option', id = 'input routing', options = ir_op,
    action = function(v)
        sc.inmx.route = ir_op[v]
        for i = 1,2 do sc.inmx:update(i) end
    end
}
for i = 1,2 do
    add_param{
        type = 'control', id = 'in lvl '..i, controlspec = cs.def { default = 1 },
        action = function(v) sc.inmx[i].vol = v; sc.inmx:update(i) end
    }
    add_param{
        type = 'control', id = 'in pan '..i, controlspec = cs.PAN,
        action = function(v) sc.inmx[i].pan = v; sc.inmx:update(i) end
    }
    add_param{
        type = 'control', id = 'out pan '..i, controlspec = cs.PAN,
        action = function(v) sc.lvlmx[i].pan = v; sc.lvlmx:update(i) end
    }
end

params:add_separator('wrm controls')
for i = 1,2 do 
    add_param{
        type = 'control',
        id = 'vol ' .. i,
        controlspec = cs.def { default = 1, max = 2 },
        action = function(v)
            sc.lvlmx[i].vol = v
            sc.lvlmx:update(i)
        end
    }
    add_param{
        type = 'control',
        id = 'old ' .. i,
        controlspec = cs.def { default = i==1 and 0.5 or 1 },
        action = function(v)
            sc.oldmx[i].old = v
            sc.oldmx:update(i)
        end
    }
    local options = { 'overdub', 'feedback', 'ping-pong' } 
    add_param{
        type = 'option',
        id = 'old mode ' .. i,
        options = options, default = i==1 and 3 or 1,
        action = function(v)
            sc.oldmx[i].mode = options[v]
            sc.oldmx:update(i)
        end
    }
end
add_param{
    type = 'binary',
    behavior = 'toggle',
    id = 'rec 1', default = 1,
    action = function(v)
        sc.punch_in:toggle(1, v)
    end
}
add_param{
    type = 'binary',
    behavior = 'trigger',
    id = 'clear 1',
    action = function()
        params:set('rec 1', 0)
        params:set('dir 1', 2)
        sc.punch_in:clear(1)
    end
}
add_param{
    type = 'binary',
    behavior = 'toggle',
    id = 'rec 2',
    action = function(v)
        sc.punch_in:toggle(2, v)
    end
}
add_param{
    type = 'binary',
    behavior = 'trigger',
    id = 'clear 2',
    action = function()
        params:set('rec 2', 0)
        params:set('dir 2', 2)
        sc.punch_in:clear(2)
    end
}
for i = 1,2 do
    add_param{
        type = 'binary', behavior = 'trigger', id = 'res '..i,
        action = function() reg.play:trigger(i) end
    }
end
add_param{
    type = 'control', id = 'bnd 1',
    controlspec = cs.def { default = 1, min = 1, max = 2 },
    action = function(v)
        sc.ratemx[1].bnd = v
        sc.ratemx:update(1)
    end
}
for i = 1,2 do
    add_param{
        type = 'number', id = 'tp '..i, formatter = tp_fm,
        default = 0, min = -10*12, max = 4*12,
        action = function(v)
            sc.ratemx[i].bndw = v/12
            sc.ratemx:update(i)
        end
    }
end
add_param{
    type = 'control', id = 'wgl',
    controlspec = cs.def { min = 0, max = 10, quantum = 0.01/10, default = 0.05 },
    action = function(v) 
        local d = (util.linexp(0, 1, 0.01, 1, v) - 0.01) * 100
        sc.mod[1].mul = d * 0.01 
    end
}
add_param{
    type = 'control', id = 'wgrt',
    controlspec = cs.def { min = 0, max = 20, default = 0.4, quantum = 1/100 },
    action = function(v) 
        sc.mod[1].rate = v
    end
}
add_param{
    type = 'control', id = 'wgl in',
    controlspec = cs.def { default = 0, min = -2, max = 2, quant = 0.01/4 },
    action = function(v)
        for i = 1,2 do
            sc.ratemx[i].pitch = v
            sc.ratemx:update(i)
        end
    end
}
for i = 1,2 do
    add_param{
        type = 'number', id = 'oct '..i,
        min = -32, max = 4, default = 0,
        action = function(v) sc.ratemx[i].oct = v; sc.ratemx:update(i) end
    }
    local options = { -1, 1 }
    add_param{
        type = 'option', id = 'dir '..i, options = options, default = 2,
        action = function(v) sc.ratemx[i].dir = options[v]; sc.ratemx:update(i) end
    }
end
add_param{
    type = 'control', id = '>',
    controlspec = cs.def { default = 1 },
    action = function(v) sc.lvlmx[1].send = v; sc.lvlmx:update(1) end
}
add_param{
    type = 'control', id = '<',
    controlspec = cs.def { default = 0 },
    action = function(v) sc.lvlmx[2].send = v; sc.lvlmx:update(2) end
}
add_param{
    type = 'number', id = 'buf 1', default = 1,
    min = 1, max = 2, wrap = true,
    action = function(v) 
        sc.buf:assign(1, v, v) -- play[1][1] or play[2][2]
    end
}
add_param{
    type = 'number', id = 'buf 2', default = 2,
    min = 1, max = 2, wrap = true,
    action = function(v) 
        if v==1 then
            sc.buf:assign(2, 1, 1)  --play[1][1] or play[2][1]
            sc.punch_in[2].play = 1; sc.punch_in:update_play(2)
            if sc.punch_in[2].play == 0 then wrms_gfx:wake(2) end
        else
            sc.buf:assign(2, 2, 1) 
            sc.punch_in:update_play(2)
            if sc.punch_in[2].play == 0 then wrms_gfx:sleep(2) end
        end
    end
}
for i = 1,2 do
    add_param{
        type = 'control', id = 'f '..i,
        --controlspec = cs.new(20,20000,'exp',0,20000,'hz'),
        controlspec = cs.def { default = ({ 0.7, 1 })[i], quantum = 1/100/2, step = 0 },
        action = function(v) 
            sc.stereo('post_filter_fc', i, util.linexp(0, 1, 20, 20000, v)) 
        end
    }
    add_param{
        type = 'control', id = 'q '..i,
        --controlspec = cs.new(min,max,'exp',0,10),
        controlspec = cs.def { default = 0.4 },
        action = function(v)
            sc.stereo('post_filter_rq', i, util.linexp(0, 1, 0.01, 20, 1 - v))
        end
    }
    local options = { 'dry', 'lp', 'hp', 'bp' } 
    add_param{
        type = 'option', id = 'filter type '..i,
        options = options, default = ({ 2, 1 })[i],
        action = function(v)
            for _,k in pairs(options) do sc.stereo('post_filter_'..k, i, 0) end
            sc.stereo('post_filter_'..options[v], i, 1)
        end
    }
end
add_param{
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

params:add_separator('options')
do
    local options = { 'wrm1',  'both', 'wrm2' }
    add_param{
        type = 'option', id = 'wgl dest', options = options,
        action = function(v)
            sc.mod[1].dest = ({ 1, 'both', 2 })[v]
        end
    }
end
params:add {
    id = 'reset', type = 'binary', behavior = 'trigger',
    action = function()
        for i,id in ipairs(param_ids) do
            local p = params:lookup_param(id)
            params:set(id, p.default or (p.controlspec and p.controlspec.default) or 0)
        end

        wrms.reset()
        params:bang()
    end
}

params:add_separator('crow')
crowify:register('wgl in')
crowify:register('wgrt')
for i = 1,2 do
    for _,v in ipairs { 'res',  'f', 'vol', 'old', 'dir', 'oct', 'rec', 'filter type' } do
        crowify:register(v..' '..i)
    end
end
crowify:add_params()
