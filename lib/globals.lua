local sh = norns.is_shield
mar, mul = sh and 2 or 18, 29

local wrms = {
    pos = { 
        x = {
            [1] = { mar, mar + mul },
            [1.5] = mar + mul*1.5,
            [2] = { mar + mul*2, mar + mul*3 },
            tab = sh and 128 or 1
        }, 
        y = {
            tab = 10,
            enc = 46,
            key = 46 + 10
        },
        mar = mar, mul = mul
    }
}

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
        for id,v in pairs(s.data) do s:remember(id, s.active[id]) end
        return s.data
    end,
    load = function(s, data)
        --reset some of the pitch data
        for i = 1,2 do
            data.buf[2]['oct '..i] = 0
            data.buf[2]['dir '..i] = 2
        end
        data.buf[3]['oct 2'] = 0
        data.buf[0]['oct 1'] = 0

        s.data = data
        for id,v in pairs(s.data) do s:recall(id, s.active[id]) end
    end,
    set = function(s, id, active)
        s:remember(id, s.active[id])
        s:recall(id, active)
        s.active[id] = active
    end
}

function wrms.setup()
    sc.setup()
    sc.mod:init(1)
end

function wrms.save(n)
    local filename = norns.state.data..'wrms-'..(n or 0)..'.data'
    tab.save({
        preset = wrms.preset:save(),
        length = sc.length:save(),
        punch_in = sc.punch_in:save()
    }, filename)
end

function wrms.load(n)
    data = {
        --hardcode save file for testing, later copy to ./data/init/
        preset = wrms.preset:save(),
        length = { { 0.4, 0 }, { 0, 0 } },
        punch_in = { true, false }
    }

    wrms.preset:load(data.preset)
    sc.length.load(data.length)
    sc.punch_in:load(data.punch_in)

    --reset non-preset rate params
    params:set('bnd 1', 1)
    for i = 1,2 do 
        params:set('tp '..i, 0)
    end
end

return wrms
