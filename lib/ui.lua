local x, y = wrms.pos.x, wrms.pos.y

local function App(args)
    local function Rec(args)
        local i = args.i
        local _rec = Text.key.toggle()

        return function()
            _rec{
                n = i+1, x = x[i][1], y = y.key,
                label = 'rec', edge = 'falling',
                state = { params:get('rec '..i) },
                action = function(v, t)
                    if t < 0.5 then params:set('rec '..i, v)
                    else params:delta('clear '..i, 1) end
                end
            }
        end
    end

    local function Trans(args)
        local i = args.i

        local blinktime = 0.2

        local _trans = to.pattern(mpat, '<< >> '..i, Text.key.trigger, function() 
            return {
                label = { '<<', '>>' },
                edge = 'falling',
                blinktime = function() return blinktime end, --not best practice
                n = { 2, 3 },
                y = y.key, x = { { x[i][1] }, { x[i][2] } },
                action = function(v, t, d, add, rem, l)
                    blinktime = sc.slew(i, t[add]) / 2

                    if #l == 2 then
                        params:set('dir '..i, params:get('dir '..i)==1 and 2 or 1)
                    else
                        params:delta('oct '..i, add==2 and 1 or -1)
                    end
                end
            }
        end)

        return function()
            _trans()
        end
    end

    local function Gfx()
        return function()
            if nest.screen.is_drawing() then
                wrms_gfx.draw()
                nest.screen.make_dirty() --redraw every frame while graphics are shown
            end
        end
    end
    local _gfx = Gfx()

    local alt = 0
    local page = 'v'
    local _alt = Key.momentary()
    local _tab = Text.enc.option()

    local page_names = { 'v', 'o', 'b', 's', '>', 'f' }

    local _pages = {}
    for i,page_name in ipairs(page_names) do
        _pages[page_name] = { main = {}, alt = {} }
    end
                
    do
        local _pg = _pages.v.main
        for i = 1,2 do
            local id = 'vol '..i
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = i + 1, x = x[i][1], y = y.enc, label = 'vol',
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        for i = 1,2 do
            local id = 'rec '..i
            _pg[id] = Rec{ i = i }
        end
    end
    do
        local _pg = _pages.v.alt
        do
            local id = 'ph 1'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = 2, x = x[1][1], y = y.enc, persistent = false, label = 'ph',
                    action = function(v)
                        softcut.position(2, sc.phase_abs[1] + v)
                    end
                }
            end)
        end
        do
            local id = 'sk 1'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    min = 0, max = 0.2, quant = 1/2000, step = 0,
                    n = 3, x = x[1][2], y = y.enc, label = 'sk',
                    state = {
                        reg.play:get_slice(1).skew,
                        function(v) 
                            reg.play:get_slice(1).skew = v 
                            reg.play:get_slice(1):update()
                        end
                    }
                }
            end)
        end
        for i = 1,2 do
            local id = 'res '..i
            _pg[id] = to.pattern(mpat, id, Text.key.trigger, function() 
                return {
                    label = 'res', n = i+1, x = x[i][1], y = y.key,
                    action = function(v) 
                        if v > 0 then
                            params:delta(id)
                        end
                    end
                }
            end)
        end
    end
    do
        local _pg = _pages.o.main
        for i = 1,2 do
            local id = 'old '..i
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = i + 1, x = x[i][1], y = y.enc, label = 'old',
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        for i = 1,2 do
            local id = 'rec '..i
            _pg[id] = Rec{ i = i }
        end
    end
    do
        local _pg = _pages.o.alt
        do
            local id = 'ph 2'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = 2, x = x[2][1], y = y.enc, label = 'ph',
                    action = function(v)
                        softcut.position(4, sc.phase_abs[2] + v*reg.play:get_length(4)/2)
                    end
                }
            end)
        end
        do
            local id = 'sk 2'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function()
                return {
                    min = 0, max = 3, quant = 1/100, step = 0,
                    n = 3, x = x[2][2], y = y.enc, label = 'sk',
                    state = {
                        reg.play:get_slice(3).skew,
                        function(v)
                            reg.play:get_slice(3).skew = v 
                            reg.play:get_slice(3):update()
                        end
                    }
                }
            end)
        end
        for i = 1,2 do
            local id = 'tap '..i
            _pg[id] = to.pattern(mpat, id, Text.key.trigger, function()
                return {
                    label = 'tap', n = i+1, x = x[i][1], y = y.key, selected = 1,
                    lvl = sc.punch_in[sc.buf[i]].tap_blink*11 + 4,
                    action = function(v, t, dt) 
                        if i == 1 then
                            if not sc.punch_in[sc.buf[1]].recorded then 
                                params:set('rec 1', 1, true)
                                sc.punch_in:manual(1) 
                            end
                        else
                            if not sc.punch_in[2].recorded then 
                                params:set('rec 2', 1, true)
                                sc.punch_in:manual(2) 
                            end
                        end

                        sc.punch_in:tap(i, dt) 
                    end
                }
            end)
        end
    end
    do
        local _pg = _pages.b.main
        do
            local id = 'bnd 1'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = 2, x = x[1][1], y = y.enc, label = 'bnd',
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        do
            local id = 'wgl'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function()
                return {
                    n = 3, x = x[1.5], y = y.enc, label = id,
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        _pg['trans'] = Trans{ i = 2 }
    end
    do
        local _pg = _pages.b.alt
        do
            local id = 'wgrt'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function()
                return {
                    n = 2, x = x[1][1], y = y.enc, label = id,
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        do
            local intervals = {
                "0th", "min 2nd", "maj 2nd",
                "min 3rd", "maj 3rd", "4th",
                "tritone", "5th", "min 6th",
                "maj 6th", "min 7th", "maj 7th"
            }
            local tp_fm = function(value) return 
                math.tointeger(value//12).." + "..intervals[value%12 + 1] 
            end

            local id = 'tp 2'
            local p = params:lookup_param(id)
            _pg[id] = to.pattern(mpat, id, Text.enc.number, function()
                return {
                    n = 3, x = x[1.5], y = y.enc, label = 'tp', inc = 1,
                    state = of.param(id), min = p.min, max = p.max,
                    formatter = tp_fm,
                }
            end)
        end
        _pg['trans'] = Trans{ i = 1 }
    end
    do
        local _pg = _pages.s.main
        do
            local id = 's 1'
            _pg[id] = to.pattern(mpat, id, Text.enc.number, function()
                return {
                    min = 0, max = math.huge, inc = 0.01, label = 's',
                    n = 2, x = x[1][1], y = y.enc,
                    state = {
                        reg.play:get_start(1),
                    },
                    action = function(v, delta)
                        reg.play:delta_startend(1, delta)
                    end
                }
            end)
        end
        do
            local id = 'l'
            _pg[id] = to.pattern(mpat, id, Text.enc.number, function()
                local len = reg.play:get_length(1)
                return {
                    min = 0, max = math.huge, inc = 0.01,
                    n = 3, x = x[1][2], y = y.enc, step = 1/100/100/100,
                    sens = sc.punch_in[sc.buf[1]].big and (
                        len <= 0.00019 and 1/100/100 or len <= 0.019 and 1/100 or 1 
                    ) or 1,
                    label = id,
                    state = { len },
                    action = function(v)
                        reg.play:set_length(1, v)
                        
                        if v > 0 and not sc.punch_in[sc.buf[1]].recorded then 
                            params:set('rec 1', 1, true)
                            sc.punch_in:manual(1) 
                        end
                        sc.punch_in:big(1, v)
                        sc.fade(1, v)
                        sc.punch_in:untap(1)
                    end
                }
            end)
        end
        _pg['trans'] = Trans{ i = 1 }
    end
    do
        local _pg = _pages.s.alt
        do
            local id = 's 2'
            _pg[id] = to.pattern(mpat, id, Text.enc.number, function()
                return {
                    min = 0, max = math.huge, inc = 0.01,
                    n = 2, x = x[2][1], y = y.enc, label = 's',
                    state = {
                        reg.play:get_start(2*2)
                    },
                    action = function(v)
                        reg.play:set_start(2*2, v)
                        sc.punch_in:untap(2)
                    end
                }
            end)
        end
        do
            local id = 'e'
            _pg[id] = to.pattern(mpat, id, Text.enc.number, function()
                return {
                    min = 0, max = math.huge, inc = 0.01,
                    n = 3, x = x[2][2], y = y.enc,
                    label = id,
                    state = {                    
                        reg.play:get_end(2*2)
                    },
                    action = function(v)
                        reg.play:set_end(2*2, v)
                        
                        if reg.play:get_length(2*2) > 0 and not sc.punch_in[2].recorded then 
                            params:set('rec 2', 1, true)
                            sc.punch_in:manual(2) 
                        end
                        sc.punch_in:untap(2)
                    end
                }
            end)
        end
        _pg['trans'] = Trans{ i = 2 }
    end
    do
        local _pg = _pages['>'].main
        do
            local id = '>'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = 2, x = x[1][1], y = y.enc, label = id,
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        do
            local id = '<'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function()
                return {
                    n = 3, x = x[2][1], y = y.enc, label = id,
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        for i = 1,2 do
            local id = 'buf '..i
            _pg[id] = to.pattern(mpat, id, Text.key.number, function()
                return {
                    label = 'buf', n = i+1, x = x[i][1], y = y.key,
                    formatter = function(v) return math.tointeger(v) end,
                    state = of.param(id),
                }
            end)
        end
    end
    do
        local _pg = _pages['>'].alt
        do
            local id = 'in pan 1'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = 2, x = x[1][1], y = y.enc, label = 'pan',
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        do
            local id = 'in pan 2'
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function()
                return {
                    n = 3, x = x[2][1], y = y.enc, label = 'pan',
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        do
            local id = 'old mode 1'
            _pg[id] = to.pattern(mpat, id, Text.key.option, function() 
                return {
                    n = 2, x = x[1][1], y = y.key, scroll_window = 1, wrap = true,
                    state = of.param(id), options = params:lookup_param(id).options,
                }
            end)
        end
        do
            local id = 'aliasing'
            _pg[id] = to.pattern(mpat, id, Text.key.toggle, function()
                return {
                    n = 3, x = x[2][1], y = y.key,
                    state = of.param(id), label = id,
                }
            end)
        end
    end
    for i = 1,2 do
        local _pg = _pages.f[({ 'main', 'alt' })[i]]
        do
            local id = 'f '..i
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function() 
                return {
                    n = 2, x = x[i][1], y = y.enc, label = 'f',
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        do
            local id = 'q '..i
            _pg[id] = to.pattern(mpat, id, Text.enc.control, function()
                return {
                    n = 3, x = x[i][2], y = y.enc, label = 'q',
                    state = of.param(id), controlspec = of.controlspec(id)
                }
            end)
        end
        do
            local id = 'filter type '..i
            _pg[id] = to.pattern(mpat, id, Text.key.option, function() 
                return {
                     n = { 2, 3 }, x = x[i][1], y = y.key,
                     state = of.param(id),
                     options = params:lookup_param(id).options,
                }
            end)
        end
    end

    return function(props)
        _gfx()

        _alt{ n = 1, action = function(v) alt = v end }
        _tab{
            n = 1, x = x.tab, y = y.tab, sens = 0.5, align = sh and 'right' or 'left', 
            margin = 2, flow = 'y', options = page_names,
            lvl = alt==1 and { 1, 15 } or { 4, 15 },
            action = function(v) page = page_names[v//1] end
        }

        for _, _ctl in pairs(_pages[page][alt==1 and 'alt' or 'main']) do _ctl() end
    end
end

return App
