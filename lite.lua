-- wrms/lite
--
-- simple stereo delay & looper
--
-- version 2.1.0 @andrew
-- https://norns.community/
--         authors/andrew/
--         wrms#wrmslite
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
-- wrm 1 (on the left) is a delay 
-- & wrm 2 (on the right) is a 
-- live looper. feed the wrms 
-- some audio to begin exploring! 
-- tap K3 once to begin 
-- recording a loop, then again 
-- to begin playback.
--
-- for documentation of each 
-- control, head to:
-- https://norns.community/
--         authors/andrew/
--         wrms#wrmslite

--external libs

cs = require 'controlspec'
pattern_time = require 'pattern_time'

--git submodule libs

nest = include 'lib/nest/core'
Key, Enc = include 'lib/nest/norns'
Text = include 'lib/nest/text'

multipattern = include 'lib/nest/util/pattern-tools/multipattern'
of = include 'lib/nest/util/of'
to = include 'lib/nest/util/to'
cartographer, Slice = include 'lib/cartographer/cartographer'
crowify = include 'lib/crowify/lib/crowify' .new(0.01)

--script lib files

wrms = include 'wrms/lib/globals'      --saving, loading, values, etc
sc, reg = include 'wrms/lib/softcut'   --softcut utilities
wrms_gfx = include 'wrms/lib/graphics' --graphics & animations
include 'wrms/lib/params'              --create params
Wrms = include 'wrms/lib/ui'           --nest v2 UI components

--pattern recorders are only created for use with orgnwrms

function pattern_time:resume()
    if self.count > 0 then
        self.prev_time = util.time()
        self.process(self.event[self.step])
        self.play = 1
        self.metro.time = self.time[self.step] * self.time_factor
        self.metro:start()
    end
end

pattern, mpat = {}, {}
for i = 1,5 do
    pattern[i] = pattern_time.new() 
    mpat[i] = multipattern.new(pattern[i])
end

--set up nest v2 UI

local _app = Wrms.lite()

nest.connect_enc(_app)
nest.connect_key(_app)
nest.connect_screen(_app, 60)

--init/cleanup

function init()
    params:set('>', 0)
    params:set('<', 1)
    params:set('input routing', 2)

    wrms.setup()
    params:read()
    wrms.load()

    params:bang()
end

function cleanup()
    --wrms.save()
    params:write()
end
