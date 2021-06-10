# ~ wrms ~~
dual stereo time-wigglers / echo loopers

two time-travel wrms for loops, delays, & everything in-between

![screen recording](lib/img/wrm.gif)

### requirements
- norns (update 210607 or later)
- audio input

### download
head to `norns.local` + click on the books, tab over to available, then scroll way down to wrms & click install 


# how 2 wrm

the first thing you should know is that E1 changes which page is displayed. pages contain different controls, mapped to the lower keys and encoders. the location of the control on-screen (left, right, center) shows which wrm will be affected by your control messing.

the first time you meet the wrms, wrm1 (on the left) will be set up as a delay & wrm 2 (on the right) will be configured as a looper pedal. feed the wrms some audio to begin exploring ! tap K3 once to begin recording a loop, then again to begin playback.

# controls

## main screen

![main screen](lib/img/main.png)

- **vol:** the easy one ! change the volume of each respective wrm
- **rec:** set the record state. 
    - if the wrm is asleep (flat line) toggling rec will punch in a new loop time. 
    - for an awake wrm (wiggling), rec sets whether the loop is overdubbing new material, or causes a stutter freeze in a delay. 
    - in an awake state, hold rec to clear the loop (or delay) and put the wrm to sleep. if wrm 1 is being a delay, you can use rec to turn it into a second looper (!!).
- **old:** set the overdub/delay feedback level - or the rate at which old material fades away. turn it up in a delay for long echo tails, or turn it down in a loop for tape decay memory loss.
- **bnd:** bnd is the simplest time warping control - K2 fine-tunes wrm1 between 1x & 2x pitch/speed for instant delay bendiness 
    - <Summmary> (when orbiting a black hole, the rate of time is inversely proportional to orbital altitude). </Summary>
- **wgl:** wgl is a slow LFO routed to the pitch of both wrms, causing various orbital instabilities. set it to around 0.08 for pleasant tape wow/flutter, or paitiently turn it up to 100 to pass through the singularity.
- **<< & >>:** octave transports double and halve the rate of time. hold & release a key for a playable tape glide effect. pressing or holding both keys at once will reverse time.
- **s & l:** the start & length of the playback window. 
    - in delay mode, "l" is the most useful as it sets the time between repeats - ranging from 4-second phrase repeats down to resonator-like phasing at 1 millisecond.
    - in loop scenarios (esp. with shared buffers) both controls can be used to modify the playback window or scan around buffer space for microlooping or pseudo-granular textures. 
    - (hint: if you cleared wrm1 to put it to sleep, "l" is how you wake it back up as a delay - just increase length from 0.)
- **> & <:** the feed controls set the routing between wrms. by default, the delaying wrm is feed into a looping one, but some may prefer loop into delay. you can also turn up both mix points for a chaotic feedback loop, or set up an infinitely rising pitch cascade when sharing buffers at different recording rates.
- **buf:** simple on the surface, but radical in application, buffer selection allows the wrms to share the same chunk of spacetime memory. 
    - assigning wrm 1 to buffer 2 yeilds a second asynchronous window into a loop, which you can fine-tune with s, l, and playback speeds.
    - assignign wrm 2 to buffer 1 yeilds a second delay tap which can re-pitch the audio recorded into wrm 1 (in the style of [alliterate](https://github.com/andr-ew/prosody#alliterate), stymon magneto, count to five).
    - (hint: sharing buffers will always result in clicks whenever the two playheads cross, but the filters help soften things & they kick in automatically when buf is changed)
- **f & q:** these set a wrm's filter cutoff & resonance. the K2&3 below set the filter responce (you'll need to take things off of dry befor you hear anything). by default, wrm1's delay will feed back through the filter each repeat which makes for a pleasant analog tone but can get screachy at higher resonances.

## params

- the **mix** section has a handful of useful level controls not available on the main screen. **input routing** will be important when using mono inputs.
    - "mono" sends both inputs to both wrms in mono
    - "2x mono" sends L in to wrm 1 only and R in to wrm 2 only
- in the **wrms** section all main & alt params are available for midi mapping (including for midi foot switches)
- the **crow** section allows you to map most controls to crow inputs (using @21echos' crowify). 

## alt

![alt screen](lib/img/alt.png)

holding K1 reveals a hidden batch of controls behind every page. these are meant to be complimentary to the main performance controls - extra tweaks & easter eggs that open up new sounds once some familiarity has been established. note that in the case of pages **s** and **f**, the alt page simply reveals the same controls mapped to wrm2.

- **sk:** skew the length of each loop channel in the stereo spectrum. great for stereofying mono sources.
- **res:** trigger playhead from 0. this is most useful as a mapping destination for crow triggers, which allows for synced delays in a modular context. 
- **ph:** set the phase separation of loop playback in the stereo spectrum.
- **tap:** a tap tempo control for delay or loop lengths
- **wgrt:** rate of the wgl LFO
- **tp**: semitone pitch transposition, also useful as a wide-range pitch bend
- **pan**: sets the _input_ pan for each wrm. K2 on this screen sets the overdub mode for wrm1 - in the default ping-pong mode, panning a mono source will bring in the the stereo ping-pong effect.
- **aliasing:** toggling on wil disable anti-aliasing for both record heads. the effect is most noticible when recording at non-1 rates, especially when bent & wiggled.

# templates

templates are variations of the main UI to fit a person's specific needs & preferences or even add new features. you could make a new template to remove an unused feature to declutter the UI, add an additonal page with some frequently used alt controls, or hack in new softcut features from another app. templates are just lua script that pulls in wrm's various libraries & hooks them all together with an on-screen user interface.

## wrms/lite

wrms ships with the "lite" template, which you can access from the main SELECT menu on norns. It's essentially a much simplified version of vanilla wrms that falls closer to a traditional dealy & looper pedal. this might be a good place to start if you're new to norns ! (the chosen controls & presets were based on those used on jade islan sayson's [paru paro](https://jadeislansayson.bandcamp.com/album/paru-paro))

(add docs of the various controls)

## custom

to create a new template in maiden, hit the "+" to make a new lua file in your top-level `code` folder & paste in the full code from `wrms.lua` (keeping your template out of the main wrms folder ensures that your tempate won't be overwritten on updates). at the top of the script you'll see various library scripts being pulled in & a bit further down there's a comment that says `default wrms template`. this is a [`nest_`](https://github.com/andr-ew/nest_) - essentially a fancy table that can draw controls (or `_affordances` in nest parlace) to the screen & sync data with the params system & more. you probably don't need to know much about it other than the fact that you can shuffle around the controls in the various tables within tables and it'll affect where they appear onscreen. 

essentially:
- theres a `pages` table within the main `wrms_` table and within pages there's a table for the letter of each page on screen. 
    - oh, and a little further up the `tab` table has an `options` table that lists out all of the page names in order, so new pages will need to update this bit as well. 
- in each page table (like `v`) theres a `main` table and an `alt` table and inside of _those_ tables there should be some tables named after the controls appearing onscreen. these are the aformentioned `_affordances`, and you may scoot them around, delete them, or stick them in new `nest_` tables as desired. 
    - note that most of these tables have various `:` function calls attatched to them (and even functions in those functions with affordances in the functions), and you'll want those to stick around as you scoot.
