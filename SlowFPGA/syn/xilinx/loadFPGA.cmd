setMode -bs
setCable -port auto
identify -inferir
identifyMPM
assignFile -p 2 -file "../run/zebra_top.bit"
setAttribute -position 2 -attr packageName -value ""
program -p 2 -defaultVersion 0
quit

