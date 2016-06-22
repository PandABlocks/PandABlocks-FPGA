setMode -pff
setSubmode -pffserial
addPromDevice -p 1 -name xcf04s
addDesign -version 0 -name 0
addDeviceChain -index 0
addDevice -p 1 -file zebra_top.bit
generate -format mcs -fillvalue FF -output zebra_top

setMode -bs
setCable -port auto
Identify -inferir
identifyMPM
assignFile -p 1 -file zebra_top.mcs
Program -p 1 -e -v

quit
