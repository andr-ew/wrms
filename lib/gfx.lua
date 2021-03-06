--screen graphics
local mar, mul = 2, 29
local gfx = {
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
        draw = function()
        end,
        update = function()
            wrms_.gfx:update()
        end
    }   
}

return gfx
