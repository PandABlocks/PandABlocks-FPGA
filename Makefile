# Top level make file for building PandA FPGA images

TOP := $(CURDIR)

# Build defaults that can be overwritten by the CONFIG file if present

BUILD_DIR = $(TOP)/build
PYTHON = python2
SPHINX_BUILD = sphinx-build
PANDA_ROOTFS = $(error Define PANDA_ROOTFS in CONFIG file)
MAKE_ZPKG = $(PANDA_ROOTFS)/make-zpkg
APPS = $(patsubst apps/%.ini,%,$(wildcard apps/*.ini))

# The CONFIG file is required.  If not present, create by copying CONFIG.example
# and editing as appropriate.
include CONFIG

# For every APP in APPS, make build/APP
APP_BUILD_DIRS = $(patsubst %,$(BUILD_DIR)/%,$(APPS))

default: $(APP_BUILD_DIRS)
.PHONY: default

# Something like 0.1-1-g5539563-dirty
export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)
# Split and append .0 to get 0.1.0, then turn into hex to get 00000100
export VERSION := $(shell ./common/python/parse_git_version.py "$(GIT_VERSION)")
# 8 if dirty, 0 if clean
DIRTY_PRE = $(shell python -c "print 8 if '$(GIT_VERSION)'.endswith('dirty') else 0")
# Something like 85539563
export SHA := $(DIRTY_PRE)$(shell git rev-parse --short HEAD)


# Create the config_d directory from the app file
$(BUILD_DIR)/%_tmp/config_d: $(TOP)/apps/%.ini
	$(PYTHON) -m common.python.generate_config $< $@

# Make the actual build directory from the temporary one
$(BUILD_DIR)/%: $(BUILD_DIR)/%_tmp/config_d
	rm -rf $@_tmp $@
	mkdir -p $@_tmp
	mv $@_tmp $@

clean:
	rm -rf $(BUILD_DIR)
	find -name '*.pyc' -delete

.PHONY: clean

