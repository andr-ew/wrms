--  _       ___________ ___  _____ 
-- | | /| / / ___/ __ `__ \/ ___/
-- | |/ |/ / /  / / / / / (__  )  
-- |__/|__/_/  /_/ /_/ /_/____/ 
--
-- dual asyncronous 
-- time-wigglers / echo loopers
--
-- version 1.0.1 @andrew
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

wrms = include 'wrms/lib/wrms_ui'

--[[
                                           
                                                                        :                           :                                       
                                                                                                                                            
                                                                  :               ==::==+:+?:+                                              
                                                               :            ~,+.?,.~,:~.?I?I+?I+?=+~        ~=                              
                                                         =  :           ~+.~:.~.,~.,:.:.,..~.:=,I+I++=~,       ~                            
                                                         :         = .=,..=.,~,~?,=+.=+~=+=+~.:.~.~?+:++==                                  
                                                                ~  .~,.::.+=+I,?:+,:=+?+?,~+???=:...,~=.++                                  
                                                  :             :..=.,=~?+~~+?++=++++++~==?++=~=,??,.:~=:+~                                 
                                              :              ++.,:.,+?+~~++?~+~:==,=,=:==+=.++++?+==~....+  ,                               
                                                          ?,,.,::,I+=.+?:+~+,=:~,~.:.,,::::~,==+=:~~~====                                   
                                          =            ??+.~.,~~??+?+++~+=:=,:.....          .:..,.,,~~~:                                   
                                         :         ????+,~.,~??++?+=+:==~~,,..                    .....=                                    
                                         .      I???++::..~???+++++:=,~...:                                                                 
                                             =:+++?~,..+~+??=++:+~=::..=                                                                    
                                          .~I?=I+.,.,:~=?=~++:=:=~~..                                                                       
                                         II?+,?::.,,,?==~+=:=:~:,.                                                                          
                                      I~~+?+~?+?=..+=,==,==:~:,.                                                                            
                                     ?+I?:?+==:=,~..~:.=:.~.,.                                  _       ___________ ___  _____                                             
                                     I==:.=??+~I:??=~,.:,...             .....:.,.             | | /| / / ___/ __ `__ \/ ___/                                           
                                    ?~?~I~=+~:++=:7,~,?=,,                    ,                | |/ |/ / /  / / / / / (__  )                                              
                                    ==I+?:+?~~I,:+==~77I?~++++.               .                |__/|__/_/  /_/ /_/ /_/____/                                                 
                                    :,=?+I=?~I=~I~?~+~:~???~??+:+             .                                                             
                                     ,~:?~++?=?I~I+I++::::~~==,,:             .                                                             
                                     ::~~~:I=+I=??I=I?=::~,~=~.~                                                                            
                                      :~~~?=+++~?=+II=~~=:=??+:                                                                             
                                      ? .:=~~,=.~,,=+?===?=+??~~=                                                                           
                                      =  ,+,~=++==..+:=~===???~7=                                                                           
                                       +,= ?~+:~==+=~~:=~=~???=~,=~                                                                         
                                       ?,  I ?.~I:~=++,==~?++=???===                                                                        
                                         ?,=.=.~,,:~=?.+++=~=~==+??+=:~ =                                                                   
                                           +?.+ =::,=+?,~,I=~===+:=+??++.== :    ~  ~                                                       
                                             :=~~~??+I+?II++?=+~++==~~=+=  =:~      :  :  =                                                 
                                                 =+=II:=?I.I.~+.I~===+=====+= ++~+, =                                                       
                                                      ,.~+?I+.?.??+++=+=~+~======+?=~=:?,~  =    =~. ,                                      
                                                       .:=?+??III.:?==I~?++++~:=:=~~=+= +::?+ ~   ~   .   ~                                 
                                                        ~,:~?++??II.?I+=??II+++?=?~+~:~~===+=,. =?          ~                               
                                                          .,:.?:??????I+I7,:~I++I~=++==+=,~=++~=. ==~ ~      ,                              
                                                            =:::~++++????II?II~?~=.~I~?~?:+::,,= ==.  ~        ~                            
                                                              =..::..+?++?????I=?~I~+=,?=+~?=+::,~=~,=.=~.~   = ~                           
                                                                 =,.:~,,=?:~++?+??????.~=.=?~=?:+:::++.~~==~I ~                             
                                                                    =.,:~.:=+I==+++?+?==+==.==+=?+=:~:~+=??=~?,:                            
                                                                        ~...,:,=??I==+++++?,====:+=:::,++,:=,II=                            
                                                                            ~=.~.:,=+++==++?++:=++~:++=~~=+:~=+,                            
                                                                      =:,,,,,,,,,=..:,~?=~~++,~=,~=:+~=~:,=+,:~~.                           
                                                             =:::~:+ ?+====,.,,,,,,,~...~+=~~+=+,.~==~,==~~:==~.++?                         
                                                         =::+=?++==~=~==~+=+=~~:,,,,,,,.~.~+,~~~++++:=?~:+::+=,:~~:                         
                                                   =:=:=+?=?==~::~=~=~?:??+==?,.+=:...,,,.:,:++~~~=:=.=~~+::::,=:  ~?                       
                                                :~ +?==?===+:~+?+I+?~.~,:+++~+==?+++++,,....:.=??:===::=:+~:~,:~=:,=:                       
                                              == ==+=:=:~=+?=?:?:+~::?++++======~~~~~~~:+,.:,:,,::::~:~:==:~=~,,+~=                         
                                           =   ?:+?~=++II=.==:?:+,+++=====~:::::::.??+=:~=..,,,:==?=~~~=+~:=~:~~:~~                         
                                         :   =.==~~??+++.~::+?+=+~~~~=+I~?.~::..,:......,,,,,...~.+?,::~:~:~~~=,,==:                        
                                         :  ~~+:~=?+?+?:==+===~~~===~:,........,,,,,:~,..,..,:,,,:.=:~~~~~.:~,~~:::,                        
                                           .=:,~~~~,.~?+~=+~~:+~:.....,,::~==,.,.,...,,,,,,.,:=?++:,=~,::,:~:=~:~:~~                        
                                     =    ,+=,~+=+~~~=++~~~,~....,::=       ,,,.,,....::,.,~+??++=~,:,=~~~~:~:~=~~===                       
                                         =+=:~?++.:?=+==::~:.,,~           :,,...:+==:..::??++::,,,,:~+?,:=,:~,::~=,                        
                                          +?:+II=.:++=~=:.~,               ,=???+~~,,.:.++==,,,,,.,,,,~+::~:.::::=~.                        
                                        .+~?:+=+=~:?+=~~:,:?,              ~~+?~:=?~,~===~,.,,.,,:    ~++,,::~~:~.                          
                                        =?+:~+==?=??+~?~~?:, :+            :::~,.?=::~~:,,.,,,~        .~  =,,:                             
                                          ~~?:~+~+==:~~:.:., :  .  I~,   I=,.=::+?=?:,:,,,,  ==        ,~,~?~                               
                                         ++,:~II~::+==~+=?.~I,   .=   , ~~::~,,:?+:,~::,:    ~         ~.  ::                               
                                   ,, ,    .+.:===+~,?++=?+=.:~~I., ,,I.,:+:++~:I?~::,:::    :          ,+,.+                               
                                           =I,~I?:=+:++=+~:+=:+ :=:?~+?=~:,???=~::=~:::,,   ~                                               
                                    =       +~:.:=~+~:::?+~~+ ?+=,=:+??+:=~,? +~~:,:~:~,    =                                               
                                      =      .~::~I,.=+?+~+==+====~=~??===~~~+==~~:,.:+  =                                                  
                                              +I+:::::=~++,~:+===~+:+~==+~:==~~=:=~:.+                                                      
                                              , ,:?=~:=?7,,~~=~?==,?,:==+=~+:.,:::?.~  +  ~                                                 
                                                  ?+~:+::.=:,:?=?I,,~~:~?=+,.,,:=?,   ~                                                     
                                         ,=         :=,:III=:~?I:::=:,::=I,.,+++     =  ~                                                   
                                                       = =,?=+,,,?~I~+:,~....~                                                              
                                                             ,    ::.:=                                                                     
                                                                                 +                                                          
                                                 =                                                                                          


