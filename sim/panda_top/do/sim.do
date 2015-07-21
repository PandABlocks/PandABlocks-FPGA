# Start with a clean work library
vlib work
vdel -all -lib work
vlib work
vmap work work

# Compile design sources
do fileset.f

vsim -t ps +notimingchecks -novopt -L unisims_ver work.panda_top_tb

do wave.do

run 1000 us

