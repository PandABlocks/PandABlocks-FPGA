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

default: apps docs
.PHONY: default

# ------------------------------------------------------------------------------
# App source autogeneration

# For every APP in APPS, make build/APP
APP_BUILD_DIRS = $(patsubst %,$(BUILD_DIR)/%,$(APPS))

# Make the built app from the ini file
$(BUILD_DIR)/%: $(TOP)/apps/%.ini
	rm -rf $@_tmp $@
	$(PYTHON) -m common.python.generate_app $< $@_tmp
	mv $@_tmp $@

apps: $(APP_BUILD_DIRS)

.PHONY: apps

# ------------------------------------------------------------------------------
# FPGA bitstream generation

# Something like 0.1-1-g5539563-dirty
export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)
# Split and append .0 to get 0.1.0, then turn into hex to get 00000100
export VERSION := $(shell ./common/python/parse_git_version.py "$(GIT_VERSION)")
# 8 if dirty, 0 if clean
DIRTY_PRE = $(shell python -c "print 8 if '$(GIT_VERSION)'.endswith('dirty') else 0")
# Something like 85539563
export SHA := $(DIRTY_PRE)$(shell git rev-parse --short HEAD)

# ------------------------------------------------------------------------------
# Documentation

# Generated rst sources from modules are put here, unfortunately it has to be in
# the docs dir otherwise matplotlib plot_directive screws up
DOCS_BUILD_DIR = $(TOP)/docs/build

# The html docs are built into this dir
DOCS_HTML_DIR = $(BUILD_DIR)/html
ALL_RST_FILES = $(shell find docs modules -name *.rst)
BUILD_RST_FILES = $(wildcard docs/build/*.rst)
SRC_RST_FILES = $(filter-out $(BUILD_RST_FILES),$(ALL_RST_FILES))

$(DOCS_HTML_DIR): docs/conf.py $(SRC_RST_FILES)
	echo $^
	$(SPHINX_BUILD) -b html docs $(DOCS_HTML_DIR)

docs: $(DOCS_HTML_DIR)

.PHONY: docs

# ------------------------------------------------------------------------------
# ZPKG generation

# ------------------------------------------------------------------------------
# Clean

clean:
	rm -rf $(BUILD_DIR) $(DOCS_BUILD_DIR)
	find -name '*.pyc' -delete

.PHONY: clean
