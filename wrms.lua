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

wrdn = include 'wrms/lib/warden/warden'

-- voice stereo pair setter helper
stereo = function(command, pair, ...)
    local off = (pair - 1) * 2
    for i = 1, 2 do
        softcut[command](off + i, ...)
    end
end

-- helper function tables
lvlmx = {
    {
        vol = 1, send = 1,
        update = function(s)
            softcut.level_cut_cut(1, 3, s.send * s.vol)
            softcut.level_cut_cut(2, 4, s.send * s.vol)
        end
    }, {
        vol = 1, send = 0,
        update = function(s)
            softcut.level_cut_cut(3, 1, s.send * s.vol)
            softcut.level_cut_cut(4, 2, s.send * s.vol)
        end
    },
    update = function(s, n)
        stereo('level', n, s[n].vol)
        s[n]:update()
    end
}

oldmx = {
    { old = 0.5, mode = 'fb' },
    { old = 1, mode = 'pre' },
    update = function(s, n)
        local off = n == 1 and 0 or 2
        if mode == 'pre' then
            stereo('pre_level', n, s.old)
            softcut.level_cut_cut(1 + off, 2 + off, 0)
            softcut.level_cut_cut(2 + off, 1 + off, 0)
        else
            stereo('pre_level', n, 0)
            softcut.level_cut_cut(1 + off, 2 + off, s.old)
            softcut.level_cut_cut(2 + off, 1 + off, s.old)
        end
    end
}

mod = {
}

ratemx = {
    { oct = 1, bnd = 1, mod = 0, dir = 1 },
    { oct = 1, bnd = 1, mod = 0, dir = -1 },
    update = function(s, n)
        stereo('rate', n, s.oct * 2^(s.bnd - 1) * 2^mod * dir)
    end
}

slew = function(n, t)
    local st = (2 + (math.random() * 0.5)) * t 
    stereo('rate_slew_time', n, st)
    return st
end

--params

--screen interface
--todo: x, y, n
rec = nest_(2):each(function(i)
    return _txt.key.toggle {
        label = 'rec',
        action = function(s, v)
            stereo('rec_level', i, v)
        end
    }
end)
rec[1].v = 1

wrms_ = nest_ {
    pages = nest_ {
        -- todo: link these to params
        v = nest_ {
            vol = nest_(2):each(function(i)
                return _txt.enc.control {
                    label = 'vol',
                    v = 1, max = 2,
                    action = function(s, v)
                        lvlmx[i].vol = v
                        lvlmx:update(i)
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
                        oldmx[i].old = v
                        oldmx:update(i)
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
                    ratemx[1].bnd = v
                    ratemx:update(1)
                end
            },
            wgl = _txt.enc.control {
                min = 1, max = 100, quantum = 0.01/100,
                action = function(s, v) mod.amount = v end
            },
            oct = 1,
            dir = 1,
            slew = 0,
            trans = _txt.key.trigger {
                label = { '<<', '>>' },
                edge = 0,
                --set blink time to slew time
                action = function(s, v, t, d, add, rem, l)
                    slew(1, t)

                    if #l == 2 then
                        s.p.dir = s.p.dir * -1
                        ratemx[1].dir = s.p.dir
                        ratemx:update()
                    else
                        s.p.oct = (add == 2) and (s.p.oct * 2) or (s.p.oct / 2)
                        ratemx[2].oct = s.p.oct
                        ratemx:update(2)
                    end
                end
            }
        }
    }
}

