# wrms
dual asyncronous time-benders / echo loopers
a remix of cranes for norns

### Requirements
norns

### Download
head to `norns.local` + click on the books
tab ovr to available & refresh community catalog


# Documentation

### basics

two wrms (stereo loops), similar in function but each with thier own quirks + abilities

`E1` up top changes which page is displayed. pages contain controls, mapped to norns' lower keys and encoders. the location of the control dictates which wrm will b affected.

### v o b s >

let's start with page `v`, ok ?

generally, `rec` decides whether new time is gobbled. notice at load, `wrm1` is echoing via continuously gobbling new time and fading old time. `wrm2` however, is dead asleep. wake her up by toggling record once, and then again. the length of her orbit is detirmined by the time between these initial toggles - after which gobble toggling returns to normal. to go back to sleep, hold `rec`, and begin again. `wrm2` mimics many of yr fav loop pedals. notice that `wrm1` feeds into `wrm2`. we'll get back to this later.

oh, and `vol` controls the volumes

page `o` is for the past.

`old` decides how loud the past is, && how long it resonates. use `old` to alter `wrm1`'s echo chain, or fade `wrm2`'s past to make room for the future. with a high `old`, `wrm1` can be used more like a looper. likewise, a low `old` on a short `wrm2` will sound an echo.

`b` bends time

`bnd` is the most tactile example. bend between single and double while the past follows along. `wrm2` has more flexibility here - `<<` and `>>` halve and double time's rate as wrms approach light speed, hapily gliding between while you hold and release.

(a technicality: the rate of time is inversely proportional to orbital altitude)

`wgl` scales time-varying orbits for both wrms - a low value makes a nice wobbly sound. a high wiggle will start pass through the singularity, but i'll let you decide whether that's an issue.

