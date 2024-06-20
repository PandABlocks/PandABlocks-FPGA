#
# Build Sine Generator IP from model composer
# IP sources and binaries can be found at git@github.com:valerixb/Panda-singen.git
#

create_ip -name singenmc -vendor MaxIV -library Panda_ModelComp -version 1.0 -module_name singenmc_0 -dir $BUILD_DIR/
