#
# Generate PS part of the firmware based as Zynq Block design
#

# Source directory
set TARGET_DIR [lindex $argv 0]
set_param board.repoPaths $TARGET_DIR/configs

# Build directory
set BUILD_DIR [lindex $argv 1]

# Output file
set OUTPUT_FILE [lindex $argv 2]

# Vivado run mode - gui or batch mode
set MODE [lindex $argv 3]

# Create project
create_project -force panda_ps $BUILD_DIR -part xc7z030sbg485-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_ps]
set_property "board_part" "em.avnet.com:picozed_7030:part0:1.0" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create block design
# (THIS is exported from Vivado design tool)
set scripts_vivado_version 2015.1
set scripts_vivado_version_2015_2_1 2015.2.1
set scripts_vivado_version_2018_3_1 2018.3.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 || [string first $scripts_vivado_version_2015_2_1 $current_vivado_version] == -1 } {
   if { [string first $scripts_vivado_version_2015_2_1 $current_vivado_version] == 0 } {
      puts ""
      puts "INFO : current vivado version is <$current_vivado_version> using Vivado <$scripts_vivado_version_2015_2_1> script"
      source $TARGET_DIR/bd/panda_ps.tcl
   } elseif { [string first $scripts_vivado_version $current_vivado_version] == 0 } {
      puts ""
      puts "INFO : current vivado version is <$current_vivado_version> using Vivado <$scripts_vivado_version> script"
      source $TARGET_DIR/bd/panda_ps.tcl
   } elseif { [string first $scripts_vivado_version_2018_3_1 $current_vivado_version] == 0 } {
      puts ""
      puts "INFO : current vivado version is <$current_vivado_version> using Vivado <$scripts_vivado_version_2018_3_1> script"
      source $TARGET_DIR/bd/panda_ps_vivado2018.3.tcl
   } else {
      puts ""
      puts "ERROR: This script was generated using Vivado <$scripts_vivado_version_2018_3_1>, <$scripts_vivado_version_2015_2_1> or <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."
      
      return 1
   }
}


# Exit script here if gui mode - i.e. if running 'make edit_ps_bd'
if {[string match "gui" [string tolower $MODE]]} { return }

# Generate the wrapper
set design_name [get_bd_designs]
make_wrapper -files [get_files $design_name.bd] -top -import

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "panda_ps_wrapper" $obj

# Generate Output Files
generate_target all [get_files $OUTPUT_FILE]
open_bd_design $OUTPUT_FILE

# Export to SDK
file mkdir $BUILD_DIR/panda_ps.sdk
write_hwdef -force -file $BUILD_DIR/panda_ps_wrapper.hdf

# Close block design and project
close_bd_design panda_ps
close_project
exit
