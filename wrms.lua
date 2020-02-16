-- ~ wrms ~~
--
-- dual asyncronous 
-- time-wigglers / echo loopers
--
-- version 1.1.0 @andrew
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
-- dictates which wrm will be 
-- affected. 

wrms = include 'lib/wrms_ui'

---------------- pages - ordered pages of visual controls and actions (event callback functions) stored in a lua table --------------------------------------------------------

wrms.pages = {
  {
    label = "v",
    e2 = { -- wrm 1 volume
      worm = 1,
      label = "vol",
      value = 1.0,
      range = { 0.0, 2.0 },
      event = function(self, v)
        supercut.level(1, v)
        
        wrms.update_control(wrms.page_from_label(">").e2)
      end
    },
    e3 = { -- wrm 2 volume
      worm = 2,
      label = "vol",
      value = 1.0,
      range = { 0.0, 2.0 },
      event = function(self, v)
        supercut.level(2, v)
        
        wrms.update_control(wrms.page_from_label(">").e3)
      end
    },
    k2 = { -- wrm 2 record toggle
      worm = 1,
      label = "rec",
      value = 1,
      behavior = "toggle",
      event = function(self, v, t)
        if t < 0.5 then -- if short press toggle record
          supercut.rec(1, v)
        else -- else long press clears loop region
          supercut.rec(1, 0)
          
          self.value = 0
          
          supercut.buffer_clear_region(1)
        end
      end
    },
    k3 = { -- wrm 2 record toggle + loop punch-in
      worm = 2,
      label = "rec",
      value = 0,
      behavior = "toggle",
      event = function(self, v, t)
        if t < 0.5 then -- if short press
          if supercut.has_initial(2) then -- if inital loop has been recorded then toggle recording 
            supercut.rec(2, v) -- toggle recording
            
          elseif supercut.is_punch_in(2) then -- else if inital loop is being punched in, punch out
            supercut.region_end(2, supercut.position(2) - 0.1) -- set loop & region end to loop time
            supercut.loop_end(2, supercut.position(2) - 0.1)
            
            supercut.rec(2, 0) -- stop recording but keep playing
            
            supercut.has_initial(2, true) -- this is how we know we're done with the punch-in
            supercut.is_punch_in(2, false)
            
            wrms.wake(2) -- this is purely an animation setting - changes whether the worm is flat (asleep) or moving (awake)
            
          elseif v == 1 then -- else if no inital loop or punch-in start loop punch-in
            supercut.rec(2, 1) -- start recording & playing
            supercut.play(2, 1)
            
            supercut.region_end(2, supercut.home_region_end(2)) -- set loop & region end to max (stored in home_region_length)
            supercut.loop_end(2, supercut.home_region_end(2))
            -- supercut.loop_position(2, 0)
            
            supercut.is_punch_in(2, true) -- this is how we know we've started the punch in on next key press
          end
        else -- else (long press)
          supercut.rec(2, 0) -- stop recording & playing
          supercut.play(2, 0)
          
          self.value = 0
          
          supercut.region_end(2, supercut.home_region_end(2)) -- set loop & region end to max (stored in home_region_length)
          supercut.loop_end(2, supercut.home_region_end(2))
          supercut.loop_position(2, 0)
          
          supercut.is_punch_in(2, false)
          supercut.has_initial(2, false)
          
          supercut.buffer_clear_region(2) -- clear loop region
          
          wrms.sleep(2)
        end
      end
    }
  },
  {
    label = "o",
    e2 = { -- wrm 1 old volume (using rec_level)
      worm = 1,
      label = "old",
      value = 0.5,
      range = { 0.0, 1.0 },
      event = function(self, v)
        supercut.rec_level(1, v)
      end
    },
    e3 = { -- wrm 2 old volume (using pre_level)
      worm = 2,
      label = "old",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(self, v)
        supercut.pre_level(2,  v)
      end
    },
    k2 = {},
    k3 = {}
  },
  {
    label = "b",
    e2 = {
      worm = 1,
      label = "bnd",
      value = 1.0,
      range = { 1, 2.0 },
      event = function(self, v)
        supercut.rate2(1, 2^(v-1))
      end
    },
    e3 = {
      worm = "both",
      label = "wgl",
      value = 0.0,
      range = { 0.0, 100.0 },
      event = function(self, v) 
        local d = (util.linexp(0, 1, 0.01, 1, v) - 0.01) * 100
        wrms.lfo[1].depth = d
        wrms.lfo[2].depth = d
        
        supercut.wiggle(1, v)
        supercut.wiggle(2, v + 0.5)
      end
    },
    k2 = {
      worm = 2,
      label = "<<",
      value = 0,
      behavior = "momentary",
      event = function(self, v, t)
        local st = (1 + (math.random() * 0.5)) * t
        supercut.rate_slew_time(2, st)
        supercut.rate(2, supercut.rate(2) / 2)
      end
    },
    k3 = {
      worm = 2,
      label = ">>",
      value = 0,
      behavior = "momentary",
      event = function(self, v, t) 
        local st = (1 + (math.random() * 0.5)) * t
        supercut.rate_slew_time(2, st)
        supercut.rate(2, supercut.rate(2) * 2)
      end
    }
  },
  {
    label = "s", 
    e2 = { -- wrm 1 loop start point
      worm = 1,
      label = "s",
      value = 0.0,
      range = { 0.0, 1.0 },
      event = function(self, v) 
        self.range[2] = supercut.region_length(1) -- update control range
        
        supercut.loop_start(1,  v + supercut.region_start(1)) -- set start point
        
        wrms.update_control(wrms.page_from_label("s").e3)
      end
    },
    e3 = { -- wrm 1 loop length
      worm = 1,
      label = "l",
      value = 0.3,
      range = { 0, 1.0 },
      event = function(self, v) 
        self.range[2] = supercut.region_length(1) -- update control range
        
        supercut.loop_length(1,  v + 0.001) -- set length
      end
    },
    k2 = {
      worm = 1,
      label = "<<",
      value = 0,
      behavior = "momentary",
      event = function(self, v, t)
        local st = (1 + (math.random() * 0.5)) * t
        supercut.rate_slew_time(1, st)
        supercut.rate(1, supercut.rate(1) / 2)
      end
    },
    k3 = {
      worm = 1,
      label = ">>",
      value = 0,
      behavior = "momentary",
      event = function(self, v, t) 
        local st = (1 + (math.random() * 0.5)) * t
        supercut.rate_slew_time(1, st)
        supercut.rate(1, supercut.rate(1) * 2)
      end
    }
  },
  {
    label = ">",
    e2 = { -- feed wrm 1 to wrm 2
      worm = 1,
      label = ">",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(self, v)
        supercut.level_cut_cut(1, 2, v * supercut.level(1))
        supercut.feed(1, v)
      end
    },
    e3 = { -- feed wrm 2 to wrm 1
      worm = 2,
      label = "<",
      value = 0.0,
      range = { 0.0, 1.0 },
      event = function(self, v) 
        supercut.level_cut_cut(2, 1, v * supercut.level(2))
        supercut.feed(2, v)
      end
    },
    k2 = {
      worm = 1,
      label = "pp",
      value = 0,
      behavior = "toggle",
      event = function(self, v, t) 
        if v == 1 then -- if ping-pong is enabled, route across voices
          supercut.level_cut_cut(1, 1, 1, 1, 2)
          supercut.level_cut_cut(1, 1, 1, 2, 1)
          supercut.level_cut_cut(1, 1, 0, 1, 1)
          supercut.level_cut_cut(1, 1, 0, 2, 2)
        else -- else (ping-pong is not enabled) route voice to voice
          supercut.level_cut_cut(1, 1, 0, 1, 2)
          supercut.level_cut_cut(1, 1, 0, 2, 1)
          supercut.level_cut_cut(1, 1, 1, 1, 1)
          supercut.level_cut_cut(1, 1, 1, 2, 2)
        end
      end
    },
    k3 = { -- toggle share buffer region
      worm = "both",
      label = "share",
      value = 0,
      behavior = "toggle",
      event = function(self, v, t)
        if v == 1 then -- if sharing
          supercut.steal_voice_region(1, 2) -- set wrm 1 region points to wrm 2 region points
        else -- else (not sharing)
          supercut.steal_voice_home_region(1, 1) -- set wrm 1 region points to wrm1 default
        end
        
        wrms.update_control(wrms.page_from_label("s").e2) -- update loop point controls, just for kicks !
        wrms.update_control(wrms.page_from_label("s").e3)
      end
    }
  }
}
-- ,
-- {
  --   label = "f",
  --   e2 = { -- wrm 1 filter cutoff
  --     worm = 1,
  --     label = "f",
  --     value = 1.0,
  --     range = { 0.0, 1.0 },
  --     event = function(self, v) 
  --       softcut.post_filter_fc(1, util.linexp(0, 1, 1, 12000, v))
  --       softcut.post_filter_fc(2, util.linexp(0, 1, 1, 12000, v))
  --     end
  --   },
  --   e3 = { -- wrm 1 filter resonance
  --     worm = 1,
  --     label = "q",
  --     value = 0.3,
  --     range = { 0.0, 1.0 },
  --     event = function(self, v) 
  --       softcut.post_filter_rq(1,1 - v)
  --       softcut.post_filter_rq(2,1 - v)
  --     end
  --   },
  --   k2 = { -- wrm 1 filter on/off
  --     worm = 1,
  --     label = "filt",
  --     value = 0,
  --     behavior = "toggle",
  --     event = function(self, v, t) 
  --       if v == 0 then
  --         softcut.post_filter_dry(1, 1)
  --         softcut.post_filter_dry(2, 1)
  --         softcut.post_filter_lp(1, 0)
  --         softcut.post_filter_lp(2, 0)
  --         softcut.post_filter_bp(1, 0)
  --         softcut.post_filter_bp(2, 0)
  --         softcut.post_filter_hp(1, 0)
  --         softcut.post_filter_hp(2, 0)
  --       else
  --         wrms.pages[5].k3:event(wrms.pages[5].k3.value)
  --       end
  --     end
  --   },
  --   k3 = { -- wrm 1 filter type
  --     worm = 1,
  --     label = { "lp", "bp", "hp"  },
  --     value = 1,
  --     behavior = "enum",
  --     event = function(self, v, t)
  --       if wrms.pages[5].k2.value == 1 then
  --         softcut.post_filter_dry(1, 0)
  --         softcut.post_filter_dry(2, 0)
  --         softcut.post_filter_lp(1, 0)
  --         softcut.post_filter_lp(2, 0)
  --         softcut.post_filter_bp(1, 0)
  --         softcut.post_filter_bp(2, 0)
  --         softcut.post_filter_hp(1, 0)
  --         softcut.post_filter_hp(2, 0)
          
  --         if v == 1 then -- v is lowpass
  --           softcut.post_filter_lp(1, 1)
  --           softcut.post_filter_lp(2, 1)
  --         elseif v == 2 then -- v is bandpass
  --           softcut.post_filter_bp(1, 1)
  --           softcut.post_filter_bp(2, 1)
  --         elseif v == 3 then -- v is hightpass
  --           softcut.post_filter_hp(1, 1)
  --           softcut.post_filter_hp(2, 1)
  --         end
  --       end
  --     end
  --   }
  -- },
