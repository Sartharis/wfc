#
# Makefile for wfc driver
#

MAKEFLAGS += --warn-undefined-variables
SHELL := bash
	.SHELLFLAGS := -eu -o pipefail -c
	.DEFAULT_GOAL := all

# C++17 compiler
ENABLE="source /opt/rh/devtoolset-8/enable"
CXX=g++ -m64
CXXFLAGS=--std=c++17 -Wall -Wno-sign-compare -Wno-misleading-indentation -O3 -g -DNDEBUG
LDFLAGS=-lstdc++ -lpthread -ldl -lm
LDLIBS=-I libs -I libs/emilib -Ibuild/

################################################################################
# Extra stuff to support ISPC
ISPC=ispc
ISPCFLAGS=-O3 --target=avx1-i32x8 --arch=x86-64
TASKSYS_CXX=tasksys.cpp

################################################################################

OBJDIR=build
OBJS=$(OBJDIR)/main.o $(OBJDIR)/libs.o $(OBJDIR)/main_ispc.o $(OBJDIR)/tasksys.o 

# FILES:=$(shell echo *.cpp)
EXECUTABLE:=main

.PHONY: all dirs clean

# Only execute `all` rule if any file in $(FILES) have changed
all: $(EXECUTABLE)

dirs:
	@echo "Updating submodule..."
	@git submodule update --init --recursive
	@echo "Creating build and output directories..."
	@mkdir -p build
	@mkdir -p output

$(EXECUTABLE): dirs $(OBJS)
	@echo "Linking..."
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(LDFLAGS) $(LDLIBS)
	@echo "Done."

$(OBJDIR)/%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) $(LDLIBS) -c -o $@

$(OBJDIR)/main.o: $(OBJDIR)/main_ispc.h

$(OBJDIR)/main_ispc.h $(OBJDIR)/main_ispc.o: main_ispc.ispc
	$(ISPC) $(ISPCFLAGS) $< -h $(OBJDIR)/main_ispc.h -o $(OBJDIR)/main_ispc.o

# make clean will clear the build dir
clean:
	rm -rf build
	rm -rf output


