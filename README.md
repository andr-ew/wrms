# ~ wrms ~~
dual asyncronous time-benders / echo loopers
a remix of cranes for norns

### requirements
a norns !

### download
head to `norns.local` + click on the books
tab ovr to available & refresh community catalog


# documentation

### basics

two wrms (stereo loops), similar in function but each with thier own quirks + abilities

`E1` up top changes which page is displayed. pages contain controls, mapped to norns' lower keys and encoders. the location of the control dictates which wrm will b affected.

### v o b s >

let's start with page `v`, ok ?

generally, `rec` decides whether new time is gobbled. notice at load, `wrm1` is echoing via continuously gobbling new time and fading old time. `wrm2` however, is dead asleep. wake her up by toggling record once, and then again. the length of her orbit is detirmined by the time between these initial toggles - after which gobble toggling returns to normal. to go back to sleep, hold `rec`, and begin again. (`wrm2` mimics many of yr fav loop pedals). notice that `wrm1` feeds into `wrm2`. we'll get back to this later.

oh, and `vol` controls the volumes

page `o` is for the past.

`old` decides how loud the past is, && how long it resonates. use `old` to alter `wrm1`'s echo chain, or fade `wrm2`'s past to make room for the future. with a high `old`, `wrm1` can be used more like a looper. likewise, a low `old` on a shorter `wrm2` will sound an echo.

`b` wiggles time

`bnd` is the most tactile example. bend `wrm1` between single and double time rate as she approaches light speed. `wrm2` has more flexibility - `<<` and `>>` halve and double time, hapily gliding between while you hold and release.

(a technicality: the rate of time is inversely proportional to orbital altitude)

`wgl` scales time-varying orbits for both wrms - a low value makes a nice wobbly sound. a high wiggle will start to pass through the singularity, but i'll let you decide whether that's an issue :~)

`s` affects `wrm1` alone

finally, here, we can make `wrm1` longer using `l` (which admittedly just looks like a vertical line, lol). with `s` we can scoot wrm for subtle delay fizzles or sub-loop glitchy stuff. `<<` and `>>` repeat actions from the previous page, useful for dual phase-orbiting looping configurations.

`>` communicates

remember how `wrm1` feeds into `wrm2` ? we can change that with `>` and `<`. feel free to place your delay after the loop for an alternate workflow, or feed both wrms to each other for more suprising results.

feed a stereo panned field to `wrm1` to hear the effect of `pp` - it reverses `old` on each pass for a ping-pong effect

lastly - `share` creates a new instrument. toggle a shared past and memory for both wrms + telepathic time loop conversations. obviously this unlocks new feaures underneath every other control, but i won't spoil them !


# roadmap

### 1.1 

- get some actual params in there
    - input mixer
    - param per control for midi mapping
- wrms mods (!!!)
- wrms mod synth engine combos

### 2.0 ?

- `K1`alt menu with pattern record + presets per page
