--  _       ___________ ___  _____ 
-- | | /| / / ___/ __ `__ \/ ___/  
-- | |/ |/ / /  / / / / / (__  )   
-- |__/|__/_/  /_/ /_/ /_/____/    
--
-- dual stereo time-wigglers
-- / echo loopers
--
-- version 2.0.0 @andrew
-- https://norns.community/
-- authors/andrew/wrms
--
-- two time-travel wrms for 
-- loops, delays, & everything 
-- in-between
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
-- the first time you meet the 
-- wrms, wrm1 (on the left) will 
-- be set up as a delay & wrm 2 
-- (on the right) will be 
-- configured as a looper pedal. 
-- feed the wrms some audio to 
-- begin exploring ! tap K3 once 
-- to begin recording a loop, 
-- then again to begin playback.
--
-- for documentation of each 
-- control, head to:
-- https://norns.community/
-- authors/andrew/wrms

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

--the default wrms template
wrms_ = nest_ {
    gfx = _screen {
        redraw = wrms.gfx.draw
    },
    tab = _txt.enc.option {
        n = 1, x = x.tab, y = y.tab, sens = 0.5, align = sh and 'right' or 'left', margin = 2,
        flow = 'y', options = { 'v', 'o', 'b', 's', '>', 'f' },
        lvl = function() return wrms_.alt.v==1 and { 1, 15 } or { 4, 15 } end
    },
    alt = _key.momentary { n = 1 },
    pages = nest_ {
        v = nest_ {
            main = nest_ {
                vol = nest_(2):each(function(i)
                    return _txt.enc.control {
                        n = i + 1, x = x[i][1], y = y.enc, label = 'vol'
                    } :param('vol '..i)
                end),
                rec = nest_(2):each(function(i) return _rec(i) end)
            }, 
            alt = nest_ {
                ph = _txt.enc.control {
                    n = 2, x = x[1][1], y = y.enc, persistent = false,
                    action = function(s, v)
                        softcut.position(2, sc.phase_abs[1] + v)
                    end
                },
                sk = _txt.enc.control {
                    min = 0, max = 0.2, quant = 1/2000, step = 0,
                    n = 3, x = x[1][2], y = y.enc,
                    value = function(s, v) return reg.play:get_slice(1).skew end,
                    action = function(s, v) 
                        reg.play:get_slice(1).skew = v 
                        reg.play:get_slice(1):update()
                    end
                },
                res = nest_(2):each(function(i)
                    return _txt.key.trigger {
                        label = 'res', n = i+1, x = x[i][1], y = y.key
                    } :param('res '..i)
                end)
            }
        },
        o = nest_ {
            main = nest_ {
                old = nest_(2):each(function(i)
                    return _txt.enc.control {
                        n = i + 1, x = x[i][1], y = y.enc, label = 'old'
                    } :param('old '..i)
                end),
                rec = nest_(2):each(function(i) return _rec(i) end)
            }, 
            alt = nest_ {
                ph = _txt.enc.control {
                    n = 2, x = x[2][1], y = y.enc, persistent = false,
                    action = function(s, v)
                        softcut.position(4, sc.phase_abs[2] + v*reg.play:get_length(4)/2)
                    end
                },
                sk = _txt.enc.control {
                    min = 0, max = 3, quant = 1/100, step = 0,
                    n = 3, x = x[2][2], y = y.enc,
                    value = function(s, v) return reg.play:get_slice(3).skew end,
                    action = function(s, v)
                        reg.play:get_slice(3).skew = v 
                        reg.play:get_slice(3):update()
                    end
                },
                tap = nest_(2):each(function(i)
                    return _txt.key.trigger {
                        label = 'tap', n = i+1, x = x[i][1], y = y.key, selected = 1,
                        lvl = function() 
                            return sc.punch_in[sc.buf[i]].tap_blink*11 + 4 
                        end,
                        action = function(s, v, t, dt) 
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
            }
        },
        b = nest_ {
            main = nest_ {
                bnd = _txt.enc.control {
                    n = 2, x = x[1][1], y = y.enc, label = 'bnd'
                } :param('bnd 1'),
                wgl = _txt.enc.control {
                    n = 3, x = x[1.5], y = y.enc
                } :param('wgl'),
                trans = _trans(2, {})
            }, 
            alt = nest_ {
                wgrt = _txt.enc.control {
                    n = 2, x = x[1][1], y = y.enc
                } :param('wgrt'),
                tp = _txt.enc.number {
                    n = 3, x = x[1.5], y = y.enc
                } :param('tp 2'),
                trans = _trans(1, {})
            }
        },
        s = nest_ {
            main = nest_ {
                s = _txt.enc.number {
                    min = 0, max = math.huge, inc = 0.01,
                    n = 2, x = x[1][1], y = y.enc,
                    value = function() return reg.play:get_start(1) end,
                    action = function(s, v, delta)
                        reg.play:delta_startend(1, delta)
                    end
                },
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
                trans = _trans(1, {})
            }, 
            alt = nest_ {
                s = _txt.enc.number {
                    min = 0, max = math.huge, inc = 0.01,
                    n = 2, x = x[2][1], y = y.enc,
                    value = function() return reg.play:get_start(2*2) end,
                    action = function(s, v)
                        reg.play:set_start(2*2, v)
                        sc.punch_in:untap(2)
                    end
                },
                e = _txt.enc.number {
                    min = 0, max = math.huge, inc = 0.01,
                    n = 3, x = x[2][2], y = y.enc,
                    value = function() return reg.play:get_end(2*2) end,
                    action = function(s, v)
                        reg.play:set_end(2*2, v)
                        
                        if reg.play:get_length(2*2) > 0 and not sc.punch_in[2].recorded then 
                            params:set('rec 2', 1, true)
                            sc.punch_in:manual(2) 
                        end
                        sc.punch_in:untap(2)
                    end
                },
                trans = _trans(2, {})
            }
        },
        ['>'] = nest_ {
            main = nest_ {
                ['>'] = _txt.enc.control {
                    n = 2, x = x[1][1], y = y.enc,
                } :param('>'),
                ['<'] = _txt.enc.control {
                    n = 3, x = x[2][1], y = y.enc,
                } :param('<'),
                buf = nest_(2):each(function(i)
                    return _txt.key.number {
                        label = 'buf', n = i+1, x = x[i][1], y = y.key,
                        formatter = function(s, v) return math.tointeger(v) end
                    } :param('buf '..i)
                end)
            }, 
            alt = nest_ {
                pan1 = _txt.enc.control {
                    n = 2, x = x[1][1], y = y.enc, label = 'pan'
                } :param('in pan 1'),
                pan2 = _txt.enc.control {
                    n = 3, x = x[2][1], y = y.enc, label = 'pan'
                } :param('in pan 2'),
                mode = _txt.key.option {
                    n = 2, x = x[1][1], y = y.key, scroll_window = 1, wrap = true,
                } :param('old mode 1'),
                aliasing = _txt.key.toggle {
                    n = 3, x = x[2][1], y = y.key, 
                } :param('aliasing')
            }
        },
        f = nest_ {
            main = nest_ {
                f = _txt.enc.control {
                    n = 2, x = x[1][1], y = y.enc, label = 'f'
                } :param('f 1'),
                q = _txt.enc.control {
                    n = 3, x = x[1][2], y = y.enc, label = 'q'
                } :param('q 1'),
                type = _txt.key.option {
                    n = { 2, 3 }, x = x[1][1], y = y.key,
                } :param('filter type '..1)
            },
            alt = nest_ {
                f = _txt.enc.control {
                    n = 2, x = x[2][1], y = y.enc, label = 'f'
                } :param('f 2'),
                q = _txt.enc.control {
                    n = 3, x = x[2][2], y = y.enc, label = 'q'
                } :param('q 2'),
                type = _txt.key.option {
                    n = { 2, 3 }, x = x[2][1], y = y.key,
                } :param('filter type '..2)

            }
        }
    } :each(function(k, v)
        v.enabled = function(s) return wrms_.tab.options[wrms_.tab.v//1] == k end
        if v.main then
            v.main.enabled = function() return wrms_.alt.v == 0 end
            v.alt.enabled = function() return wrms_.alt.v == 1 end
        end
    end)
} :connect { screen = screen, enc = enc, key = key } 

function init()
    wrms.setup()
    params:read()
    wrms.load()

    params:bang()
    wrms_:init()
end

function cleanup()
    wrms.save()
    params:write()
end
