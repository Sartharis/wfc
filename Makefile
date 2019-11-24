#
# Makefile for wfc driver
#

MAKEFLAGS += --warn-undefined-variables
SHELL := bash
	.SHELLFLAGS := -eu -o pipefail -c
	.DEFAULT_GOAL := all

# C++17 compiler
ENABLE="source /opt/rh/devtoolset-8/enable"
CXX=g++
CPPFLAGS=--std=c++17 -Wall -Wno-sign-compare -O2 -g -DNDEBUG
LDLIBS=-lstdc++ -lpthread -ldl
OBJECTS=

FILES:=$(shell echo *.cpp)

# Only execute `all` rule if any file in $(FILES) have changed
all: $(FILES)
	@echo "Updating submodule..."
	@git submodule update --init --recursive
	@echo "Creating build and output directories..."
	@mkdir -p build
	@mkdir -p output
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
	$(CXX) $(CPPFLAGS) $(LDLIBS) -o main build/libs.o build/main.o
	@echo "Done."

# make clean will clear the build dir
clean:
	rm -rf build

.PHONY: all clean
