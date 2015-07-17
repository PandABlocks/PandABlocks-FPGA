VIVADO_VER = 2015.1
VIVADO = source /dls_sw/FPGA/Xilinx/Vivado/$(VIVADO_VER)/settings64.sh > /dev/null

DESIGN = panda_encin_tb
SIM_DIR = simulation
WAVE_FILE = wave.do
RUN_FILE = $(SIM_DIR)/run.tcl
TCL_FILE = open_sim.tcl

# Get source *.vhd filenames (ie: 'top_defines.vhd')
MODULE_PATHS = $(shell awk '{print $$1}' fileset.f)
MODULE_NAMES = $(notdir $(MODULE_PATHS))

# Get source directories (ie: '../../src/defines')
MODULE_DIRS = $(dir $(MODULE_PATHS))

VPATH = $(MODULE_DIRS)

WORK_DIR = $(SIM_DIR)/xsim.dir/work

SNAP_DIR = $(WORK_DIR).$(DESIGN)

LIB_DEPS = $(patsubst %.vhd,$(WORK_DIR)/%.vdb,$(MODULE_NAMES))

default: sim

clean:
	rm -rf $(SIM_DIR)
	rm $(TCL_FILE)

$(SIM_DIR):
	mkdir $(SIM_DIR)

$(WORK_DIR)/%.vdb: %.vhd
	cd $(SIM_DIR) && \
	    xvhdl -work work ../$<

$(SNAP_DIR) : $(SIM_DIR) $(LIB_DEPS)
	cd $(SIM_DIR) && \
	    xelab $(DESIGN) -debug typical

sim: clean_sim $(SNAP_DIR) $(RUN_FILE) $(TCL_FILE)
	cd $(SIM_DIR) && \
	    xsim $(DESIGN) -wdb $(DESIGN).wdb -t run.tcl

## If waveform file or snapshot directory modified,
## update run.tcl
$(RUN_FILE) :
	cat $(WAVE_FILE) > $(RUN_FILE)
	echo 'run all' >> $@
	echo 'save_wave_config $(DESIGN).wcfg' >> $@
	echo 'quit' >> $@

## If snapshot directory modified, there may be a new target design
## update open_wave.tcl
$(TCL_FILE) :
	echo 'close_sim -quiet' > $@
	echo 'current_fileset' >> $@
	echo 'open_wave_database $(SIM_DIR)/$(DESIGN).wdb' >> $@
	echo 'open_wave_config $(SIM_DIR)/$(DESIGN).wcfg' >> $@

clean_sim :
	rm -f $(SIM_DIR)/$(DESIGN).*
	rm -f $(RUN_FILE)
	rm -f $(TCL_FILE)

.PHONY: default clean clean_waveform sim