wrms.pages[2].k2 = wrms.pages[1].k2
wrms.pages[2].k3 = wrms.pages[1].k3

-------------------------------------------- global callbacks - feel free to redefine  ------------------------------------------------------------

function init()
  --wigl lfo setup
  wrms.lfo.init()
  wrms.lfo[1].freq = 0.5 -- keep the lfos out of phase
  wrms.lfo[2].freq = 0.4
  wrms.lfo.process = function() -- called on each lfo update
    local rate = supercut.rate(1) + wrms.lfo[1].delta -- set wrm 1 rate = change in lfo1 each time it updates
    supercut.rate(1, rate)
    
    local rate = supercut.rate(2) + wrms.lfo[2].delta -- set wrm 2 rate = change in lfo2 each time it updates
    supercut.rate(2, rate)
  end
  
  -- supercut (softcut) initial settings
  supercut.buffer_clear()
  
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  
  supercut.init(1, "stereo")
  supercut.init(2, "stereo")
  
  supercut.play(1, 1)
  supercut.pre_level(1, 0.0)
  supercut.rate_slew_time(1, 0.2)
  supercut.home_region_length(1, 5)
  
  supercut.rec_level(2, 1.0)
  supercut.rate(2, 1)
  
  supercut.phase_quant(1, wrms.phase_quant)
  supercut.phase_quant(2, wrms.phase_quant)
  
  supercut.has_initial(1, true)
  
  for i = 1,2 do
    supercut.enable(i, 1)
    supercut.loop(i, 1)
    supercut.fade_time(i, 0.1)
    supercut.position(i, 0)
    
    supercut.level_input_cut(1, i, 1.0, 1)
    supercut.level_input_cut(2, i, 1.0, 2)
    
    supercut.pan(i, 0)
    
    supercut.level_slew_time(i, 0.1)
    supercut.recpre_slew_time(i, 0.01)
  end
  
  wrms.init()
  
  redraw()
end

function enc(n, delta)
  wrms.enc(n, delta)
  
  redraw()
end

function key(n,z)
  wrms.key(n,z)
  
  redraw()
end

function redraw()
  wrms.redraw()
end

metro.init(function() redraw() end,  1/100):start()