! ! ! welcome ! ! !

i'm glad u decided to visit the guts :)

i put lots here 4 u to read here & 
more importantly: help you to make your own wrms mods

a looper is very personal, and i've structured wrms so it can be modified + extended to suit your own needs

it turns out that wrms is both a SCRIPT and a LIBRARY, so modifying wrms, or including it in a project of your choosing is as easy as:
wrms = include "wrms/wrms"

the first step to creating a mod will be familiarizing yourself with the code contained here. it is very redefinable !
then, you can check out some of the mods andrew shared @ https://llllllll.co/t/wrms to get an idea how the modding process works
"filt" is particularly simple !

wrms uses the supercut lib to interact with softcut.
before reading on, i'd recommend reading up on that over here -> https://llllllll.co/t/supercut-lib

]]--

-- under here are pages: ordered sections of visual controls and functions (https://www.lua.org/pil/5.html) stored in a lua table (https://www.lua.org/pil/11.html)

wrms.pages = {
  {
    label = "v", -- page label as it appears on the right
    e2 = { -- wrm 1 volume
      worm = 1, -- accepts 1, 2 or "both", essentially it just detirmines where the control appears on-screen
      label = "vol", -- label for the control
      value = 1.0, -- initally the default value, but it also stores the live value for retrieval
      range = { 0.0, 2.0 }, -- the range of the value
      event = function(self, v) -- event() is called every time the value is changed, its job is to communicate with supercut and keep other values up-to-date
        supercut.level(1, v) -- here, we're just setting voice 1 level to the latest value v from function args
        
        wrms.update_control(wrms.page_from_label(">").e2) -- and we're updating e2 on page ">"" since it references vol
      end
    },
    e3 = { -- wrm 2 volume (same deal as vol 1)
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
      behavior = "toggle", -- keys can have 3 behaviors, "toggle", "momentary", and "enum". rec is a on/off toggle control.
      event = function(self, v, t)
        if t < 0.5 then -- if short press toggle record
          supercut.rec(1, v)
        else -- else long press clears loop region
          supercut.rec(1, 0)
          
          self.value = 0 -- self is US, the control ! here we turn our value off
          
          supercut.buffer_clear_region(1) -- just send our voice # to clear ourself
        end
      end
    },
    k3 = { -- wrm 2 record toggle (loop pedal style) + loop punch-in
      worm = 2,
      label = "rec",
      value = 0,
      behavior = "toggle",
      event = function(self, v, t)
        if t < 0.5 then -- if short press
          if v == 1 then -- else if no inital loop or punch-in has happened yet, start loop punch-in
            supercut.rec(2, 1) -- start recording & playing
            supercut.play(2, 1)
            
            supercut.region_length(2, supercut.home_region_length(2)) -- set loop & region length to max (stored in home_region_length)
            supercut.loop_length(2, supercut.home_region_length(2))
            
            supercut.is_punch_in(2, true) -- this is how we know we've started the punch in on next key press
            
          elseif supercut.is_punch_in(2) then -- else if inital loop is being punched in, it's time to punch out
            supercut.region_length(2, supercut.region_position(2) - 0.1) -- set loop & region length to loop's position in the region
            supercut.loop_length(2, supercut.region_position(2) - 0.1)
            
            supercut.rec(2, 0) -- stop recording but keep playing
            
            supercut.has_initial(2, true) -- this is how we know we're done with the whole punch-in process
            supercut.is_punch_in(2, false)
            
            wrms.wake(2) -- this is purely an animation setting - changes whether the worm is flat (asleep) or moving (awake)
            
          elseif supercut.has_initial(2) then -- if inital loop has been recorded then toggle recording 
            supercut.rec(2, v)
            
          end
        else -- else (long press) we're gonna clear the buffer region
          supercut.rec(2, 0) -- stop recording & playing
          supercut.play(2, 0)
          
          self.value = 0
          
          supercut.region_length(2, supercut.home_region_length(2)) -- set loop & region length to max (stored in home_region_length)
          supercut.loop_length(2, supercut.home_region_length(2))
          supercut.loop_position(2, 0)
          
          supercut.is_punch_in(2, false) -- reset those vals from above
          supercut.has_initial(2, false)
          
          supercut.buffer_clear_region(2) -- clear loop region
          
          wrms.sleep(2)
        end
      end
    }
  },
  {
    label = "o",
    e2 = { -- wrm 1 old volume (using rec_level) (wrm 1 is fed back into itself)
      worm = 1,
      label = "old",
      value = 0.5,
      range = { 0.0, 1.0 },
      event = function(self, v)
        supercut.rec_level(1, v)
      end
    },
    e3 = { -- wrm 2 old volume (using pre_level (/overdub))
      worm = 2,
      label = "old",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(self, v)
        supercut.pre_level(2,  v)
      end
    },
    k2 = {}, -- way at the bottom we're duplicating the rec controls from pg 1 and putting them here
    k3 = {}
  },
  {
    label = "b", 
    e2 = { -- continutious control btw rate = 1x and rate = 2x for wrm 1
      worm = 1,
      label = "bnd",
      value = 1.0,
      range = { 1, 2.0 },
      event = function(self, v)
        supercut.rate2(1, 2^(v-1)) -- uses a handy small feature in supercut - there are 4 independent rate controls which are multiplied together
      end
    },
    e3 = { -- wigl controls the depth of modulation for 2 lfo instances routed to each wrm rate. it also updates a supercut param referenced by the animation system
      worm = "both",
      label = "wgl",
      value = 0.0,
      range = { 0.0, 100.0 },
      event = function(self, v) 
        local d = (util.linexp(0, 1, 0.01, 1, v) - 0.01) * 100 -- little bit of exponential scaling fun
        wrms.lfo[1].depth = d
        wrms.lfo[2].depth = d
        
        supercut.wiggle(1, v)
        supercut.wiggle(2, v + 0.5)
      end
    },
    k2 = { -- << and >> halve and double rate for wrm 2
      worm = 2,
      label = "<<",
      value = 0,
      behavior = "momentary", -- momentary, so the value doesn't change - something just happens once on every press
      event = function(self, v, t)
        local st = (1 + (math.random() * 0.5)) * t -- t == time a key is held before release (it comes from our function args). it goes thru some random scaling here
        supercut.rate_slew_time(2, st) -- then modifies the slew time to create a glide effect
        supercut.rate(2, supercut.rate(2) / 2)
      end
    },
    k3 = { -- same stuff
      worm = 2,
      label = ">>",
      value = 0,
      behavior = "momentary",
      event = function(self, v, t) 
        local st = (1 + (math.random() * 0.5)) * t
        supercut.rate_slew_time(2, st)
        supercut.rate(2, supercut.rate(2) * 2)
      end
    },
    k2_k3 = { -- when k2_k3 is provided after a pair of momentary, holding both keys and releasing triggers an additional momentary event
      behavior = "momentary",
      event = function(self, v, t) 
        local st = (1 + (math.random() * 0.5)) * t
        supercut.rate_slew_time(2, st)
        supercut.rate(2, supercut.rate(2) * -1) -- in this case we're reversing playback
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
        
        supercut.loop_start(1,  v) -- set start point
        
        wrms.update_control(wrms.page_from_label("s").e3) -- update loop length when start changes
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
    k2 = { -- rate controls for for wrm 1, same deal really
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
    },
    k2_k3 = {
      behavior = "momentary",
      event = function(self, v, t) 
        local st = (1 + (math.random() * 0.5)) * t
        supercut.rate_slew_time(1, st)
        supercut.rate(1, supercut.rate(1) * -1)
      end
    }
  },
  {
    label = ">", -- > and < use the level_cut_cut function to send audio between wrms
    e2 = { -- feed wrm 1 to wrm 2
      worm = 1,
      label = ">",
      value = 1.0,
      range = { 0.0, 1.0 },
      event = function(self, v)
        supercut.level_cut_cut(1, 2, v * supercut.level(1)) -- we're setting the level = feed val * level val
        supercut.feed(1, v) -- this is a seprate control just for the animation
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
    k2 = { -- optional wrm 1 ping-pong routing
      worm = 1,
      label = { "stereo", "pp" },
      value = 1,
      behavior = "enum",
      event = function(self, v, t) 
        if v == 2 then -- if ping-pong, route across voices
          supercut.level_cut_cut(1, 1, 1, 1, 2)
          supercut.level_cut_cut(1, 1, 1, 2, 1)
          supercut.level_cut_cut(1, 1, 0, 1, 1)
          supercut.level_cut_cut(1, 1, 0, 2, 2)
        elseif v == 1 then -- if stereo, route voice to voice
          supercut.level_cut_cut(1, 1, 0, 1, 2)
          supercut.level_cut_cut(1, 1, 0, 2, 1)
          supercut.level_cut_cut(1, 1, 1, 1, 1)
          supercut.level_cut_cut(1, 1, 1, 2, 2)
        end
      end
    },
    k3 = { -- toggle shared buffer region
      worm = "both",
      label = { "normal", "share" },
      value = 1,
      behavior = "enum",
      event = function(self, v, t)
        if v == 2 then -- if sharing
          supercut.steal_voice_region(1, 2) -- set wrm 1 region points to wrm 2 region points
          wrms.update_control(wrms.page_from_label("v").k2, 0) -- set wrm 1 rec = 0
        elseif v == 1 then -- if normal
          supercut.steal_voice_home_region(1, 1) -- set wrm 1 region points to wrm1 default
          wrms.update_control(wrms.page_from_label("v").k2, 1) -- set wrm 1 rec = 1
        end
        
        wrms.update_control(wrms.page_from_label("s").e2) -- update loop point controls, just for kicks !
        wrms.update_control(wrms.page_from_label("s").e3)
      end
    }
  }
}
  

wrms.pages[2].k2 = wrms.pages[1].k2 -- copied controls for page "o"
wrms.pages[2].k3 = wrms.pages[1].k3


-- wgl lfo setup

wrms.lfo[1].freq = 0.5 
wrms.lfo[2].freq = 0.4
wrms.lfo.process = function() -- called on each lfo update
  local rate = supercut.rate(1) + wrms.lfo[1].delta -- set wrm 1 rate = change in lfo1 each time it updates
  supercut.rate(1, rate)
  
  local rate = supercut.rate(2) + wrms.lfo[2].delta -- set wrm 2 rate = change in lfo2 each time it updates
  supercut.rate(2, rate)
end

function wrms.sc_init() -- this gets called first within the larger wrms.init() function. redefine to customize initialization routine
  
  -- supercut (softcut) initial settings
  
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  
  supercut.init(1, "stereo")
  supercut.init(2, "stereo")
  
  supercut.play(1, 1)
  supercut.pre_level(1, 0.0)
  supercut.rate_slew_time(1, 0.2)
  supercut.home_region_length(1, 5)
  
  supercut.rec_level(2, 1.0)

  supercut.has_initial(1, true)
  
  for i = 1,2 do
    supercut.phase_quant(i, 0.05)
    supercut.level_input_cut(1, i, 1.0, 1)
    supercut.level_input_cut(2, i, 1.0, 2)
    supercut.level_slew_time(i, 0.1)
    supercut.recpre_slew_time(i, 0.01)
  end
end
-------------------------------------------- global callbacks - feel free to redefine when including wrms ! ------------------------------------------------------------

function init()
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

wrms.re = metro.init(function() redraw() end,  1/50)
wrms.re:start()

function cleanup()
  wrms.cleanup()
end

return wrms