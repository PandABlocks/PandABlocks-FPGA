#
# Build PID IP from model composer
# IP sources and binaries can be found at git@github.com:valerixb/Panda-PID.git
#

create_ip -name pidmc -vendor MaxIV -library Panda_ModelComp -version 1.0 -module_name pidmc_0 -dir $BUILD_DIR/
