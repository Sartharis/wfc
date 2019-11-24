#
# Makefile for wfc driver
#

MAKEFLAGS += --warn-undefined-variables
SHELL := bash
	.SHELLFLAGS := -eu -o pipefail -c
	.DEFAULT_GOAL := all

# C++14 compiler
ENABLE="source /opt/rh/devtoolset-8/enable"
CXX=g++
CPPFLAGS=--std=c++17 -Wall -Wno-sign-compare -O2 -g -DNDEBUG
LDLIBS=-lstdc++ -lpthread -ldl
OBJECTS=""

FILES:=$(shell echo *.cpp)

# Only execute `all` rule if any file in $(FILES) have changed
all: $(FILES)
	git submodule update --init --recursive
	mkdir -p build
	@for src_path in $(FILES); do \
		obj_path="build/$${src_path%.cpp}.o" ; \
		OBJECTS+=" $$obj_path" ; \
		if [ ! -f $$obj_path ] || [ $$obj_path -ot $$src_path ]; then \
			echo "Compiling $$src_path to $$obj_path..." ; \
			$(CXX) $(CPPFLAGS) \
				-I libs -I libs/emilib \
				-c $$src_path -o $$obj_path ; \
		fi \
	done
	@echo "Linking..."
	$(CXX) $(CPPFLAGS) $(OBJECTS) $(LDLIBS) -o wfc.bin
	@echo "Done."

# Run it:
# mkdir -p output
# ./wfc.bin $@
# exit

# make clean will clear the build dir
clean:
	rm -rf build

.PHONY: all clean
