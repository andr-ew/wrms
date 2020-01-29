 softloop = {}
 
 -- temporary override
 softcut.defaults = function()
  zeros = {}
  for i = 1, softcut.VOICE_COUNT do zeros[i] = 0 end
   
   local state = {}
   for i=1, softcut.VOICE_COUNT do
     state[i] = {}
     
     state[i].enable = 0
     state[i].play = 0
     state[i].record = 0
     
     state[i].buffer = (i%2 + 1)
     state[i].level =0
     state[i].pan = 0
     
     state[i].level_input_cut = {0,0}
     state[i].level_cut_cut = zeros
     
     state[i].rate = 1
     state[i].loop_start = (i-1)*2
     state[i].loop_end = (i-1)*2+1
     state[i].loop = 1
     
     state[i].fade_time =  0.0005
     state[i].rec_level = 0
     state[i].pre_level = 0
     state[i].rec = 0
     state[i].rec_offset = -0.00015
     state[i].position = 0
     
     state[i].pre_filter_fc = 16000
     state[i].pre_filter_dry = 0
     state[i].pre_filter_lp = 1
     state[i].pre_filter_hp = 0
     state[i].pre_filter_bp = 0
     state[i].pre_filter_br = 0
     state[i].pre_filter_fc_mod = 1

     state[i].post_filter_fc = 12000
     state[i].post_filter_dry = 0
     state[i].post_filter_lp = 0
     state[i].post_filter_hp = 0
     state[i].post_filter_bp = 0
     state[i].post_filter_br = 0
     
     state[i].level_slew_time = 0.001
     state[i].rate_slew_time = 0.001
     state[i].phase_quant = 1
     state[i].phase_offset = 0
  end
  return state
end

local softloop_data = softcut.defaults()

for k,v in pairs(softloop_data[1]) do
  softloop[k] = function(voice, ...) end
end