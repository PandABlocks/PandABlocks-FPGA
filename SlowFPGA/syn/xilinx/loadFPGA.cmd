setMode -bs
setCable -port auto
identify -inferir
identifyMPM
assignFile -p 4 -file "../run/slow_top.bit"
setAttribute -position 4 -attr packageName -value ""
program -p 4 -defaultVersion 0
quit

